// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

import "composable/BaseConditionalOrder.sol";
import "composable/interfaces/IAggregatorV3Interface.sol";
import {ConditionalOrdersUtilsLib as Utils} from "composable/types/ConditionalOrdersUtilsLib.sol";

interface IERC20Plus is IERC20 {
    function decimals() external view returns (uint256);
}

// --- error strings

string constant ORACLE_INVALID_PRICE = "oracle invalid price";

string constant ORACLE_STALE_PRICE = "oracle stale price";

string constant ILLEGAL_DELTA = "illegal delta";

bytes32 constant DOMAIN_SEPARATOR = 0xfb378b35457022ecc5709ae5dafad9393c1387ae6d8ce24913a0c969074c07fb;

contract Rebalance is BaseConditionalOrder {
    using Math for uint256;

    uint256 public tolerance = 5; // 5% tolerance for rebalancing

    struct Data {
        IERC20Plus[] assets;
        int256[] deltas; // Delta > 0: buy this asset, Delta < 0: sell this asset
        address targetPortfolio; // the EOA to be replicated by the user's Safe
        bytes32 appData;
        address receiver; // safe
        bool isPartiallyFillable;
        uint32 validityBucketSeconds; // use a default
        IAggregatorV3Interface[] assetsPriceOracles;
        uint256 maxTimeSinceLastOracleUpdate;
    }

    /// @dev Represents the asset to be rebalannced
    struct Asset {
        address token;
        uint256 decimals;
        int256 absoluteDelta;
        int256 percentageDelta;
        uint256 price;
        uint256 safeBalance;
        uint256 targetBalance;
    }

    function getTradeableOrder(
        address,
        address,
        bytes32,
        bytes calldata staticInput,
        bytes calldata
    ) public view override returns (GPv2Order.Data memory order) {
        Data memory data = abi.decode(staticInput, (Data));
        Asset[] memory assets = new Asset[](data.assets.length);

        // scope variables to avoid stack too deep error
        {
            for (uint256 i = 0; i < data.assets.length; i++) {
                // (, int256 basePrice,, uint256 sellUpdatedAt,) = data.sellTokenPriceOracle.latestRoundData();
                (, int256 basePrice, , uint256 _updatedAt, ) = data
                    .assetsPriceOracles[i]
                    .latestRoundData();
                // assets[i].price = basePrice;
                if (!(assets[i].price > 0)) {
                    revert IConditionalOrder.OrderNotValid(
                        ORACLE_INVALID_PRICE
                    );
                }
                if (
                    !(_updatedAt >=
                        block.timestamp - data.maxTimeSinceLastOracleUpdate)
                ) {
                    revert IConditionalOrder.OrderNotValid(ORACLE_STALE_PRICE);
                }

                assets[i].safeBalance = data.assets[i].balanceOf(msg.sender); // TODO: Check if msg.sender or some other param
                assets[i].targetBalance = data.assets[i].balanceOf(
                    data.targetPortfolio
                );
                assets[i].decimals = data.assets[i].decimals();
            }

            Asset[] memory computedAssets = computeAssetDeltas(assets);
            Asset memory shallExitAsset = computedAssets[0];
            Asset memory shallEnterAsset = computedAssets[0];
            for (uint256 i = 0; i < computedAssets.length; i++) {
                if (
                    computedAssets[i].percentageDelta >
                    shallExitAsset.percentageDelta
                ) {
                    shallEnterAsset = computedAssets[i];
                } else if (
                    computedAssets[i].percentageDelta <
                    shallExitAsset.percentageDelta
                ) {
                    shallExitAsset = computedAssets[i];
                }
            }

            if (
                uint256(shallExitAsset.percentageDelta) < tolerance ||
                uint256(shallEnterAsset.percentageDelta) < tolerance
            ) {
                revert IConditionalOrder.OrderNotValid(ILLEGAL_DELTA);
            }

            // Normalize the decimals for basePrice and quotePrice, scaling them to 18 decimals
            // Caution: Ensure that base and quote have the same numeraires (e.g. both are denominated in USD)
            // basePrice = Utils.scalePrice(basePrice, data.sellTokenPriceOracle.decimals(), 18);
            // quotePrice = Utils.scalePrice(quotePrice, data.buyTokenPriceOracle.decimals(), 18);

            /// @dev Scale the strike price to 18 decimals.
            // if (!(basePrice * SCALING_FACTOR / quotePrice <= data.strike)) {
            //     revert IConditionalOrder.OrderNotValid(STRIKE_NOT_REACHED);
            // }

            order = GPv2Order.Data(
                IERC20(shallExitAsset.token), // data.sellToken,
                IERC20(shallEnterAsset.token), // data.buyToken,
                data.receiver,
                uint256(shallExitAsset.absoluteDelta), // data.sellAmount,
                uint256(shallEnterAsset.absoluteDelta), // data.buyAmount,
                Utils.validToBucket(data.validityBucketSeconds),
                data.appData,
                0, // use zero fee
                GPv2Order.KIND_SELL,
                true,
                GPv2Order.BALANCE_ERC20,
                GPv2Order.BALANCE_ERC20
            );
        }
    }

    function rescaledAmountInDollars(
        uint256 _price,
        uint256 _decimals,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 value = _price * _amount;
        return value.ceilDiv(10 ** (_decimals * 2));
    }

    function totalPortfolioWeightedValues(
        Asset[] memory assets
    )
        public
        view
        returns (
            uint256 totalSafe,
            uint256 totalTarget,
            uint256[] memory positionValuesSafe,
            uint256[] memory positionValuesTarget
        )
    {
        positionValuesSafe = new uint256[](assets.length);
        positionValuesTarget = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 rescaledSafeValue = rescaledAmountInDollars(
                assets[i].price,
                assets[i].decimals,
                assets[i].safeBalance
            );
            uint256 rescaledTargetValue = rescaledAmountInDollars(
                assets[i].price,
                assets[i].decimals,
                assets[i].targetBalance
            );

            totalSafe += rescaledSafeValue;
            positionValuesSafe[i] = rescaledSafeValue;

            totalTarget += rescaledTargetValue;
            positionValuesTarget[i] = rescaledTargetValue;
        }
    }

    function computeAssetDeltas(
        Asset[] memory assets
    ) public view returns (Asset[] memory) {
        uint256[] memory weightsSafe = new uint256[](assets.length);
        uint256[] memory weightsTarget = new uint256[](assets.length);

        (
            uint256 totalSafe,
            uint256 totalTarget,
            uint256[] memory positionValuesSafe,
            uint256[] memory positionValuesTarget
        ) = totalPortfolioWeightedValues(assets);

        for (uint256 i = 0; i < assets.length; i++) {
            weightsSafe[i] = positionValuesSafe[i] / totalSafe;
            weightsTarget[i] = positionValuesTarget[i] / totalTarget;

            assets[i].percentageDelta =
                int256(weightsTarget[i]) -
                int256(weightsSafe[i]);

            assets[i].absoluteDelta =
                int256(positionValuesTarget[i]) -
                int256(positionValuesSafe[i]); //if delta is positive it means that we need to buy some asset
        }
        return assets;
    }

    /// @param orderDigest The EIP-712 signing digest derived from the order
    /// @param encodedOrder Bytes-encoded order information, originally created by an off-chain bot. Created by concatening the order data (in the form of GPv2Order.Data), the price checker address, and price checker data.
    function isValidSignature(
        bytes32 orderDigest,
        bytes calldata encodedOrder
    ) external view returns (bytes4) {
        GPv2Order.Data memory order = abi.decode(
            encodedOrder,
            (GPv2Order.Data)
        );
        require(
            GPv2Order.hash(order, DOMAIN_SEPARATOR) == orderDigest,
            "encoded order digest mismatch"
        );

        // return the GPv2EIP1271 magic value for eip1271
        return 0x1626ba7e;
    }
}
