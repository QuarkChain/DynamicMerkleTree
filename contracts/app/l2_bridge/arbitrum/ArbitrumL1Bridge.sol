// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "arb-shared-dependencies/contracts/Inbox.sol";
import "arb-shared-dependencies/contracts/Outbox.sol";

import "../L2BridgeSource.sol";

contract ArbitrumL1Bridge {
    address public l2Source;
    address public l2Target;
    IInbox public inbox;
    bytes32 public receiptRoot;

    event RetryableTicketCreated(uint256 indexed ticketId);

    constructor(
        address _l2Source,
        address _l2Target,
        address _inbox
    ) {
        l2Source = _l2Source;
        l2Target = _l2Target;
        inbox = IInbox(_inbox);
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
    function setReceiptRootHashInL2Test(
        bytes32 newReceiptRoot,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    ) public payable returns (uint256) {
        bytes memory data =
            abi.encodeWithSelector(L2BridgeSource.updateReceiptRoot.selector, newReceiptRoot);
        
        uint256 ticketID = inbox.createRetryableTicket{value: msg.value}(
            l2Target,
            0,
            maxSubmissionCost,
            msg.sender,
            msg.sender,
            maxGas,
            gasPriceBid,
            data
        );

        emit RetryableTicketCreated(ticketID);
        return ticketID;
    }

    function setReceiptRootHashInL2(
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    ) public payable returns (uint256) {
        bytes memory data =
            abi.encodeWithSelector(L2BridgeSource.updateReceiptRoot.selector, receiptRoot);
        
        uint256 ticketID = inbox.createRetryableTicket{value: msg.value}(
            l2Target,
            0,
            maxSubmissionCost,
            msg.sender,
            msg.sender,
            maxGas,
            gasPriceBid,
            data
        );

        emit RetryableTicketCreated(ticketID);
        return ticketID;
    }

    /// @notice only l2Target can update
    function updateReceiptRoot(bytes32 newRoot) public {
        IOutbox outbox = IOutbox(inbox.bridge().activeOutbox());
        address l2Sender = outbox.l2ToL1Sender();
        require(l2Sender == l2Source, "receipt root only updateable by source L2");

        receiptRoot = newRoot;
    }
}