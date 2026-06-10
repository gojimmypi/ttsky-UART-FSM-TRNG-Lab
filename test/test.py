# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
#
# See ATTRIBUTION.md for third-party sources and credits.
#
# file: test/test.py

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock

CLK_PERIOD_NS = 40
CLKS_PER_BIT = 217
SETTLE_TIME_NS = 2

UART_RX_BIT = 3
UART_TX_BIT = 4

UI_IDLE_VALUE = 0x18

EXPECTED_VERSION_PREFIX = b"Version "


def set_bit(value: int, bit_index: int, bit_value: int) -> int:
    mask = 1 << bit_index
    if bit_value:
        return value | mask
    return value & ~mask


async def uart_send_byte(dut, byte_value: int) -> None:
    bit_time_ns = CLK_PERIOD_NS * CLKS_PER_BIT

    current_ui = UI_IDLE_VALUE

    current_ui = set_bit(current_ui, UART_RX_BIT, 1)
    dut.ui_in.value = current_ui
    await Timer(bit_time_ns, unit="ns")

    current_ui = set_bit(current_ui, UART_RX_BIT, 0)
    dut.ui_in.value = current_ui
    await Timer(bit_time_ns, unit="ns")

    for bit_index in range(8):
        bit_value = (byte_value >> bit_index) & 0x1
        current_ui = set_bit(current_ui, UART_RX_BIT, bit_value)
        dut.ui_in.value = current_ui
        await Timer(bit_time_ns, unit="ns")

    current_ui = set_bit(current_ui, UART_RX_BIT, 1)
    dut.ui_in.value = current_ui
    await Timer(bit_time_ns, unit="ns")


async def uart_send_bytes(dut, data: bytes) -> None:
    for byte_value in data:
        await uart_send_byte(dut, byte_value)


def get_uart_tx_bit(dut) -> int:
    uo_value = dut.uo_out.value
    tx_value = uo_value[UART_TX_BIT]
    tx_text = str(tx_value)

    if tx_text not in ("0", "1"):
        raise ValueError(f"UART TX bit is not 0 or 1: {tx_text}")

    return int(tx_text)


async def uart_recv_byte(dut, idle_timeout_ns: int | None = None) -> int:
    bit_time_ns = CLK_PERIOD_NS * CLKS_PER_BIT
    half_bit_time_ns = bit_time_ns // 2

    waited_ns = 0

    while True:
        await Timer(CLK_PERIOD_NS, unit="ns")
        await Timer(SETTLE_TIME_NS, unit="ns")

        uo_value = dut.uo_out.value
        tx_value = uo_value[UART_TX_BIT]
        tx_text = str(tx_value)

        if tx_text == "0":
            break

        if tx_text == "1" or tx_text.upper() == "X":
            waited_ns += CLK_PERIOD_NS
            if idle_timeout_ns is not None and waited_ns >= idle_timeout_ns:
                raise TimeoutError("UART receive timeout waiting for start bit")
            continue

        raise ValueError(f"UART TX bit is not 0 or 1: {tx_text}")

    await Timer(half_bit_time_ns, unit="ns")
    await Timer(SETTLE_TIME_NS, unit="ns")

    start_bit = get_uart_tx_bit(dut)
    assert start_bit == 0, f"Expected UART start bit 0, got {start_bit}"

    await Timer(bit_time_ns, unit="ns")
    await Timer(SETTLE_TIME_NS, unit="ns")

    result = 0
    for bit_index in range(8):
        bit_value = get_uart_tx_bit(dut)
        result |= (bit_value << bit_index)
        await Timer(bit_time_ns, unit="ns")
        await Timer(SETTLE_TIME_NS, unit="ns")

    stop_bit = get_uart_tx_bit(dut)
    assert stop_bit == 1, f"Expected UART stop bit 1, got {stop_bit}"

    return result

async def uart_recv_until_timeout(dut, max_bytes: int = 64, idle_timeout_bits: int = 20) -> bytes:
    bit_time_ns = CLK_PERIOD_NS * CLKS_PER_BIT
    idle_timeout_ns = bit_time_ns * idle_timeout_bits

    data = bytearray()

    for _ in range(max_bytes):
        try:
            data.append(await uart_recv_byte(dut, idle_timeout_ns=idle_timeout_ns))
        except TimeoutError:
            return bytes(data)

    return bytes(data)


@cocotb.test()
async def test_version_command_or_absent(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    dut.ena.value = 1
    dut.ui_in.value = UI_IDLE_VALUE
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await Timer(100, unit="ns")
    dut.rst_n.value = 1

    # Gate-level simulation can leave outputs as X until reset has settled
    # through the synthesized netlist and a few clocks have completed.
    await Timer(100_000, unit="ns")
    await Timer(SETTLE_TIME_NS, unit="ns")

    tx_idle = get_uart_tx_bit(dut)
    assert tx_idle == 1, f"UART TX should idle high after reset, got {tx_idle}"

    await Timer(CLK_PERIOD_NS // 2, unit="ns")
    await uart_send_bytes(dut, b"V\r")

    response = await uart_recv_until_timeout(
        dut, max_bytes=64, idle_timeout_bits=200
    )

    assert response, "No UART response received for V command"

    if response == b"?\r":
        dut._log.info("Version command not present in this bitstream")
        return

    assert EXPECTED_VERSION_PREFIX in response, (
        f"Expected version prefix or absent-version response, got {response!r}"
    )