# Scripts

Some bash scripts for cleaning and validating project source files.

- `check-nettype.sh` - ensure verilog files are wrapped in `` `default_nettype none `` .. `` `default_nettype wire ``
- `clean-files.sh` - ensure there are only simple ASCII chars & using UTF-8 encoding
- `env_tiny_tapeout.sh` - set environment variables (e.g. `source ./env_tiny_tapeout.sh`)
- `verilator_lint.sh` - lint the Verilog project using Verilator.
