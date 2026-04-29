# ULX3S ESP32

Build with ESP-ISF v5.5

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
 
  To RESET the ESP32 and start the running program in flash:
  
 -    Hold btn[1]
 -    Tap btn[0]
 -    Release btn[1]
 
  To PROGRAM the ESP32 in flash:
  
  -   Hold btn[0]
  -     (begin flash upload)
  -   Release btn[0] when "Connecting..." is observed.
 
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