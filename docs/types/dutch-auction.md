# Dutch Auctions

## Overview

A simple _dutch auction_ may be thought of as a series of _limit orders_ where the limit price is monotonically decreasing over time. This contract implements a dutch auction by using a `ConditionalOrder` to place a series of limit orders, each with a lower limit price than the previous order.

This contract simplifies the _dutch auction_ by not selling on a continually decreasing price curve, but instead selling at a fixed price for a fixed period of time before discounting further. This approximation makes replay protection more intuitive / easier to reason, as well as eliminating the need for additional logic to be implemented within the watch-tower.

### Discount Formulae

This contract implements a linear "stair-step" discount formulae, where the price decreases by a fixed amount every `stepDuration` seconds. This discount formulae is as follows:

`minimumBuyAmount = startBuyAmount - (stepIndex * stepDiscount  * startBuyAmount / 10000)`

Where:
- `minimumBuyAmount` is the minimum amount of `buyToken` that must be paid to fill the order.
- `startBuyAmount` is the initial amount of `buyToken` at the start of the auction.
- `stepIndex` is the 0-index of the current step in the auction.
- `stepDiscount` is the amount of discount to apply to the `startBuyAmount` every `stepDuration` seconds. This is measured in BPS (1/10000).

## Data Structure

* **Uses Cabinet**: ✅
* **Value Factory**: `CurrentBlockTimestampFactory`

### Call Data

The `Data` struct is used to store the parameters of the dutch auction. The `Data` struct is ABI-encoded and used as the `staticInput` of the `ConditionalOrder` that is created. The `Data` struct is as follows:

```solidity=
struct Data {
    IERC20 sellToken;
    IERC20 buyToken;
    address receiver;
    uint256 sellAmount;
    bytes32 appData;
    // dutch auction specifics
    uint32 startTime; // 0 = mining time, > 0 = specific start time
    uint256 startBuyAmount;
    uint32 stepDuration; // measured in seconds
    uint256 stepDiscount; // measured in BPS (1/10000)
    uint256 numSteps;
    // nullifier
    uint256 buyTokenBalance; // monitor the current balance of `buyToken` to avoid replay attacks
}
```

### Storage

The `DutchAuction` contract _MAY_ make use of the cabinet (a single storage slot) to store the following:

1. The `block.timestamp` at the time the order was created (substitutes for `startTime` being 0)

**NOTE**: The general use case for storing `block.timestamp` at order creation time is to avoid bad UX when needing to wait for multiple signers on a multi-sig wallet.

### Calculated / auto-filled fields

The following `GPv2Order.Data` fields are calculated / auto-filled by the contract:

- `buyAmount`: Calculated by reference to time (current step) and discount formulae
- `kind`: Set to `GPv2Order.Kind.Sell`
- `sellTokenBalance` / `buyTokenBalance`: Set to `erc20`
- `feeAmount`: Set to `0`, ie. limit order
- `partiallyFillable`: Set to `false`, ie. Fill-or-Kill

## Limitations

* `sell` orders ONLY
* `sellToken` MUST NOT be the same as `buyToken`
* `sellAmount` MUST be greater than 0
* `numSteps` MUST be at least 2
* `stepDuration` MUST not be 0 seconds, and SHOULD be at least 3 mins (CoW Protocol API requires orders being placed to have a validity of at least 2 mins)
* `stepDiscount` MUST be at least 1 BPS (1/10000) and MUST be less than 10000 BPS (100%)
* `stepDiscount * numSteps` MUST be less than 10000 BPS (100%)
* Does NOT support partial fills

### Replay Mitigation

1. The primary method to mitigate replay attacks is for front-ends / users to ensure that the `GPv2VaultRelayer` only has spending allowance for `Data.sellAmount`. This is guaranteed to avoid settling subsequent orders in the series of limit orders.
2. If the `GPv2VaultRelayer` has an infinite allowance for `Data.sellToken`, then subsequent orders in the series of limit orders may be settled (violating the intent of the order type). Setting `Data.buyTokenBalance` to the user's  balance of `buyToken` (at time of **conditional order creation**) mitigates this attack vector.

**CAUTION**: If using (2) for replay mitigation, withdrawing / transferring `buyToken` from the receiver's address may invalidate the replay mitigation.

## Usage

Example: Alice wants to sell 10 WETH for DAI, starting at a price of 2000 DAI/ETH, decreasing by 100 DAI/WETH every 5 mins, for a total of 10 steps, starting at Sunday, October 1, 2023 6:11:37 GMT+00:00 (unix timestamp: 1696140697), with the price reducing by 5% every 5 mins. Alice presently has 50000 DAI in her wallet.

- `sellToken`: `WETH`
- `buyToken`: `DAI`
- `receiver`: `address(alice)`
- `sellAmount`: `10 * 10**18` // 10 WETH
- `appData`: `keccak256('dutch')`
- `startTime`: `1696140697` // Sunday, October 1, 2023 6:11:37 GMT+00:00
- `startBuyAmount`: `20000 * 10**18` // 20000 DAI for 10 WETH
- `stepDuration`: `300` // 5 mins
- `stepDiscount`: `500` // 5%
- `numSteps`: `10` // 10 steps
- `buyTokenBalance`: `50000 * 10**18` // 50000 DAI initially in Alice's wallet

To create the Dutch auction order:

1. ABI-Encode the `IConditionalOrder.ConditionalOrderParams` struct with:
    - `handler`: set the the `DutchAuction` smart contract deployment.
    - `salt`: set to a unique value (recommended: cryptographically random).
    - `staticInput`: set to the ABI-encoded `DutchAuction.Data` struct.
2. Use the `struct` from (1) as either a Merkle leaf, or with `ComposableCoW.create` to create a single conditional order.
3. Approve `GPv2VaultRelayer` to spend `sellAmount` of user's `sellToken` tokens (in the example above, `GPv2VaultRelayer` should be approved to spend 10 WETH).

**NOTE**: When calling `ComposableCoW.create`, setting `dispatch = true` will cause `ComposableCoW` to emit event logs that are indexed by the watch-tower automatically. If you wish to maintain a private order (and will submit to the CoW Protocol API  through your own infrastructure, you may set `dispatch` to `false`).

Fortunately, when using Safe, it is possible to batch together all the above calls to perform these steps atomically, and in doing so optimising on gas consumption and UX.