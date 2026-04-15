// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IEtherVaultTreasury {
	struct AssetConfig {
		bool enabled;
		uint8 decimals;
		uint256 usdWadPerToken;
	}

	function capacityToken() external view returns (address);

	function capacityUnitPriceWad() external view returns (uint256);

	function totalOutstandingCapacity() external view returns (uint256);

	function capacityCeiling() external view returns (uint256);

	function utilizationBps() external view returns (uint256);

	function setAssetConfig(address asset, uint8 decimals, uint256 usdWadPerToken, bool enabled) external;

	function setCapacityCeiling(uint256 newCeiling) external;

	function deposit(address asset, uint256 amount, address recipient) external returns (uint256 capacityMinted);

	function redeem(address asset, uint256 capacityAmount, address recipient) external returns (uint256 assetAmount);

	function routeProviderPayment(address asset, uint256 amount, address provider) external;
}
