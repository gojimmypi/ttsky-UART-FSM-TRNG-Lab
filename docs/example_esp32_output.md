# Example ESP32 Output

<!--- # Do not move this file. Referenced by TT 4337 Documentation https://app.tinytapeout.com/projects/4337 --->


```text
gojimmypi:/mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ESP32
$ idf.py -p /dev/ttyS3 -b 115200 monitor
Executing action: monitor
Running idf_monitor in directory /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ESP32
Executing "/home/gojimmypi/.espressif/python_env/idf5.5_py3.10_env/bin/python /mnt/c/SysGCC/esp32-master/esp-idf/v5.5/tools/idf_monitor.py -p /dev/ttyS3 -b 115200 --toolchain-prefix xtensa-esp32-elf- --target esp32 --revision 0 /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ESP32/build/ulx3s_esp32.elf /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ESP32/build/bootloader/bootloader.elf -m '/home/gojimmypi/.espressif/python_env/idf5.5_py3.10_env/bin/python' '/mnt/c/SysGCC/esp32-master/esp-idf/v5.5/tools/idf.py' '-p' '/dev/ttyS3' '-b' '115200'"...
--- esp-idf-monitor 1.6.2 on /dev/ttyS3 115200
--- Quit: Ctrl+] | Menu: Ctrl+T | Help: Ctrl+T followed by Ctrl+H
I (13) boot: ESP-IDF v5.5 2nd stage bootloader
I (13) boot: compile time Jun  4 2026 08:25:56
I (13) boot: Multicore bootloader
I (13) boot: chip revision: v1.0
I (16) boot.esp32: SPI Speed      : 40MHz
I (20) boot.esp32: SPI Mode       : DIO
I (23) boot.esp32: SPI Flash Size : 2MB
I (27) boot: Enabling RNG early entropy source...
I (31) boot: Partition Table:
I (34) boot: ## Label            Usage          Type ST Offset   Length
I (40) boot:  0 nvs              WiFi data        01 02 00009000 00006000
I (47) boot:  1 phy_init         RF data          01 01 0000f000 00001000
I (53) boot:  2 factory          factory app      00 00 00010000 00100000
I (60) boot: End of partition table
I (63) esp_image: segment 0: paddr=00010020 vaddr=3f400020 size=0a3b0h ( 41904) map
I (85) esp_image: segment 1: paddr=0001a3d8 vaddr=3ff80000 size=00020h (    32) load
I (85) esp_image: segment 2: paddr=0001a400 vaddr=3ffb0000 size=023dch (  9180) load
I (92) esp_image: segment 3: paddr=0001c7e4 vaddr=40080000 size=03834h ( 14388) load
I (102) esp_image: segment 4: paddr=00020020 vaddr=400d0020 size=13374h ( 78708) map
I (131) esp_image: segment 5: paddr=0003339c vaddr=40083834 size=0b144h ( 45380) load
I (156) boot: Loaded app from partition at offset 0x10000
I (156) boot: Disabling RNG early entropy source...
I (166) cpu_start: Multicore app
I (174) cpu_start: Pro cpu start user code
I (175) cpu_start: cpu freq: 160000000 Hz
I (175) app_init: Application information:
I (177) app_init: Project name:     ulx3s_esp32
I (183) app_init: App version:      0.1.5-8-gfc18cf9-dirty
I (189) app_init: Compile time:     Jun  4 2026 08:25:35
I (195) app_init: ELF file SHA256:  ca2f9cedc...
I (200) app_init: ESP-IDF:          v5.5
I (205) efuse_init: Min chip rev:     v0.0
I (209) efuse_init: Max chip rev:     v3.99
I (214) efuse_init: Chip rev:         v1.0
I (220) heap_init: Initializing. RAM available for dynamic allocation:
I (227) heap_init: At 3FFAE6E0 len 00001920 (6 KiB): DRAM
I (233) heap_init: At 3FFB2C90 len 0002D370 (180 KiB): DRAM
I (239) heap_init: At 3FFE0440 len 00003AE0 (14 KiB): D/IRAM
I (245) heap_init: At 3FFE4350 len 0001BCB0 (111 KiB): D/IRAM
I (252) heap_init: At 4008E978 len 00011688 (69 KiB): IRAM
I (259) spi_flash: detected chip: generic
I (262) spi_flash: flash io: dio
W (266) spi_flash: Detected size(4096k) larger than the size in the binary image header(2048k). Using the size in the binary image header.
I (280) main_task: Started on CPU0
I (290) main_task: Calling app_main()
I (290) main: ------------------- ULX3S ESP32 Example ----------------
I (290) main: --------------------------------------------------------
I (300) main: --------------------------------------------------------
I (300) main: ---------------------- BEGIN MAIN ----------------------
I (310) main: --------------------------------------------------------
I (320) main: --------------------------------------------------------
I (330) main: Stack Start: 0x0
I (330) main: Stack HWM: 2400

Hello world 3!
This is esp32 chip with 2 CPU core(s), WiFi/BTBLE, silicon revision v1.0, 2MB external flash
Minimum free heap size: 305496 bytes
I (350) main: SPI write mode: boot config once
I (350) ulx3s_spi: SPI regs: R0=00 R1=00 R2=10 R3=00 R4=01 R5=04 R6=3E R7=84 raw=0x843E status=0x04 src=0 div=0x10 mode=0x00 oscen=0x01
I (460) main: TRNG deterministic LFSR test
I (460) main: lfsr test sample 00: raw=0x7F2E status=0x00
I (460) main: lfsr test sample 01: raw=0x9F33 status=0x00
I (460) main: lfsr test sample 02: raw=0xFC1C status=0x00
I (470) main: lfsr test sample 03: raw=0x6F03 status=0x00
I (480) main: lfsr test sample 04: raw=0x4B7D status=0x00
I (480) main: lfsr test sample 05: raw=0x52C8 status=0x00
I (490) main: lfsr test sample 06: raw=0xD6B7 status=0x00
I (490) main: lfsr test sample 07: raw=0xEF2A status=0x00
I (500) main: TRNG live source test: S1 RO0/fallback
I (510) main: S1 RO0/fallback sample 00: raw=0xAE11 status=0x0C
I (520) main: S1 RO0/fallback sample 01: raw=0x7826 status=0x0C
I (530) main: S1 RO0/fallback sample 02: raw=0x6F7D status=0x0C
I (540) main: S1 RO0/fallback sample 03: raw=0xDA87 status=0x0C
I (550) main: S1 RO0/fallback sample 04: raw=0x616F status=0x0C
I (560) main: S1 RO0/fallback sample 05: raw=0xD14E status=0x0C
I (570) main: S1 RO0/fallback sample 06: raw=0xE2E6 status=0x0C
I (580) main: S1 RO0/fallback sample 07: raw=0xB874 status=0x0C
I (580) main: TRNG live source test: S2 ROX/fallback
I (590) main: S2 ROX/fallback sample 00: raw=0xC060 status=0x14
I (600) main: S2 ROX/fallback sample 01: raw=0x64E4 status=0x14
I (610) main: S2 ROX/fallback sample 02: raw=0xA9DE status=0x14
I (620) main: S2 ROX/fallback sample 03: raw=0x6CB7 status=0x14
I (630) main: S2 ROX/fallback sample 04: raw=0xAF8F status=0x14
I (640) main: S2 ROX/fallback sample 05: raw=0x9E9C status=0x14
I (650) main: S2 ROX/fallback sample 06: raw=0x8E83 status=0x14
I (660) main: S2 ROX/fallback sample 07: raw=0xA7C1 status=0x14
I (660) main: TRNG live source test: S3 MIX/fallback
I (670) main: S3 MIX/fallback sample 00: raw=0x0D45 status=0x1C
I (680) main: S3 MIX/fallback sample 01: raw=0x55D6 status=0x1C
I (690) main: S3 MIX/fallback sample 02: raw=0x138C status=0x1C
I (700) main: S3 MIX/fallback sample 03: raw=0x1815 status=0x1C
I (710) main: S3 MIX/fallback sample 04: raw=0x7104 status=0x1C
I (720) main: S3 MIX/fallback sample 05: raw=0xFD98 status=0x1C
I (730) main: S3 MIX/fallback sample 06: raw=0x1BE8 status=0x1C
I (740) main: S3 MIX/fallback sample 07: raw=0x843E status=0x1C
I (740) ulx3s_spi: SPI regs: R0=00 R1=00 R2=10 R3=00 R4=01 R5=04 R6=3E R7=84 raw=0x843E status=0x04 src=0 div=0x10 mode=0x00 oscen=0x01
I (740) ulx3s_spi: SPI regs: R0=00 R1=00 R2=10 R3=00 R4=01 R5=04 R6=3E R7=84 raw=0x843E status=0x04 src=0 div=0x10 mode=0x00 oscen=0x01
```
