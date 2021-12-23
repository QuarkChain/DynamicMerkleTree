//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../DynamicMerkleTree.sol";

library BridgeLib {
    struct TransferData {
        address tokenAddress;
        address destination;
        uint256 amount;
        uint256 startTime;
        uint256 feeRampup;
    }

    struct TransferInitiated {
        TransferData data;
        address self;
    }
}

contract BridgeSource {
    using SafeERC20 for IERC20;

    uint256 public nextTransferId;

    bytes32 public stateRoot;

    uint256 public constant CONTRACT_FEE_BASIS_POINTS = 5;

    constructor() {}

    function withdraw(
        BridgeLib.TransferData memory transferData,
        bytes32[] memory proof
    ) public {
        // safemath not needed for solidity 8
        uint256 amountPlusFee = (transferData.amount *
            (10000 + CONTRACT_FEE_BASIS_POINTS)) / 10000;
        IERC20(transferData.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amountPlusFee
        );

        BridgeLib.TransferInitiated memory transferInitiated = BridgeLib
            .TransferInitiated({data: transferData, self: address(this)});

        stateRoot = DynamicMerkleTree.append(
            nextTransferId,
            stateRoot,
            keccak256(abi.encode(transferInitiated)),
            proof
        );
        nextTransferId += 1;

        // TOOD: send the root to message box?
        // TODO: send the fee to bounty pool
    }
}

contract BridgeDestination {
    using SafeERC20 for IERC20;

    struct TransferKey {
        BridgeLib.TransferData transferData;
        uint256 transferId;
    }

    mapping(bytes32 => address) public ownerMap;

    mapping(bytes32 => bool) public validatedStateRoots;

    mapping(uint256 => bool) doneTransfers;

    constructor() {}

    function changeOwner(TransferKey memory tkey, address newOwner) public {
        bytes32 key = keccak256(abi.encode(tkey));
        require(ownerMap[key] == address(0x0), "owned");
        require(
            msg.sender == tkey.transferData.destination,
            "not from destination"
        );
        ownerMap[key] = newOwner;
    }

    function transferOwnership(TransferKey memory tkey, address newOwner)
        public
    {
        bytes32 key = keccak256(abi.encode(tkey));

        require(ownerMap[key] == msg.sender, "not from owner");
        ownerMap[key] = newOwner;
    }

    function getLPFee(BridgeLib.TransferData memory transferData)
        public
        view
        returns (uint256)
    {
        // TODO:
        return 0;
    }

    function buy(TransferKey memory tkey) public {
        uint256 amount = tkey.transferData.amount - getLPFee(tkey.transferData);
        // TODO: another token address on dest. chain?
        IERC20(tkey.transferData.tokenAddress).safeTransferFrom(
            msg.sender,
            tkey.transferData.destination,
            amount
        );

        bytes32 key = keccak256(abi.encode(tkey));
        ownerMap[key] = msg.sender;
    }

    function withdraw(
        TransferKey memory tkey,
        bytes32[] memory stateRootProof,
        bytes32 stateRoot,
        address sourceContract,
        uint256 transferLen,
        bytes32[] memory recordProof
    ) public {
        if (!validatedStateRoots[stateRoot]) {
            // TODO: prove stateRoot is in stateRootProof
        }

        require(!doneTransfers[tkey.transferId], "already transfered");

        BridgeLib.TransferInitiated memory transferInitiated = BridgeLib
            .TransferInitiated({data: tkey.transferData, self: sourceContract});

        DynamicMerkleTree.verify(
            tkey.transferId,
            transferLen,
            stateRoot,
            keccak256(abi.encode(transferInitiated)),
            recordProof
        );

        bytes32 key = keccak256(abi.encode(tkey));
        IERC20(tkey.transferData.tokenAddress).safeTransfer(
            ownerMap[key],
            tkey.transferData.amount
        );
        ownerMap[key] = address(2**160 - 1); // -1, not used any more
        doneTransfers[tkey.transferId] = true;
    }
}
