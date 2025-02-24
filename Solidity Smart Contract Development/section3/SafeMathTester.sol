// safemath was used everywhere before 0.8 version of solidity

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0; // this the one used in the example
// pragma solidity ^0.8.0;
pragma solidity ^0.8.24;


contract SafeMathTester { 
    uint8 public bigNumber = 255; // unchecked, safe math was used to wraph

    function add() public {
        bigNumber = bigNumber +1;
        // unchecked {bigNumber = bigNumber +1;} // UNCHECKED can be used in versions above 0.8 USEFUL FOR spending less gas when sure number doesnt break
    }
}