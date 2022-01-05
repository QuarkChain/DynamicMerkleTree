// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "arb-shared-dependencies/contracts/ArbSys.sol";
import "arb-shared-dependencies/contracts/AddressAliasHelper.sol";

import "../L2BridgeSource.sol";

contract ArbitrumBridgeSource is L2BridgeSource {
    ArbSys constant arbsys = ArbSys(address(100));
    address public l1Target;

    event L2ToL1TxCreated(uint256 indexed withdrawalId);

    constructor(
        address _l1Target
    ) {
        l1Target = _l1Target;
    }

    /// @notice only owner can call
    function updateL1Target(address _l1Target) public {
        l1Target = _l1Target;
    }

    /// @notice only l1Target can update
    function updateReceiptRoot(bytes32 newRoot) public override {
        // To check that message came from L1, we check that the sender is the L1 contract's L2 alias.
        require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1Target), "only updateable by L1");
        L2BridgeSource.updateReceiptRoot(newRoot);
    }
}