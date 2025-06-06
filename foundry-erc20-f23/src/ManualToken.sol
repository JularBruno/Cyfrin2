// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// follow eip erc20 token standard

contract ManualToken {
    mapping(address => uint256) private s_balances;

    // function name() public view returns (string memory) {
    //     return "Manual Token";
    // }
    string public name = "Manual Token";

    function totalSupply() public pure returns (uint256) {
        return 100 ether;
    } // this might require the decimal functoins

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return s_balances[_owner];
    }

    function transfer(address _to, uint256 _value) public {
        // msg.sender = _from
        uint256 previousBalances = balanceOf(msg.sender) + balanceOf(_to);
        s_balances[msg.sender] -= _value;
        s_balances[_to] += _value;

        require(balanceOf(msg.sender) + balanceOf(_to) == previousBalances);
    }

}