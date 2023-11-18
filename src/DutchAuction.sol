// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {GPv2Order} from "cowprotocol/libraries/GPv2Order.sol";

import {ComposableCoW} from "composable/ComposableCoW.sol";
import "composable/BaseConditionalOrder.sol";
import "composable/interfaces/IAggregatorV3Interface.sol";

// --- error strings
/// @dev auction hasn't started
string constant AUCTION_NOT_STARTED = "auction not started";
/// @dev auction has already ended
string constant AUCTION_ENDED = "auction ended";
/// @dev auction has already been filled
string constant AUCTION_FILLED = "auction filled";
/// @dev can't buy and sell the same token
string constant ERR_SAME_TOKENS = "same tokens";
/// @dev sell amount must be greater than zero
string constant ERR_MIN_SELL_AMOUNT = "sellAmount must be gt 0";
/// @dev auction duration must be greater than zero
string constant ERR_MIN_AUCTION_DURATION = "auction duration is zero";
/// @dev step discount is zero
string constant ERR_MIN_STEP_DISCOUNT = "stepDiscount is zero";
/// @dev step discount is greater than or equal to 10000
string constant ERR_MAX_STEP_DISCOUNT = "stepDiscount is gte 10000";
/// @dev number of steps is less than or equal to 1
string constant ERR_MIN_NUM_STEPS = "numSteps is lte 1";
/// @dev total discount is greater than 10000
string constant ERR_MAX_TOTAL_DISCOUNT = "total discount is gte 10000";

/**
 * @title Simple Dutch Auction order type for CoW Protocol.
 * @author CoW Protocol Developers
 * @author kayibal (original code)
 */
contract DutchAuction is BaseConditionalOrder {
    /// @dev `staticInput` data struct for dutch auctions
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

    /// @dev need to know where to find ComposableCoW as this has the cabinet!
    ComposableCoW public immutable composableCow;

    constructor(ComposableCoW _composableCow) {
        composableCow = _composableCow;
    }

    /**
     * If the conditions are satisfied, return the order that can be filled.
     * @param owner The owner of the conditional order.
     * @param ctx The ctx key used for the cabinet in `ComposableCoW`.
     * @param staticInput The ABI encoded `Data` struct.
     * @return order The GPv2Order.Data struct that can be filled.
     */
    function getTradeableOrder(address owner, address, bytes32 ctx, bytes calldata staticInput, bytes calldata)
        public
        view
        override
        returns (GPv2Order.Data memory order)
    {
        Data memory data = abi.decode(staticInput, (Data));
        _validateData(data);

        // `startTime` for the auction is either when the was mined or a specific start time
        if (data.startTime == 0) {
            data.startTime = uint32(uint256(composableCow.cabinet(owner, ctx)));
        }

        // woah there! you're too early and the auction hasn't started. Come back later.
        if (data.startTime > uint32(block.timestamp)) {
            revert PollTryAtEpoch(data.startTime, AUCTION_NOT_STARTED);
        }

        /**
         * @dev We bucket out the time from the auction's start to determine the step we are in.
         *      Unchecked:
         *      * Underflow: `block.timestamp - data.startTime` is always positive due to the above check.
         *      * Divison by zero: `data.stepDuration` is asserted to be non-zero in `validateData`.
         *      If `data.stepDuration` is consistently very large, resulting in the bucket always being zero,
         *      then the auction is effectively a fixed price sale with no discount.
         */
        uint32 bucket;
        unchecked {
            bucket = uint32(block.timestamp - data.startTime) / data.stepDuration;
        }

        // if too late, not valid, revert
        if (bucket >= data.numSteps) {
            revert PollNever(AUCTION_ENDED);
        }

        // calculate the current buy amount
        // Note: due to integer rounding, the current buy amount might be slightly lower than expected (off-by-one)
        uint256 bucketBuyAmount = data.startBuyAmount - (bucket * data.stepDiscount * data.startBuyAmount) / 10000;

        order = GPv2Order.Data(
            data.sellToken,
            data.buyToken,
            data.receiver,
            data.sellAmount,
            bucketBuyAmount,
            data.startTime + (bucket + 1) * data.stepDuration, // valid until the end of the current bucket
            data.appData,
            0, // use zero fee for limit orders
            GPv2Order.KIND_SELL, // only sell order support for now
            false, // partially fillable orders are not supported
            GPv2Order.BALANCE_ERC20,
            GPv2Order.BALANCE_ERC20
        );

        /**
         * @dev We use the `buyTokenBalance`, ie. B(buyToken) to avoid replay attacks. Generally, this value will
         *      represent the user's balance of `buyToken` at the time of the order creation. We assert that if
         *      B(buyToken) + `bucketBuyAmount` >= B'(buyToken), then the order has already been filled.
         *      Considerations:
         *      1. A 'malicious' user gives `bucketBuyAmount` to the user after the order has been created.
         *         This is not a problem as the user has more effective `buyToken` than expected. This may be a
         *         problem if it results in a hook not being called that had a critical side effect.
         *      2. A user excitedly transfers `buyToken` to themselves after the order has been settled,
         *         and subsequently creates a new order in the next bucket. This presents UX issues that the
         *         SDK / front-end should handle - explicitly by ensuring that the `GPv2VaultRelayer` only has
         *         allowance to spend the exact `sellAmount` of `sellToken` for the order. This ensures
         *         that the user does not inadvertently trade again.
         */
        if (data.buyToken.balanceOf(GPv2Order.actualReceiver(order, owner)) >= data.buyTokenBalance + bucketBuyAmount) {
            revert PollNever(AUCTION_FILLED);
        }
    }

    /**
     * @dev External function for validating the ABI encoded data struct. Help debuggers!
     * @param data `Data` struct containing the order parameters
     * @dev Throws if the order provided is not valid.
     */
    function validateData(bytes memory data) external pure override {
        _validateData(abi.decode(data, (Data)));
    }

    /**
     * Internal method for validating the ABI encoded data struct.
     * @dev This is a gas optimisation method as it allows us to avoid ABI decoding the data struct twice.
     * @param data `Data` struct containing the order parameters
     * @dev Throws if the order provided is not valid.
     */
    function _validateData(Data memory data) internal pure {
        if (data.sellToken == data.buyToken) revert OrderNotValid(ERR_SAME_TOKENS);
        if (data.sellAmount == 0) revert OrderNotValid(ERR_MIN_SELL_AMOUNT);
        if (data.stepDuration == 0) revert OrderNotValid(ERR_MIN_AUCTION_DURATION);
        if (data.stepDiscount == 0) revert OrderNotValid(ERR_MIN_STEP_DISCOUNT);
        if (data.stepDiscount >= 10000) revert OrderNotValid(ERR_MAX_STEP_DISCOUNT);
        if (data.numSteps <= 1) revert OrderNotValid(ERR_MIN_NUM_STEPS);
        if (data.numSteps * data.stepDiscount >= 10000) revert OrderNotValid(ERR_MAX_TOTAL_DISCOUNT);
    }
}
