//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
