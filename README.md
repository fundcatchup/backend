# FundCatchup
> Catch up to your funds and what friends owe you

## What is FundCatchup?
"FundCatchup" is a dynamic and user-friendly app designed to simplify the often complex process of splitting expenses among friends, family, or colleagues. With its intuitive interface, this app takes the hassle out of tracking shared costs for various activities like group trips, meals, or joint gifts.

## Setting Up for Development
This repository holds all of FundCatchup's application level codebase. We use [NixOS](https://nixos.org) for the best developer experience. 
There are many applications that need running together managed via [Tilt](https://tilt.dev) and [Buck2](https://buck2.build).
We only support working on Linux/MacOS (`x86-64` or `aarch64`) at the moment, other platforms are unsupported.

### Dependencies

- [Nix with Flakes](https://github.com/DeterminateSystems/nix-installer)
- [Direnv](https://direnv.net)

When you clone this repository and open a terminal in the root directory of the repository, the remaining dependencies will be automatically installed. 
To complete the setup, you'll need to execute the command `direnv allow` in the terminal.

Nix will automatically fetch and install all the necessary dependencies, as specified in the [nix flake file](./flake.nix).

### Running

This would bring up Tilt and you can see all logs from all applications (after being built via buck2):

```sh
buck2 run //dev:up
```
