# Tiny Tapeout Verilog Source Files


## Files

 - `src\config.json` - edit with caution
 
 - `src\project.v` - the main template shim. Keep it simple for portability.
 - `src\tt_um_uart_trng_ascii.v` - the main project file, which instantiates the UART and TRNG cores.  

 - `src\UART\uart_rx_min.v` - a simple UART receiver core, which receives ASCII characters and outputs them as 8-bit values.
 - `src\UART\uart_tx_min.v` - a simple UART transmitter core, which sends 8-bit values as ASCII characters.
 - `src\UART\uart_trng_ascii_core.v` - a simple UART core that receives ASCII characters and outputs them as 8-bit values, and also includes a TRNG core that generates random numbers and sends them over UART when a specific command is received.

 - `src\UART\TRNG\trng_cfg_ascii_core.v` - a simple TRNG core that can be configured via UART commands, and sends random numbers over UART when a specific command is received. This is a more complex version of the `uart_trng_ascii_core` that allows for configuration of the TRNG parameters.
 - `src\UART\TRNG\trng_stub.v` - a stub TRNG core that can be used for testing the UART functionality without the complexity of a real TRNG. It generates pseudo-random numbers based on a simple counter and some bit manipulation, and sends them over UART when a specific command is received. This can be useful for testing the UART communication and command parsing without needing a real TRNG implementation.
 