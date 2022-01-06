// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "arb-shared-dependencies/contracts/ArbSys.sol";
import "arb-shared-dependencies/contracts/AddressAliasHelper.sol";

import "../L2BridgeDestination.sol";
import "../L2BridgeSource.sol";

contract ArbitrumBridgeDestination is L2BridgeDestination {
    ArbSys constant arbsys = ArbSys(address(100));
    address public l1Target;

    event L2ToL1TxCreated(uint256 indexed withdrawalId);

    constructor(address _l1Target) {
        l1Target = _l1Target;
    }

    /// @notice only owner can call
    function updateL1Target(address _l1Target) public {
        l1Target = _l1Target;
    }

    function updateReceiptRootToL1() public returns (uint256) {
        bytes memory data = abi.encodeWithSelector(
            L2BridgeSource.updateReceiptRoot.selector,
            receiptRoot
        );

        uint256 withdrawalId = arbsys.sendTxToL1(l1Target, data);

        emit L2ToL1TxCreated(withdrawalId);
        return withdrawalId;
    }
}
