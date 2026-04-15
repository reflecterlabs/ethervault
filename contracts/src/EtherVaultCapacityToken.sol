// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IEtherVaultCapacityToken} from "./interfaces/IEtherVaultCapacityToken.sol";

contract EtherVaultCapacityToken is IEtherVaultCapacityToken {
	error NotTreasury();
	error ZeroAddress();
	error InsufficientBalance();
	error InsufficientAllowance();

	string public name;
	string public symbol;
	uint8 public constant decimals = 18;
	address public treasury;

	uint256 public totalSupply;

	mapping(address => uint256) public override balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event TreasuryUpdated(address indexed treasury);

	constructor(string memory name_, string memory symbol_, address treasury_) {
		if (treasury_ == address(0)) {
			revert ZeroAddress();
		}

		name = name_;
		symbol = symbol_;
		treasury = treasury_;
		emit TreasuryUpdated(treasury_);
	}

	modifier onlyTreasury() {
		if (msg.sender != treasury) {
			revert NotTreasury();
		}
		_;
	}

	function transfer(address to, uint256 amount) external returns (bool) {
		_transfer(msg.sender, to, amount);
		return true;
	}

	function approve(address spender, uint256 amount) external returns (bool) {
		allowance[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function transferFrom(address from, address to, uint256 amount) external returns (bool) {
		uint256 currentAllowance = allowance[from][msg.sender];
		if (currentAllowance != type(uint256).max) {
			if (currentAllowance < amount) {
				revert InsufficientAllowance();
			}
			unchecked {
				allowance[from][msg.sender] = currentAllowance - amount;
			}
			emit Approval(from, msg.sender, allowance[from][msg.sender]);
		}

		_transfer(from, to, amount);
		return true;
	}

	function mint(address to, uint256 amount) external override onlyTreasury {
		if (to == address(0)) {
			revert ZeroAddress();
		}

		totalSupply += amount;
		balanceOf[to] += amount;
		emit Transfer(address(0), to, amount);
	}

	function burn(uint256 amount) external override onlyTreasury {
		uint256 currentBalance = balanceOf[address(this)];
		if (currentBalance < amount) {
			revert InsufficientBalance();
		}

		unchecked {
			balanceOf[address(this)] = currentBalance - amount;
			totalSupply -= amount;
		}
		emit Transfer(address(this), address(0), amount);
	}

	function setTreasury(address newTreasury) external onlyTreasury {
		if (newTreasury == address(0)) {
			revert ZeroAddress();
		}

		treasury = newTreasury;
		emit TreasuryUpdated(newTreasury);
	}

	function _transfer(address from, address to, uint256 amount) internal {
		if (from == address(0) || to == address(0)) {
			revert ZeroAddress();
		}

		uint256 fromBalance = balanceOf[from];
		if (fromBalance < amount) {
			revert InsufficientBalance();
		}

		unchecked {
			balanceOf[from] = fromBalance - amount;
			balanceOf[to] += amount;
		}

		emit Transfer(from, to, amount);
	}
}
