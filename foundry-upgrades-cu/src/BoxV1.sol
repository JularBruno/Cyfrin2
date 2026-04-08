// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BoxV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
	uint256 internal number;

	constructor() {
		_disableInitializers();
	}

	function initialize() public initializer {
		__Ownable_init();
		__UUPSUpgradeable_init();
	}

	function getNumber() external view returns (uint256) {
		return number;
	}

	function version() external pure returns (uint256) {
		return 1;
	}

	function _authorizeUpgrade(address newImplementation) internal override {}

}