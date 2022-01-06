// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../L2BridgeSource.sol";

import "./iAbs_BaseCrossDomainMessenger.sol";

contract OptimismL1Bridge {
    address public l2Source;
    address public l2Target;
    iAbs_BaseCrossDomainMessenger public messenger;
    bytes32 public receiptRoot;

    event MessageSent(address indexed target, bytes32 root, uint256 maxGas);

    constructor(
        address _l2Source,
        address _l2Target,
        address _messenger
    ) {
        l2Source = _l2Source;
        l2Target = _l2Target;
        messenger = iAbs_BaseCrossDomainMessenger(_messenger);
    }

    /// @notice only owner can call
    function updateL2Target(address _l2Target) public {
        l2Target = _l2Target;
    }

    /// @notice only owner can call
    function updateL2Source(address _l2Source) public {
        l2Source = _l2Source;
    }

    /// @notice test only.
    function setReceiptRootHashInL2Test(bytes32 newReceiptRoot, uint32 maxGas)
        public
        payable
    {
        bytes memory data = abi.encodeWithSelector(
            L2BridgeSource.updateReceiptRoot.selector,
            newReceiptRoot
        );

        messenger.sendMessage(l2Target, data, maxGas);

        emit MessageSent(l2Target, newReceiptRoot, maxGas);
    }

    function setReceiptRootHashInL2(uint32 maxGas) public payable {
        bytes memory data = abi.encodeWithSelector(
            L2BridgeSource.updateReceiptRoot.selector,
            receiptRoot
        );

        messenger.sendMessage(l2Target, data, maxGas);

        emit MessageSent(l2Target, receiptRoot, maxGas);
    }

    /// @notice only l2Target can update
    function updateReceiptRoot(bytes32 newRoot) public {
        iAbs_BaseCrossDomainMessenger messenger = iAbs_BaseCrossDomainMessenger(
            msg.sender
        );
        address l2Sender = messenger.xDomainMessageSender();
        require(
            l2Sender == l2Source,
            "receipt root only updateable by source L2"
        );

        receiptRoot = newRoot;
    }
}
