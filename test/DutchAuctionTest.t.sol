// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "composable-test/ComposableCoW.base.t.sol";
import "../src/DutchAuction.sol";

contract DutchAuctionTest is BaseComposableCoWTest {
    IERC20 constant SELL_TOKEN = IERC20(address(0x1));
    IERC20 constant BUY_TOKEN = IERC20(address(0x2));
    address constant SELL_ORACLE = address(0x3);
    address constant BUY_ORACLE = address(0x4);
    address constant COMPOSABLE_COW = address(0x5);
    bytes32 constant APP_DATA = bytes32(0x0);

    DutchAuction dutchAuction;
    address safe;

    function setUp() public virtual override(BaseComposableCoWTest) {
        super.setUp();

        dutchAuction = new DutchAuction(ComposableCoW(COMPOSABLE_COW));
    }

    function mockCowCabinet(address mock, address owner, bytes32 ctx, bytes32 retVal)
        internal
        returns (ComposableCoW iface)
    {
        iface = ComposableCoW(mock);
        vm.mockCall(mock, abi.encodeWithSelector(iface.cabinet.selector, owner, ctx), abi.encode(retVal));
    }

    function test_pricing_LimitPriceAtStart_concrete() public {
        DutchAuction.Data memory data = helper_testData();
        vm.warp(data.startTime);

        GPv2Order.Data memory res =
            dutchAuction.getTradeableOrder(safe, address(0), bytes32(0), abi.encode(data), bytes(""));

        assertEq(res.buyAmount, 10 ether);
    }

    function test_pricing_LimitPriceAtEnd_concrete() public {
        DutchAuction.Data memory data = helper_testData();
        vm.warp(data.startTime - 1 + data.stepDuration * data.numSteps);

        GPv2Order.Data memory res =
            dutchAuction.getTradeableOrder(safe, address(0), bytes32(0), abi.encode(data), bytes(""));

        assertEq(res.buyAmount, 9 ether);
    }

    function test_pricing_LimitPriceAtMiddle_concrete() public {
        DutchAuction.Data memory data = helper_testData();
        vm.warp(data.startTime - 1 + data.stepDuration * (data.numSteps / 2));

        GPv2Order.Data memory res =
            dutchAuction.getTradeableOrder(safe, address(0), bytes32(0), abi.encode(data), bytes(""));

        assertEq(res.buyAmount, 9.6 ether);
    }

    function test_verifyOrder() public {
        bytes32 domainSeparator = 0x8f05589c4b810bc2f706854508d66d447cd971f8354a4bb0b3471ceb0a466bc7;

        DutchAuction.Data memory data = helper_testData();
        vm.warp(1_000_000);
        GPv2Order.Data memory empty;
        GPv2Order.Data memory order =
            dutchAuction.getTradeableOrder(safe, address(0), bytes32(0), abi.encode(data), bytes(""));
        bytes32 hash_ = GPv2Order.hash(order, domainSeparator);
        vm.warp(1_000_000 + 79);

        dutchAuction.verify(safe, address(0), hash_, domainSeparator, bytes32(0), abi.encode(data), bytes(""), empty);
    }

    function test_startMiningTime() public {
        (DutchAuction.Data memory data, bytes32 id, DutchAuction auction, uint256 startTime) = helper_miningTime();

        // advance to the start of the dutch auction
        vm.warp(startTime);
        // the following should no longer revert as the conditions are met
        auction.getTradeableOrder(safe, address(0), id, abi.encode(data), bytes(""));
    }

    function test_timing_RevertBeforeAuctionStarted() public {
        DutchAuction.Data memory data = helper_testData();

        // if before start time, should revert
        vm.warp(data.startTime - 1);
        vm.expectRevert(
            abi.encodeWithSelector(IConditionalOrder.PollTryAtEpoch.selector, data.startTime, AUCTION_NOT_STARTED)
        );
        dutchAuction.getTradeableOrder(safe, address(0), bytes32(0), abi.encode(data), bytes(""));
    }

    function test_timing_RevertBeforeAuctionStartedMiningTime() public {
        (DutchAuction.Data memory data, bytes32 id, DutchAuction auction, uint256 startTime) = helper_miningTime();

        // if before start time, should revert
        vm.warp(startTime - 1);
        vm.expectRevert(
            abi.encodeWithSelector(IConditionalOrder.PollTryAtEpoch.selector, startTime, AUCTION_NOT_STARTED)
        );
        auction.getTradeableOrder(safe, address(0), id, abi.encode(data), bytes(""));
    }

    function test_timing_RevertAfterAuctionFinished() public {
        DutchAuction.Data memory data = helper_testData();
        vm.warp(data.startTime + (data.numSteps * data.stepDuration));

        vm.expectRevert(abi.encodeWithSelector(IConditionalOrder.PollNever.selector, AUCTION_ENDED));
        dutchAuction.getTradeableOrder(safe, address(0), bytes32(0), abi.encode(data), bytes(""));
    }

    function test_timing_RevertAfterAuctionFinishedMiningTime() public {
        (DutchAuction.Data memory data, bytes32 id, DutchAuction auction, uint256 startTime) = helper_miningTime();
        vm.warp(startTime + (data.numSteps * data.stepDuration));

        vm.expectRevert(abi.encodeWithSelector(IConditionalOrder.PollNever.selector, AUCTION_ENDED));
        auction.getTradeableOrder(safe, address(0), id, abi.encode(data), bytes(""));
    }

    function test_validation_RevertWhenSellTokenEqualsBuyToken() public {
        DutchAuction.Data memory data = helper_testData();
        data.sellToken = data.buyToken;

        helper_runRevertingValidate(data, ERR_SAME_TOKENS);
    }

    function test_validation_RevertWhenSellAmountInvalid() public {
        DutchAuction.Data memory data = helper_testData();
        data.sellAmount = 0;

        helper_runRevertingValidate(data, ERR_MIN_SELL_AMOUNT);
    }

    function test_validation_RevertWhenZeroDuration() public {
        DutchAuction.Data memory data = helper_testData();
        data.stepDuration = 0;

        helper_runRevertingValidate(data, ERR_MIN_AUCTION_DURATION);
    }

    function test_validation_RevertWhenNoDiscount() public {
        DutchAuction.Data memory data = helper_testData();
        data.stepDiscount = 0;

        helper_runRevertingValidate(data, ERR_MIN_STEP_DISCOUNT);
    }

    function test_validation_RevertWhenStepDiscountTooHigh() public {
        DutchAuction.Data memory data = helper_testData();
        data.stepDiscount = 10000;

        helper_runRevertingValidate(data, ERR_MAX_STEP_DISCOUNT);
    }

    function test_validation_RevertWhenTotalDiscountTooHigh() public {
        DutchAuction.Data memory data = helper_testData();
        data.stepDiscount = 5000;
        data.numSteps = 3;

        helper_runRevertingValidate(data, ERR_MAX_TOTAL_DISCOUNT);
    }

    function test_validation_RevertWhenStepsInsufficient() public {
        DutchAuction.Data memory data = helper_testData();
        data.numSteps = 1;

        helper_runRevertingValidate(data, ERR_MIN_NUM_STEPS);
    }

    function test_e2e_settle() public {
        DutchAuction.Data memory data = helper_testData();
        data.sellToken = token0;
        data.buyToken = token1;

        // create the order
        IConditionalOrder.ConditionalOrderParams memory params =
            super.createOrder(dutchAuction, keccak256("dutchAuction"), abi.encode(data));

        // create the order
        _create(address(safe1), params, false);
        // deal the sell token to the safe
        deal(address(data.sellToken), address(safe1), data.sellAmount * 2);
        // authorise the vault relayer to pull the sell token from the safe
        vm.prank(address(safe1));
        data.sellToken.approve(address(relayer), data.sellAmount * 2);
        data.buyTokenBalance = data.sellToken.balanceOf(address(safe1));

        // make sure we're at the start of the auction
        vm.warp(data.startTime);

        (GPv2Order.Data memory order, bytes memory sig) =
            composableCow.getTradeableOrderWithSignature(address(safe1), params, bytes(""), new bytes32[](0));

        uint256 safe1BalanceBefore = data.sellToken.balanceOf(address(safe1));

        settle(address(safe1), bob, order, sig, hex"");

        uint256 safe1BalanceAfter = data.sellToken.balanceOf(address(safe1));

        assertEq(safe1BalanceAfter, safe1BalanceBefore - data.sellAmount);

        // in the end-to-end, we can test replay protection by trying to settle again
        vm.warp(block.timestamp + 1);
        settle(
            address(safe1),
            bob,
            order,
            sig,
            abi.encodeWithSelector(IConditionalOrder.PollNever.selector, AUCTION_FILLED)
        );
    }

    function helper_runRevertingValidate(DutchAuction.Data memory data, string memory reason) internal {
        vm.expectRevert(abi.encodeWithSelector(IConditionalOrder.OrderNotValid.selector, reason));
        dutchAuction.validateData(abi.encode(data));
    }

    function helper_miningTime() internal returns (DutchAuction.Data memory, bytes32, DutchAuction, uint256) {
        DutchAuction.Data memory data = helper_testData();
        data.startTime = 0;
        // an example mining time
        uint32 startTime = 10_000;
        bytes32 id = 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef;

        DutchAuction auction = new DutchAuction(mockCowCabinet(COMPOSABLE_COW, safe, id, bytes32(uint256(startTime))));
        return (data, id, auction, startTime);
    }

    function helper_testData() internal view returns (DutchAuction.Data memory data) {
        return DutchAuction.Data({
            sellToken: token0,
            buyToken: token1,
            receiver: address(0x0),
            sellAmount: 1 ether,
            appData: APP_DATA,
            startTime: 1_000_000,
            startBuyAmount: 10 ether,
            stepDuration: 5 minutes,
            stepDiscount: 200, // 2%
            numSteps: 6, // total 10% discount
            buyTokenBalance: 0
        });
    }
}
