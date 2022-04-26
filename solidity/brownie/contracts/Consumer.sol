//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStarknetCore.sol";

contract Consumer {
    IStarknetCore starknetCore;
    uint public governor;
    uint public balance;

    constructor(uint _governor, address _starknetCore) {
        starknetCore = IStarknetCore(_starknetCore);
        governor = _governor;
    }

    function increase_balance(uint256 amount) public{
        uint256[] memory payload = new uint256[](1);
        payload[0] = amount;
        starknetCore.consumeMessageFromL2(governor, payload);
        balance += amount;
    }

  
}
