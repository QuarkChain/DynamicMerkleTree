//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../DynamicMerkleTree.sol";

import "./L2BridgeLib.sol";

contract L2BridgeDestination {
    using SafeERC20 for IERC20;

    bytes32 public receiptRoot;
    uint256 public nextReceiptId;
    mapping(bytes32 => bool) public transferBought; // storage root should be enough, but we use dynamic Merkle tree to simplify
    mapping(uint256 => bytes32) public boughtList; // not necessarily on-chain, but can simplify off-chain proof generation

    constructor() {}

    function getLPFee(L2BridgeLib.TransferData memory transferData)
        public
        view
        returns (uint256)
    {
        uint256 currentTime = block.timestamp;
        if (currentTime < transferData.startTime) {
            return 0;
        } else if (
            currentTime >= transferData.startTime + transferData.feeRampup
        ) {
            return transferData.fee;
        } else {
            return
                (transferData.fee * (currentTime - transferData.startTime)) /
                transferData.feeRampup;
        }
    }

    /*
     * buy the transfer token at source by exchange the corresponding destination token.
     */
    function buy(
        L2BridgeLib.TransferData memory transferData,
        bytes32[] memory appendProof
    ) public {
        bytes32 key = keccak256(abi.encode(transferData));
        require(!transferBought[key], "already bought");
        transferBought[key] = true;

        uint256 amount = transferData.amount - getLPFee(transferData);
        IERC20(transferData.dstTokenAddress).safeTransferFrom(
            msg.sender,
            transferData.destination,
            amount
        );

        // construct receipt and append it to Merkle tree
        L2BridgeLib.TransferReceipt memory receipt = L2BridgeLib
            .TransferReceipt({transferDataHash: key, lp: msg.sender});

        bytes32 receiptHash = keccak256(abi.encode(receipt));
        boughtList[nextReceiptId] = receiptHash;
        receiptRoot = DynamicMerkleTree.append(
            nextReceiptId,
            receiptRoot,
            receiptHash,
            appendProof
        );
        nextReceiptId += 1;
    }
}