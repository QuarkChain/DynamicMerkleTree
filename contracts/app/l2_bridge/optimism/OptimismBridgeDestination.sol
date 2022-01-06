// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../L2BridgeDestination.sol";
import "../L2BridgeSource.sol";

import "./iAbs_BaseCrossDomainMessenger.sol";

contract OptimismBridgeDestination is L2BridgeDestination {
    address public l1Target;
    iAbs_BaseCrossDomainMessenger public messenger =
        iAbs_BaseCrossDomainMessenger(
            0x4200000000000000000000000000000000000007
        );

    event L2ToL1TxCreated(bytes32 root);

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

    function updateReceiptRootToL1(uint32 maxGas) public {
        bytes memory data = abi.encodeWithSelector(
            L2BridgeSource.updateReceiptRoot.selector,
            receiptRoot
        );

        messenger.sendMessage(l1Target, data, maxGas);

        emit L2ToL1TxCreated(receiptRoot);
    }
}
