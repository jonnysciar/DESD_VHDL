# README

## Intro

## Quick Start

- `source env.sh` sources Vivado and exports correct LC_NUMERIC (fix for synthesis error)
- `make all` generates the bitstream for the provided instructor's solution in the `/build/lab_solution` folder.

Check out the Makefile for the complete target list.

## Testing New Modules

To test a new VHDL module, one should delete any previous build of the project, substitute the desidered moduled into the `/hdl` folder, making sure to use the exact same name of the original module you are substituting. Then re-running `make project` to see the results in action.

> Should be working, but needs testing!

## Repository Structure

```
.
├── constraints     # constraints for the Basys3 board
│                   # note: the board_file is still required
│
├── hdl             # contains .vhd modules
│   └── tb          # testbenches
│
├── iprepo          # axi4 conversion IPs
├── scripts         # scripts for agile Vivado use
├── old             # lab0 stuff
└── build           # not present but generated at runtime

```

