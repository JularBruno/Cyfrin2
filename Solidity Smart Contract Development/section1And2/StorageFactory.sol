// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SimpleStorage} from "./SimpleStorage.sol";

contract StorageFactory {

    SimpleStorage[] public listOfSimpleStorageContracts;

    function createSimpleStorageContract() public {
        SimpleStorage newListOfSimpleStorageContracts = new SimpleStorage();
        listOfSimpleStorageContracts.push(newListOfSimpleStorageContracts);
    }

    function sfStore(uint256 _simpleStorageIndex, uint256 _newSimpleStorageNumber) public {
        // address
        // abi (just need function selector) - application binary interface

        SimpleStorage mySimpleStorage = listOfSimpleStorageContracts[_simpleStorageIndex];
        // SimpleStorage mySimpleStorage = SimpleStorage(listOfAddress[_simpleStorageIndex])
        mySimpleStorage.store(_newSimpleStorageNumber);
    }

    function sfGet(uint256 _simpleStorageIndex) public view returns(uint256) {
        // SimpleStorage mySimpleStorage = listOfSimpleStorageContracts[_simpleStorageIndex];
        // return mySimpleStorage.retrieve();
        return listOfSimpleStorageContracts[_simpleStorageIndex].retrieve();
    }
}