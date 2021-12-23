//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Bridge.sol";

contract TestBridgeDestination is BridgeDestination {
    function verifyStateRoot(bytes32 stateRoot, bytes32[] memory stateRootProof)
        internal
        pure
        override
    {
        // pass
    }
}
