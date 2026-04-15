// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library FeePolicy {
	uint256 internal constant BPS_DENOMINATOR = 10_000;
	uint24 internal constant MAX_LP_FEE_PIPS = 1_000_000;

	function computeDynamicLpFee(
		uint256 utilizationBps,
		uint256 reserveCoverageBps,
		uint24 baseFeePips,
		uint24 maxFeePips
	) internal pure returns (uint24) {
		uint256 feePips = uint256(baseFeePips);

		feePips += utilizationBps * 35;

		if (reserveCoverageBps < BPS_DENOMINATOR) {
			feePips += (BPS_DENOMINATOR - reserveCoverageBps) * 20;
		}

		if (utilizationBps > 7_500) {
			feePips += (utilizationBps - 7_500) * 12;
		}

		uint256 cappedMax = maxFeePips == 0 ? MAX_LP_FEE_PIPS : uint256(maxFeePips);
		if (feePips > cappedMax) {
			feePips = cappedMax;
		}

		return uint24(feePips);
	}

	function calculateTreasuryFee(uint256 amount, uint16 treasuryFeeBps) internal pure returns (uint256) {
		return (amount * treasuryFeeBps) / BPS_DENOMINATOR;
	}

	function isExactIn(int256 amountSpecified) internal pure returns (bool) {
		return amountSpecified < 0;
	}
}
