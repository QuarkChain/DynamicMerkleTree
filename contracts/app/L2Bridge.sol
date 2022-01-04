//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../DynamicMerkleTree.sol";

library L2BridgeLib {
    struct TransferData {
        address srcTokenAddress;
        address dstTokenAddress;
        address destination;
        uint256 amount;
        uint256 fee;
        uint256 startTime;
        uint256 feeRampup;
        uint256 expiration;
    }

    struct TransferReceipt {
        bytes32 transferDataHash;
        address lp;
    }
}

contract L2BridgeSource {
    using SafeERC20 for IERC20;

    uint256 public constant XFER_NEW = 0;
    uint256 public constant XFER_PENDING = 1;
    uint256 public constant XFER_EXPIRED = 2;
    uint256 public constant XFER_DONE = 3;

    mapping(bytes32 => uint256) public transferStatus;

    bytes32 public receiptRoot;

    constructor() {}

    /*
     * deposit the user's fund and request to exchange token at destination.
     */
    function deposit(L2BridgeLib.TransferData memory transferData) public {
        bytes32 key = keccak256(abi.encode(transferData));
        require(transferStatus[key] == XFER_NEW, "not new");

        IERC20(transferData.srcTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            transferData.amount
        );

        transferStatus[key] = XFER_PENDING;
    }

    /*
     * refund the user's fund after expiration (no LP exchanges the token at dest.).
     */
    function refund(L2BridgeLib.TransferData memory transferData) public {
        bytes32 key = keccak256(abi.encode(transferData));
        require(transferStatus[key] == XFER_PENDING, "not pending");
        require(transferData.expiration < block.timestamp, "not expire");

        IERC20(transferData.srcTokenAddress).safeTransfer(
            transferData.destination,
            transferData.amount
        );

        transferStatus[key] = XFER_EXPIRED;
    }

    /*
     * withdraw the user's fund by LP after providing the liquidity at destination with
     * confirmed receipt root.
     */
    function withdraw(
        L2BridgeLib.TransferData memory transferData,
        uint256 receiptIdx,
        uint256 receiptLen,
        bytes32[] memory receiptProof
    ) public {
        bytes32 key = keccak256(abi.encode(transferData));
        require(transferStatus[key] == XFER_PENDING, "not pending");
        require(receiptIdx < receiptLen, "invalid idx");

        // construct receipt and verify whether it is completed.
        L2BridgeLib.TransferReceipt memory receipt = L2BridgeLib
            .TransferReceipt({transferDataHash: key, lp: msg.sender});

        require(
            DynamicMerkleTree.verify(
                receiptIdx,
                receiptLen,
                receiptRoot,
                keccak256(abi.encode(receipt)),
                receiptProof
            ),
            "fail to prove"
        );

        IERC20(transferData.srcTokenAddress).safeTransfer(
            msg.sender,
            transferData.amount
        );

        transferStatus[key] = XFER_DONE;
    }
}

contract L2BridgeDestination {
    using SafeERC20 for IERC20;

    bytes32 public receiptRoot;
    uint256 public nextReceiptId;
    mapping(bytes32 => bool) public transferBought; // storage root should be enough, but we use dynamic Merkle tree to simplify

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

        receiptRoot = DynamicMerkleTree.append(
            nextReceiptId,
            receiptRoot,
            keccak256(abi.encode(receipt)),
            appendProof
        );
        nextReceiptId += 1;
    }
}

contract TestL2BridgeSource is L2BridgeSource {
    function updateReceiptRoot(bytes32 newRoot) public {
        receiptRoot = newRoot;
    }

    function getReceiptHash(L2BridgeLib.TransferData memory transferData)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(transferData));
    }
}
