//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./L2BridgeSource.sol";

contract TestL2BridgeSource is L2BridgeSource {
    function getReceiptHash(L2BridgeLib.TransferData memory transferData)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(transferData));
    }
}