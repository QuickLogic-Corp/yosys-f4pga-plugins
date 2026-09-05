# Yosys F4PGA Plugins

This repository contains plugins for [Yosys](https://github.com/YosysHQ/yosys.git) developed as [part of the F4PGA project](https://f4pga.org).

## Design introspection plugin

Adds several commands that allow for collecting information about cells, nets, pins and ports in the design or a
selection of objects.
Additionally provides functions to convert selection on TCL lists.

Following commands are added with the plugin:

* get_cells
* get_nets
* get_pins
* get_ports
* get_count
* selection_to_tcl_list

## FASM plugin

Writes out the design's [fasm features](https://fasm.readthedocs.io/en/latest/) based on the parameter annotations on a
design cell.

The plugin adds the following command:

* write_fasm

## Integrate inverters plugin

Implements a pass that integrates inverters into cells that have ports with the 'invertible_pin' attribute set.

The plugin adds the following command:

* integrateinv

## Parameters plugin

Reads the specified parameter on a selected object.

The plugin adds the following command:

* getparam

## QuickLogic IOB plugin

[QuickLogic IOB plugin](./ql-iob-plugin/) annotates IO buffer cells with information from IO placement constraints.
Used during synthesis for QuickLogic EOS-S3 architecture.

The plugin adds the following command:

* quicklogic_iob

## QuickLogic QLF FPGAs plugin

[QuickLogic QLF plugin](./ql-qlf-plugin) extends Yosys with synthesis support for `qlf_k4n8` and `qlf_k6n10` architectures.

The plugin adds the following command:

* synth_quicklogic
* ql_dsp

Detailed help on the supported command(s) can be obtained by running `help <command_name>` in Yosys.

## SDC plugin

Reads Standard Delay Format (SDC) constraints, propagates these constraints across the design and writes out the
complete SDC information.

The plugin adds the following commands:

* read_sdc
* write_sdc
* create_clock
* get_clocks
* propagate_clocks
* set_false_path
* set_max_delay
* set_clock_groups

## XDC plugin

Reads Xilinx Design Constraints (XDC) files and annotates the specified cells parameters with properties such as:

* INTERNAL_VREF
* IOSTANDARD
* SLEW
* DRIVE
* IN_TERM
* LOC
* PACKAGE_PIN

The plugin adds the following commands:

* read_xdc
* get_iobanks
* set_property
* get_bank_tiles

## SystemVerilog plugin

Reads SystemVerilog and UHDM files and processes them into yosys AST.

The plugin adds the following commands:

* read_systemverilog
* read_uhdm

Detailed help on the supported command(s) can be obtained by running `help <command_name>` in Yosys.


## Clock Gating plugin

Performs dynamic power optimization by automatically clock gating registers in design.

For Full documentation check [Lighter](https://github.com/Cloud-V/Lighter).

The plugin adds the following command:

* reg_clock_gating

Detailed help on the supported command(s) can be obtained by running `help <command_name>` in Yosys.

## Releasing to TabbyCAD / Aurora (QuickLogic)

Merging a change that touches plugin code into `main` automatically produces a new
TabbyCAD release and opens a version-bump PR in `aurora2`. No label is needed.

- **Docs/CI-only change** — `*.md`, `LICENSE`, `.github/**`, and the editor dotfiles
  `.editorconfig`, `.clang-format`, `.gitattributes`, `.gitignore`. No release is built.
- **Anything else counts as code**, including a path that does not exist today. A
  TabbyCAD release build (typically ~50 min, all three platforms, occasionally up to ~2 h)
  starts on merge, and when it finishes an automated PR is opened in
  `QL-Proprietary/aurora2` bumping both the TabbyCAD release tag and the `yosys-plugins`
  submodule pin. Review and merge it. The bias is deliberate: a spurious release costs a
  tag and a closeable PR, while a missed one leaves `aurora2` silently pinned to stale
  plugins.
- **Opting out:** add the label **`skip-tabbycad-release`** to a PR before merging to
  suppress the release even though it touches code.

A path-based skip runs the `trigger-tabbycad-release` job and records the reason in its
job summary. The `skip-tabbycad-release` label is checked at job level, so it skips the
whole job instead — the run shows a skipped job with no summary. Merged PRs from forks
also skip, because fork runs receive no secrets.

Full reference (manual trigger, versioning, prerequisites):
`tabbycad-quicklogic-build/docs/automated-release-pipeline.md`.
