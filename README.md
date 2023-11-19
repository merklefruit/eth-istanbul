# replicow

> Copy the token composition of any Ethereum wallet with just a click.

## What is it?

Replicow uses [CoW Protocol](https://swap.cow.fi/) Programmatic Orders to automatically replicate
the portfolio of any Ethereum wallet. This is possible thanks to the [Safe](https://safe.global/)
ExtensibleFallbackHandler that allows to control user's funds only if the specified conditions
are met. In this case, the conditions are that the portfolio composition of the user's wallet
must match (or be close to) the portfolio composition of the replicated wallet.

Furthermore, when the portfolio composition changes over time, Replicow will automatically
perform rebalancing operations on existing tokens, and will also add/remove tokens from the
portfolio upon user's approval.

## Getting started

- Frontend: `cd frontend && yarn && yarn dev`
- Smart contracts: Deployed on Goerli testnet

## Limitations

Due to the short time available, the following limitations apply:

- Only a few ERC20 tokens are supported
- The Safe creation is not fully automated yet
- When new tokens are added to the tracked portfolio, the user must create a new order
  (and a new signature) to allow the auto rebalancing to occur for that token. This is
  a good use case for a notification system that would alert the user before committing
  to accumulating new tokens. This is not implemented yet.

## Authors

- [drun](https://github.com/fedemagnani)
- [merklefruit](https://github.com/merklefruit)
- [loocapro](https://github.com/loocapro)
- [melkor](https://github.com/0xmelkor)
