// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SimpleStorage} from "./SimpleStorage.sol";


contract AddFiveStorage is SimpleStorage {

    // virtual override
    function store(uint256 _favoriteNumber) public override {
        myFavoriteNumber = _favoriteNumber +5;
    }
}
