![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Tiny Tapeout Project: ttsky-UART-FSM-TRNG-Lab

<!-- breadcrumb for testing workflows 1.0 -->

Details of this project are located in [docs/info.md](./docs/info.md)

See companions projects:

- https://github.com/gojimmypi/ttgf-UART-FSM-TRNG-Lab (Global Foundry 180)
- This https://github.com/gojimmypi/ttsky-UART-FSM-TRNG-Lab (Sky130)

## Files and Directories

 - `.devcontainer` - TT VS Code devcontainer configuration for easy setup and development. Edit with caution.
 - `.github/workflows` - see the CI [workflows](.github/workflows)
 - `docs` - documentation for the project, which is used to generate the project page on the Tiny Tapeout website. 
 - `info.yaml` - metadata for the project, which is used to generate the project page on the Tiny Tapeout website.
 - `scripts` - scripts for building, testing, and flashing the project.
 - `src` - the main source files for the project, including the Verilog code for the design and any necessary configuration files.
 - `test` - testbenches and scripts for testing the project using simulation.  
 - `test-hw` - test scripts and files for testing the project on hardware. Only the ULX3S FPGA board at this time.
 - `ulx3s` - files for testing the project on the ULX3S FPGA board, including a wrapper module and scripts for building and flashing the board.

## Tiny Tapeout Verilog Project Template (manually reverted from Analog)

It was fairly difficult to do the conversion, not recommended. See [ttsky-analog-template/issues/2](https://github.com/TinyTapeout/ttsky-analog-template/issues/2). 
and local [7th commit da97ef8](https://github.com/gojimmypi/ttsky-UART-FSM-TRNG-Lab/commit/da97ef817f54f08ba1455db252e800bbea61c40a) .. [11th commit ab6b3ea](https://github.com/gojimmypi/ttsky-UART-FSM-TRNG-Lab/commit/ab6b3ea64d99a953928a76d761a291149c9cc03b).

- [Read the documentation for project](./docs/info.md)

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Analog projects

For specifications and instructions, see the [analog specs page](https://tinytapeout.com/specs/analog/).

## Enable GitHub actions to build the results page

- [Enabling GitHub Pages](https://tinytapeout.com/faq/#my-github-action-is-failing-on-the-pages-part)

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)

## What next?

- [Submit your design to the next shuttle](https://app.tinytapeout.com/).
- Edit [this README](README.md) and explain your design, how it works, and how to test it.
- Share your project on your social network of choice:
  - LinkedIn [#tinytapeout](https://www.linkedin.com/search/results/content/?keywords=%23tinytapeout) [@TinyTapeout](https://www.linkedin.com/company/100708654/)
  - Mastodon [#tinytapeout](https://chaos.social/tags/tinytapeout) [@matthewvenn](https://chaos.social/@matthewvenn)
  - X (formerly Twitter) [#tinytapeout](https://twitter.com/hashtag/tinytapeout) [@tinytapeout](https://twitter.com/tinytapeout)
  - Bluesky [@tinytapeout.com](https://bsky.app/profile/tinytapeout.com)
