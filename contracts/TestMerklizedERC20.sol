//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./MerklizedERC20.sol";

contract TestMerklizedERC20 is MerklizedERC20 {
    constructor() MerklizedERC20("Test", "TEST") {}

    function mint(address addr, uint256 amount, bytes32[] memory proof) public {
        _mint(addr, amount, proof);
    }
}
