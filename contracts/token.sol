// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingToken is ERC20("Mock BUSD", "BUSD") {
    constructor() {
        // mint 1 million BUSD / 18 decimals
        _mint(msg.sender, 10**24);
    }
}