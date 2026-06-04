# ULX3S ESP32

Build with ESP-ISF v5.5

## Program with US1

Shown here in WSL using ULX3S FTDI `US1` (net the external UART) to pogram the ESP32 on `/dev/ttyS3`:

```
cd /mnt/c/SysGCC/esp32-master/esp-idf/v5.5

. ./export.sh

cd "$PROJECT_ROOT/ulx3s/ESP32
idf.py build

# For hands-off programming, be sure to define ESP32_BOOT_RTS_DTR_ENABLED in the ULX3S Makefile
idf.py -p /dev/ttyS3 -b 115200 flash

# Optional monitor from commandline:
idf.py -p /dev/ttyS3 -b 115200 monitor
```

- The C compiler identification is GNU 14.2.0
- The CXX compiler identification is GNU 14.2.0

 NOTICE - IMPORTANT

 The ESP32 on the ULX3S sits behind the FPGA! When using the serial port for programming, the
 FPGA ** MUST ** be configured in passthru mode. See top_ulx3s.v file. Something like:
  

```verilog
    assign wifi_en    = btn[0];
    assign wifi_gpio0 = btn[1];
```

  If ESP32_BOOT_CONTROL_ENABLED is defined, BTN0 controls wifi_en and BTN1 controls wifi_gpio0

## Reset and Programming

### Reset and Boot Mode Selection 

  To RESET the ESP32 and start the running program in flash:
  
 -    Hold btn[1]     ('PWR/RESET')
 -    Tap btn[0]      ('BOOT/FLASH')
 -    Release btn[1]

### Programming

  To PROGRAM the ESP32 in flash:
  
  -   Hold btn[0]
  -     (begin flash upload)
  -   Release btn[0] when "Connecting..." is observed.
 
 If the above does not work, hold down the Pwr/Reset button and try again.

  Should then see something like:

```text
    Chip is ESP32-D0WDQ6 (revision v1.0)
    Features: WiFi, BT, Dual Core, 240MHz, VRef calibration in efuse, Coding Scheme None
    Crystal is 40MHz
    Uploading stub...
    Running stub...
    Stub running...
    Changing baud rate to 460800
    Changed.
      ... etc ...
```

ftdi_ndtr    | ftdi_nrts | dtr | rts | wifi_gpio0 | wifi_en     | ESP32 state
-------------| --------- | --- | --- | --------- | ------------ | ---
   0         |   0       |  1  | 1   |     1     |      1       | normal run
   0         |   1       |  1  | 0   |     0     |      1       | boot select low
   1         |   0       |  0  | 1   |     1     |      0       | reset
   1         |   1       |  0  | 0   |     1     |      1       | normal run
