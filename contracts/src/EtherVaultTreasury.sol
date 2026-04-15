// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {EtherVaultCapacityToken} from "./EtherVaultCapacityToken.sol";
import {IEtherVaultTreasury} from "./interfaces/IEtherVaultTreasury.sol";

interface IERC20Like {
	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract EtherVaultTreasury is IEtherVaultTreasury {
	error NotOwner();
	error AssetDisabled();
	error ZeroAmount();
	error UnsupportedAsset();
	error InsufficientReserve();
	error InvalidCeiling();
	error NotConfigured();
	error TransferFailed();

	address public owner;
	EtherVaultCapacityToken public immutable override capacityToken;
	uint256 public override capacityUnitPriceWad;
	uint256 public override totalOutstandingCapacity;
	uint256 public override capacityCeiling;

	struct InternalAssetConfig {
		bool enabled;
		uint8 decimals;
		uint256 usdWadPerToken;
	}

	mapping(address => InternalAssetConfig) private assetConfigs;
	mapping(address => bool) private isSupportedAsset;
	address[] public supportedAssets;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event AssetConfigured(address indexed asset, uint8 decimals, uint256 usdWadPerToken, bool enabled);
	event CapacityCeilingUpdated(uint256 previousCeiling, uint256 newCeiling);
	event Deposited(address indexed asset, address indexed recipient, uint256 amount, uint256 capacityMinted);
	event Redeemed(address indexed asset, address indexed recipient, uint256 capacityBurned, uint256 assetAmount);
	event ProviderPaid(address indexed asset, address indexed provider, uint256 amount);

	constructor(address owner_, uint256 capacityUnitPriceWad_) {
		if (owner_ == address(0) || capacityUnitPriceWad_ == 0) {
			revert InvalidCeiling();
		}

		owner = owner_;
		capacityUnitPriceWad = capacityUnitPriceWad_;
		capacityToken = new EtherVaultCapacityToken("EtherVault Capacity", "EVCAP", address(this));
		capacityCeiling = type(uint256).max;
		emit OwnershipTransferred(address(0), owner_);
	}

	modifier onlyOwner() {
		if (msg.sender != owner) {
			revert NotOwner();
		}
		_;
	}

	function setAssetConfig(address asset, uint8 decimals, uint256 usdWadPerToken, bool enabled)
		external
		override
		onlyOwner
	{
		if (asset == address(0) || usdWadPerToken == 0) {
			revert UnsupportedAsset();
		}

		InternalAssetConfig storage config = assetConfigs[asset];
		if (!isSupportedAsset[asset]) {
			supportedAssets.push(asset);
			isSupportedAsset[asset] = true;
		}

		config.enabled = enabled;
		config.decimals = decimals;
		config.usdWadPerToken = usdWadPerToken;
		emit AssetConfigured(asset, decimals, usdWadPerToken, enabled);
	}

	function setCapacityCeiling(uint256 newCeiling) external override onlyOwner {
		if (newCeiling == 0) {
			revert InvalidCeiling();
		}

		emit CapacityCeilingUpdated(capacityCeiling, newCeiling);
		capacityCeiling = newCeiling;
	}

	function deposit(address asset, uint256 amount, address recipient)
		external
		override
		returns (uint256 capacityMinted)
	{
		if (amount == 0) {
			revert ZeroAmount();
		}

		InternalAssetConfig memory config = assetConfigs[asset];
		if (!config.enabled) {
			revert AssetDisabled();
		}

		uint256 normalizedAmount = _normalize(amount, config.decimals);
		capacityMinted = (normalizedAmount * config.usdWadPerToken) / capacityUnitPriceWad;
		if (capacityMinted == 0) {
			revert ZeroAmount();
		}

		if (!IERC20Like(asset).transferFrom(msg.sender, address(this), amount)) {
			revert TransferFailed();
		}

		if (totalOutstandingCapacity + capacityMinted > capacityCeiling) {
			revert InvalidCeiling();
		}

		totalOutstandingCapacity += capacityMinted;
		capacityToken.mint(recipient, capacityMinted);
		emit Deposited(asset, recipient, amount, capacityMinted);
	}

	function redeem(address asset, uint256 capacityAmount, address recipient)
		external
		override
		returns (uint256 assetAmount)
	{
		if (capacityAmount == 0) {
			revert ZeroAmount();
		}

		InternalAssetConfig memory config = assetConfigs[asset];
		if (!config.enabled) {
			revert AssetDisabled();
		}

		capacityToken.transferFrom(msg.sender, address(this), capacityAmount);
		capacityToken.burn(capacityAmount);

		if (totalOutstandingCapacity < capacityAmount) {
			revert InsufficientReserve();
		}

		totalOutstandingCapacity -= capacityAmount;
		uint256 normalizedAssetAmount = (capacityAmount * capacityUnitPriceWad) / config.usdWadPerToken;
		assetAmount = _denormalize(normalizedAssetAmount, config.decimals);

		uint256 reserveBalance = IERC20Like(asset).balanceOf(address(this));
		if (reserveBalance < assetAmount) {
			revert InsufficientReserve();
		}

		if (!IERC20Like(asset).transfer(recipient, assetAmount)) {
			revert TransferFailed();
		}

		emit Redeemed(asset, recipient, capacityAmount, assetAmount);
	}

	function routeProviderPayment(address asset, uint256 amount, address provider) external override onlyOwner {
		if (amount == 0) {
			revert ZeroAmount();
		}

		if (!assetConfigs[asset].enabled) {
			revert AssetDisabled();
		}

		if (!IERC20Like(asset).transfer(provider, amount)) {
			revert TransferFailed();
		}

		emit ProviderPaid(asset, provider, amount);
	}

	function utilizationBps() public view override returns (uint256) {
		if (capacityCeiling == 0) {
			return 0;
		}

		return (totalOutstandingCapacity * 10_000) / capacityCeiling;
	}

	function getAssetConfig(address asset) external view returns (AssetConfig memory config) {
		InternalAssetConfig memory internalConfig = assetConfigs[asset];
		config = AssetConfig({
			enabled: internalConfig.enabled,
			decimals: internalConfig.decimals,
			usdWadPerToken: internalConfig.usdWadPerToken
		});
	}

	function supportedAssetCount() external view returns (uint256) {
		return supportedAssets.length;
	}

	function supportedAssetAt(uint256 index) external view returns (address) {
		return supportedAssets[index];
	}

	function _normalize(uint256 amount, uint8 decimals) internal pure returns (uint256) {
		if (decimals == 18) {
			return amount;
		}
		if (decimals > 18) {
			return amount / (10 ** (decimals - 18));
		}
		return amount * (10 ** (18 - decimals));
	}

	function _denormalize(uint256 amount, uint8 decimals) internal pure returns (uint256) {
		if (decimals == 18) {
			return amount;
		}
		if (decimals > 18) {
			return amount * (10 ** (decimals - 18));
		}
		return amount / (10 ** (18 - decimals));
	}
}
