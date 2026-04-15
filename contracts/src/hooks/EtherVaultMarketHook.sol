// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";

import {FeePolicy} from "../libraries/FeePolicy.sol";
import {IEtherVaultTreasury} from "../interfaces/IEtherVaultTreasury.sol";

contract EtherVaultMarketHook is BaseHook {
	using LPFeeLibrary for uint24;

	error NotOwner();
	error NotPoolManager();
	error ZeroAddress();
	error TreasuryFeeTooHigh();

	address public owner;
	IEtherVaultTreasury public treasury;
	uint24 public baseFeePips;
	uint24 public maxFeePips;
	uint16 public treasuryFeeBps;
	uint256 public reserveCoverageTargetBps;

	event FeePolicyUpdated(uint24 baseFeePips, uint24 maxFeePips, uint16 treasuryFeeBps, uint256 reserveCoverageTargetBps);
	event TreasuryUpdated(address indexed treasury);
	event LiquidityObserved(bytes32 indexed poolId, int256 liquidityDelta, int256 feesAccrued);
	event TreasuryFeeCaptured(address indexed currency, uint256 amount);
	event DynamicFeeUpdated(bytes32 indexed poolId, uint24 feePips);

	constructor(
		IPoolManager poolManager,
		IEtherVaultTreasury treasury_,
		uint24 baseFeePips_,
		uint24 maxFeePips_,
		uint16 treasuryFeeBps_,
		uint256 reserveCoverageTargetBps_
	) BaseHook(poolManager) {
		if (address(treasury_) == address(0)) {
			revert ZeroAddress();
		}
		if (treasuryFeeBps_ > 10_000) {
			revert TreasuryFeeTooHigh();
		}

		owner = msg.sender;
		treasury = treasury_;
		baseFeePips = baseFeePips_;
		maxFeePips = maxFeePips_;
		treasuryFeeBps = treasuryFeeBps_;
		reserveCoverageTargetBps = reserveCoverageTargetBps_;
		emit TreasuryUpdated(address(treasury_));
		emit FeePolicyUpdated(baseFeePips_, maxFeePips_, treasuryFeeBps_, reserveCoverageTargetBps_);
	}

	modifier onlyOwner() {
		if (msg.sender != owner) {
			revert NotOwner();
		}
		_;
	}

	modifier onlyPoolManager() {
		if (msg.sender != address(poolManager)) {
			revert NotPoolManager();
		}
		_;
	}

	function getHookPermissions() public pure override returns (Hooks.Permissions memory permissions) {
		permissions = Hooks.Permissions({
			beforeInitialize: false,
			afterInitialize: true,
			beforeAddLiquidity: true,
			afterAddLiquidity: true,
			beforeRemoveLiquidity: true,
			afterRemoveLiquidity: true,
			beforeSwap: true,
			afterSwap: true,
			beforeDonate: false,
			afterDonate: false,
			beforeSwapReturnDelta: false,
			afterSwapReturnDelta: true,
			afterAddLiquidityReturnDelta: false,
			afterRemoveLiquidityReturnDelta: false
		});
	}

	function setTreasury(IEtherVaultTreasury treasury_) external onlyOwner {
		if (address(treasury_) == address(0)) {
			revert ZeroAddress();
		}

		treasury = treasury_;
		emit TreasuryUpdated(address(treasury_));
	}

	function setFeePolicy(
		uint24 baseFeePips_,
		uint24 maxFeePips_,
		uint16 treasuryFeeBps_,
		uint256 reserveCoverageTargetBps_
	) external onlyOwner {
		if (treasuryFeeBps_ > 10_000) {
			revert TreasuryFeeTooHigh();
		}

		baseFeePips = baseFeePips_;
		maxFeePips = maxFeePips_;
		treasuryFeeBps = treasuryFeeBps_;
		reserveCoverageTargetBps = reserveCoverageTargetBps_;
		emit FeePolicyUpdated(baseFeePips_, maxFeePips_, treasuryFeeBps_, reserveCoverageTargetBps_);
	}

	function beforeAddLiquidity(
		address,
		PoolKey calldata,
		bytes calldata
	) external override onlyPoolManager returns (bytes4) {
		return IHooks.beforeAddLiquidity.selector;
	}

	function afterAddLiquidity(
		address,
		PoolKey calldata key,
		bytes calldata,
		BalanceDelta,
		BalanceDelta,
		bytes calldata
	) external override onlyPoolManager returns (bytes4, BalanceDelta) {
		emit LiquidityObserved(_poolId(key), 0, 0);
		return (IHooks.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
	}

	function beforeRemoveLiquidity(
		address,
		PoolKey calldata,
		bytes calldata
	) external override onlyPoolManager returns (bytes4) {
		return IHooks.beforeRemoveLiquidity.selector;
	}

	function afterRemoveLiquidity(
		address,
		PoolKey calldata key,
		bytes calldata,
		BalanceDelta,
		BalanceDelta,
		bytes calldata
	) external override onlyPoolManager returns (bytes4, BalanceDelta) {
		emit LiquidityObserved(_poolId(key), 0, 0);
		return (IHooks.afterRemoveLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
	}

	function afterInitialize(
		address,
		PoolKey calldata key,
		uint160,
		int24
	) external override onlyPoolManager returns (bytes4) {
		uint24 initialFee = _currentFeePips();
		poolManager.updateDynamicLPFee(key, initialFee);
		emit DynamicFeeUpdated(_poolId(key), initialFee);
		return IHooks.afterInitialize.selector;
	}

	function beforeSwap(
		address,
		PoolKey calldata,
		SwapParams calldata,
		bytes calldata
	) external override onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
		uint24 feePips = _currentFeePips();
		return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, feePips | LPFeeLibrary.OVERRIDE_FEE_FLAG);
	}

	function afterSwap(
		address,
		PoolKey calldata key,
		SwapParams calldata params,
		BalanceDelta,
		bytes calldata
	) external override onlyPoolManager returns (bytes4, int128) {
		uint256 amount = _absAmount(params.amountSpecified);
		Currency feeCurrency = params.zeroForOne ? (params.amountSpecified < 0 ? key.currency1 : key.currency0) : (params.amountSpecified < 0 ? key.currency0 : key.currency1);
		uint256 treasuryFee = FeePolicy.calculateTreasuryFee(amount, treasuryFeeBps);

		if (treasuryFee > 0) {
			poolManager.take(feeCurrency, address(treasury), treasuryFee);
			emit TreasuryFeeCaptured(_currencyAddress(feeCurrency), treasuryFee);
			return (IHooks.afterSwap.selector, int128(int256(treasuryFee)));
		}

		return (IHooks.afterSwap.selector, 0);
	}

	function beforeDonate(
		address,
		PoolKey calldata,
		uint256,
		uint256,
		bytes calldata
	) external pure override onlyPoolManager returns (bytes4) {
		return IHooks.beforeDonate.selector;
	}

	function afterDonate(
		address,
		PoolKey calldata,
		uint256,
		uint256,
		bytes calldata
	) external pure override onlyPoolManager returns (bytes4) {
		return IHooks.afterDonate.selector;
	}

	function _currentFeePips() internal view returns (uint24) {
		uint256 utilization = treasury.utilizationBps();
		return FeePolicy.computeDynamicLpFee(utilization, reserveCoverageTargetBps, baseFeePips, maxFeePips);
	}

	function _poolId(PoolKey calldata key) internal pure returns (bytes32) {
		return keccak256(abi.encode(key.currency0, key.currency1, key.fee, key.tickSpacing, key.hooks));
	}

	function _currencyAddress(Currency currency) internal pure returns (address) {
		return Currency.unwrap(currency);
	}

	function _absAmount(int256 value) internal pure returns (uint256) {
		return value < 0 ? uint256(-value) : uint256(value);
	}
}
