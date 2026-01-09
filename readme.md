# Ethernaut Solutions with Foundry

This repository contains some possible solutions to [Ethernaut](https://github.com/OpenZeppelin/ethernaut), a series of smart contract security puzzles by [OpenZeppelin](https://ethernaut.openzeppelin.com).
I approached the challenges by writing [Foundry](https://getfoundry.sh/) tests that demonstrate solutions for each level.

In addition, this repo provides bash scripts and a Dockerfile to spin up a **local Ethernaut instance** - both the contracts (on a local Anvil test RPC on port 8545) and the web UI (on port 3000) - so you can practice and test solutions in a self-contained local environment.

Once that Ethernaut instance is spun up, there is a further Dockerfile which is a Foundry test and build image which forks the chain from that local RPC and runs the test solutions in this repository.

The only dependencies are docker, git, and bash. There is no need to install foundry.

The purpose of this repo is primarily educational, but you might find the container version of Ethernaut useful.

Solutions are given for each level. However, some of the levels have many possible solutions beyond those shown here.

## Repository Structure

- **`test/`** Foundry tests, one per Ethernaut level.
- **`test/Ethernaut.t.sol`** Provides the base test for creating foundry test solutions for Ethernaut.
- **`docker/`** Contains the Dockerfiles used in the repository.
- **`level{n}`** Contains additional code used to solve a level.
- **`./ethernaut`** Is a bash dispatcher for launching Ethernaut, tests, and other repository functions.

## Getting Started

### Prerequisites

- Docker
- Git
- Bash

### Clone this repository

```bash
git clone https://github.com/mireynolds/ethernaut-solutions && cd ethernaut-solutions
```

### Grant permissions to run the ethernaut dispatcher and set a local path for the dispatcher

```bash
chmod +x ethernaut
```

### Launch Local Ethernaut (Web UI + RPC)

```bash
./ethernaut launch
```

- RPC at http://localhost:8545 with Ethernaut deployed.

- Web UI at http://localhost:3000 to interact with the challenges in your browser.

These are both contained within one docker container.

Logs can be viewed with `./ethernaut logs`.

The app and RPC are not persistent. They can be stopped with `./ethernaut stop`.

### Run Foundry Tests

```bash
./ethernaut test
```

Runs all the foundry tests in `test/` using a Foundry build and test docker image.

## Other Scripts

### Foundry Debugger

It was useful to use the Foundry debugger to solve level 13 and 36.

The corresponding script enters the Foundry debugger using a docker image for that test.

```bash
./ethernaut forge_debug_level 13
```

### Level 35 and 37

For level 35, it was necessary to construct a hash and signature pairing for this level.

The following command uses docker build to calculate such a pairing. The associated code is in `./ecdsa/`.

There is also a corresponding test for level 37.

```bash
./ethernaut ecdsa
```

### Forge formatting

The Solidity files in this repository have been formatted with the Foundry formatting tool.

The corresponding script formats all the solidity files tracked by git in this repository inside a foundry docker image.

```bash
./ethernaut forge_fmt
```

## Licensing

- **This repository’s code** (tests, scripts, Dockerfiles) is licensed under **MIT**. See [LICENSE](LICENSE).
- **Ethernaut** is used only at runtime inside the Docker environment and is licensed under **AGPL-3.0** by its authors. Source: https://github.com/OpenZeppelin/ethernaut
- **Foundry** is used as a development tool (MIT and Apache-2.0). Source: https://github.com/foundry-rs/foundry
