//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("Test", "TEST") {}

    function mint(address addr, uint256 amount) public {
        _mint(addr, amount);
    }
}

contract TestERC20WithName is ERC20 {
    constructor(string memory name) ERC20(name, name) {}

    function mint(address addr, uint256 amount) public {
        _mint(addr, amount);
    }
}
