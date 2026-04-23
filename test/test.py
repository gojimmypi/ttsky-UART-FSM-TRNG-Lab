# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

CLK_PERIOD_NS = 10
CLKS_PER_BIT = 217

UART_RX_BIT = 3
UART_TX_BIT = 4

EXPECTED_VERSION_PREFIX = b"Version "

def set_bit(value: int, bit_index: int, bit_value: int) -> int:
    mask = 1 << bit_index
    if bit_value:
        return value | mask
    return value & ~mask

async def uart_send_byte(dut, byte_value: int) -> None:
    bit_time_ns = CLK_PERIOD_NS * CLKS_PER_BIT

    current_ui = int(dut.ui_in.value)

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

async def uart_recv_byte(dut) -> int:
    bit_time_ns = CLK_PERIOD_NS * CLKS_PER_BIT
    half_bit_time_ns = bit_time_ns // 2

    prev_tx = (int(dut.uo_out.value) >> UART_TX_BIT) & 0x1

    # wait for falling edge (start bit)
    while True:
        await Timer(CLK_PERIOD_NS, unit="ns")
        tx_value = int(dut.uo_out.value)
        curr_tx = (tx_value >> UART_TX_BIT) & 0x1

        if prev_tx == 1 and curr_tx == 0:
            break

        prev_tx = curr_tx

    # move to middle of start bit
    await Timer(half_bit_time_ns, unit="ns")

    tx_value = int(dut.uo_out.value)
    start_bit = (tx_value >> UART_TX_BIT) & 0x1
    assert start_bit == 0, f"Expected UART start bit 0, got {start_bit}"

    # move to center of first data bit
    await Timer(bit_time_ns, unit="ns")

    result = 0
    for bit_index in range(8):
        tx_value = int(dut.uo_out.value)
        bit_value = (tx_value >> UART_TX_BIT) & 0x1
        result |= (bit_value << bit_index)

        await Timer(bit_time_ns, unit="ns")

    # sample stop bit in its center
    tx_value = int(dut.uo_out.value)
    stop_bit = (tx_value >> UART_TX_BIT) & 0x1
    assert stop_bit == 1, f"Expected UART stop bit 1, got {stop_bit}"

    return result

async def uart_recv_until_timeout(dut, max_bytes: int = 64, idle_timeout_bits: int = 20) -> bytes:
    bit_time_ns = CLK_PERIOD_NS * CLKS_PER_BIT
    idle_timeout_ns = bit_time_ns * idle_timeout_bits

    data = bytearray()

    for _ in range(max_bytes):
        waited_ns = 0
        while int(dut.uo_out.value) & (1 << UART_TX_BIT):
            await Timer(CLK_PERIOD_NS, unit="ns")
            waited_ns += CLK_PERIOD_NS
            if waited_ns >= idle_timeout_ns:
                return bytes(data)

        data.append(await uart_recv_byte(dut))

    return bytes(data)

@cocotb.test()
async def test_version_command(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await Timer(100, unit="ns")
    dut.rst_n.value = 1

    await Timer(1000, unit="ns")

    tx_idle = (int(dut.uo_out.value) >> UART_TX_BIT) & 0x1
    assert tx_idle == 1, f"UART TX should idle high after reset, got {tx_idle}"

    await uart_send_bytes(dut, b"V\r")
    response = await uart_recv_until_timeout(dut, max_bytes=64)

    assert response, "No UART response received for V command"
    assert EXPECTED_VERSION_PREFIX in response, (
        f"Expected prefix {EXPECTED_VERSION_PREFIX!r}, got {response!r}"
    )