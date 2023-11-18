## Clogs - Dutch Auctions on CoW Protocol

This repository aims to provide an opinionated best-practices reference implementation of a Conditional Order (concretely a Dutch Auction), on CoW Protocol, using the [ComposableCoW conditional order framework](https://github.com/cowprotocol/composable-cow).

## Getting Started

This repository uses [Foundry](https://getfoundry.sh) as the smart contract development environment. If you're using [Visual Studio Code](https://code.visualstudio.com), with [Development Containers](https://containers.dev/), then everything is ready to go out of the box!

If not, then you will need to install the following:

- [forge](https://getfoundry.sh)

## Designing / Reasoning of Order Types

When designing a new order type, it is important to consider the following:

1. What is the intended use case for the order type?
2. What are the limitations of the order type?
3. How can orders be made to be non-replayable?
4. What are the security considerations for the order type?
5. What data is required (if any) to be stored in the cabinet?

See the [Dutch Auction](./docs/types/dutch-auction.md) documentation for an example of how to address these questions.

## Repository Layout

- `src/`: Source code for the Dutch Auction contract
- `test/`: Tests for the Dutch Auction contract
- `script/`: Script for deploying the Dutch Auction contract
- `docs/`: Documentation for the Dutch Auction contract

### Tests

By extending `BaseComposableCoWTest`, we get a number of useful helper functions for testing the `DutchAuction`` contract. This includes complete fixtures (fully functional deployments) for:

1. Standalone CoW Protocol contracts
2. Safe contracts
3. Dogfooded ERC20 tokens (`token0`, `token1`, `token2`)
4. Test accounts (`alice`, `bob`, `safe1`)

Using the provided test harness, one may write complete E2E tests that will simulate the entire lifecycle of conditional orders, including:

1. Configuring a Safe for ComposableCoW
2. Creating a conditional order
3. Settling a conditional order via the CoW Protocol settlement contract (`GPv2Settlement`)

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Deploy

Before running the deployment script, you **MUST** set the following environment variables:

- `PRIVATE_KEY`: Private key of the deployer
- `COMPOSABLE_COW`: Address of the ComposableCoW contract

These can be set in a `.env` file in the root of the repository.

```shell
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url <your_rpc_url>
```

### Cast

```shell
cast <subcommand>
```

### Help

```shell
forge --help
anvil --help
cast --help
```

### Documentation

https://book.getfoundry.sh/
