// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IEtherVaultTreasury} from "./interfaces/IEtherVaultTreasury.sol";

interface IERC20RouterLike {
	function transferFrom(address from, address to, uint256 amount) external returns (bool);

	function transfer(address to, uint256 amount) external returns (bool);
}

contract EtherVaultSettlementRouter {
	error NotOwner();
	error ZeroAddress();
	error ZeroAmount();
	error TransferFailed();

	address public owner;
	IEtherVaultTreasury public immutable treasury;

	event RouteConfigured(address indexed asset, address indexed provider, uint16 treasuryShareBps);
	event RouteExecuted(address indexed asset, address indexed provider, uint256 treasuryAmount, uint256 providerAmount);

	struct RouteConfig {
		address provider;
		uint16 treasuryShareBps;
		bool enabled;
	}

	mapping(address => RouteConfig) public routes;

	constructor(address owner_, IEtherVaultTreasury treasury_) {
		if (owner_ == address(0)) {
			revert ZeroAddress();
		}

		owner = owner_;
		treasury = treasury_;
	}

	modifier onlyOwner() {
		if (msg.sender != owner) {
			revert NotOwner();
		}
		_;
	}

	function setRoute(address asset, address provider, uint16 treasuryShareBps, bool enabled) external onlyOwner {
		if (asset == address(0) || provider == address(0)) {
			revert ZeroAddress();
		}
		if (treasuryShareBps > 10_000) {
			revert ZeroAmount();
		}

		routes[asset] = RouteConfig({provider: provider, treasuryShareBps: treasuryShareBps, enabled: enabled});
		emit RouteConfigured(asset, provider, treasuryShareBps);
	}

	function route(address asset, uint256 amount) external returns (uint256 treasuryAmount, uint256 providerAmount) {
		if (amount == 0) {
			revert ZeroAmount();
		}

		RouteConfig memory config = routes[asset];
		if (!config.enabled || config.provider == address(0)) {
			revert ZeroAddress();
		}

		if (!IERC20RouterLike(asset).transferFrom(msg.sender, address(this), amount)) {
			revert TransferFailed();
		}

		treasuryAmount = (amount * config.treasuryShareBps) / 10_000;
		providerAmount = amount - treasuryAmount;

		if (treasuryAmount > 0) {
			if (!IERC20RouterLike(asset).transfer(address(treasury), treasuryAmount)) {
				revert TransferFailed();
			}
		}

		if (providerAmount > 0) {
			if (!IERC20RouterLike(asset).transfer(config.provider, providerAmount)) {
				revert TransferFailed();
			}
		}

		emit RouteExecuted(asset, config.provider, treasuryAmount, providerAmount);
	}
}
