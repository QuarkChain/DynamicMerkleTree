// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../L2BridgeSource.sol";

import "./iAbs_BaseCrossDomainMessenger.sol";

contract OptimismBridgeSource is L2BridgeSource {
    address public l1Target;
    iAbs_BaseCrossDomainMessenger public messenger =
        iAbs_BaseCrossDomainMessenger(
            0x4200000000000000000000000000000000000007
        );

    event L2ToL1TxCreated(uint256 indexed withdrawalId);

    constructor(address _l1Target) {
        l1Target = _l1Target;
    }

    /// @notice only owner can call
    function updateL1Target(address _l1Target) public {
        l1Target = _l1Target;
    }

    /// @notice only owner can call
    function updateMessenger(address _messenger) public {
        messenger = iAbs_BaseCrossDomainMessenger(_messenger);
    }

    /// @notice only l1Target can update
    function updateReceiptRoot(bytes32 newRoot) public override {
        // To check that message came from L1, we check that the sender is the L1 contract's L2 alias.
        require(msg.sender == address(messenger), "only message can call");
        require(
            messenger.xDomainMessageSender() == l1Target,
            "only updateable by L1"
        );
        L2BridgeSource.updateReceiptRoot(newRoot);
    }
}
