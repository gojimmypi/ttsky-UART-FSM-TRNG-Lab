# Tiny Tapeout Verilog Source Files

This is the main project source directory.

## Files

 - `src\config.json` - edit with caution.
 
 - `src\project_config.v` - project-wide parameter values and macros. Use by source in other directories requires `Makefile` edits (e.g. `tt/tt_tool.py`)
 
 - `src\project.v` - the main template shim. Keep it simple for portability.
 - `src\tt_um_main.v` - the main project file, which instantiates the JTAG, SPI, UART and TRNG cores.  

 - `src\UART\uart_rx_min.v` - a simple UART receiver core, which receives ASCII characters and outputs them as 8-bit values.
 - `src\UART\uart_tx_min.v` - a simple UART transmitter core, which sends 8-bit values as ASCII characters.
 - `src\UART\uart_trng_ascii_core.v` - a simple UART core that receives ASCII characters and outputs them as 8-bit values, and also includes a TRNG core that generates random numbers and sends them over UART when a specific command is received.

 - `src\TRNG\trng_cfg_ascii_core.v` - a simple TRNG core that can be configured via UART commands, and sends random numbers over UART when a specific command is received. This is a more complex version of the `uart_trng_ascii_core` that allows for configuration of the TRNG parameters.
 - `src\TRNG\trng_stub.v` - a stub TRNG core that can be used for testing the UART functionality without the complexity of a real TRNG. It generates pseudo-random numbers based on a simple counter and some bit manipulation, and sends them over UART when a specific command is received. This can be useful for testing the UART communication and command parsing without needing a real TRNG implementation.
 - `src\TRNG\trng_lab_core.v` - an optional TRNG lab core that provides an alternative to the `trng_stub` for experimentation and testing purposes.
 
## Config Edits

Although the GH Actions were all green, digging into the logs some concerns were observed. See [suggestion](https://discord.com/channels/1009193568256135208/1513299711975489566/1513680659447812276).

From [LibreLane Checking the reports](https://librelane.readthedocs.io/en/stable/additional_material/caravel/macro_first_hardening/index.html#checking-the-reports):

> Increase the slew/cap repair margins using DESIGN_REPAIR_MAX_SLEW_PCT and DESIGN_REPAIR_MAX_CAP_PCT. The default value is 20%. You may increase it as part of your implementation process:

`DESIGN_REPAIR_MAX_SLEW_PCT` - Tell the flow to apply N% slew margin when repairing slew. Instead of only trying to meet the real library max transition limit, it tries to make transitions faster than the limit by about N%.

`GRT_DESIGN_REPAIR_MAX_SLEW_PCT` - Applies the same idea to the post-global-route repair stage. That is important because after global routing, the tool has a better estimate of real wire parasitics.

> Enable post-global routing design optimizations using `RUN_POST_GRT_DESIGN_REPAIR`:

These changes have been applied / added to `src\config.json`:

```
  "RUN_POST_GRT_DESIGN_REPAIR": "true",
  "RUN_POST_GPL_DESIGN_REPAIR": "true",

  "DESIGN_REPAIR_MAX_SLEW_PCT": 30,
  "GRT_DESIGN_REPAIR_MAX_SLEW_PCT": 30,
```

First GDS Post Design Repair log in GF180: [GRT / GPL Design Repair Test #49](https://github.com/gojimmypi/ttgf-UART-FSM-TRNG-Lab/actions/runs/27211329394/job/80340895326) 
in [Commit d3155f9](https://github.com/gojimmypi/ttgf-UART-FSM-TRNG-Lab/commit/d3155f9d3418fc884a32badff31be2cce4a5a792).

Second Max Slew Rate 30% Percent log in GF190: [Add REPAIR_MAX_SLEW_PCT 30% #50](https://github.com/gojimmypi/ttgf-UART-FSM-TRNG-Lab/actions/runs/27216708803)
in [commit b7862a0](https://github.com/gojimmypi/ttgf-UART-FSM-TRNG-Lab/commit/b7862a07a85e2058a95b6d6190a75b42c49837e5).

References:

- [LibreLane Option 1 — Macro-First Hardening strategy](https://librelane.readthedocs.io/en/stable/additional_material/caravel/macro_first_hardening/index.html)
- [Module 3: Routing and Physical Optimization](https://silicon-sprint-auc.readthedocs.io/en/latest/MODULE3.html)
