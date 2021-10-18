//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./DynamicMerkleTree.sol";

contract MerklizedStaking {
    using SafeERC20 for IERC20;

    struct TreeNode {
        address addr;
        uint256 balance;
    }

    mapping(address => uint256) private _indices1; // 1-based index

    mapping(address => uint256) private _balances;

    uint256 public len;

    IERC20 public token;

    bytes32 public rootHash;

    constructor(IERC20 _token) {
        token = _token;
    }

    function stake(uint256 _amount, bytes32[] memory _proof) public {
        token.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _idx1 = _indices1[msg.sender];
        if (_idx1 == 0) {
            TreeNode memory node = TreeNode({
                addr: msg.sender,
                balance: _amount
            });

            rootHash = DynamicMerkleTree.append(
                len,
                rootHash,
                keccak256(abi.encode(node)),
                _proof
            );
            len = len + 1;
            _indices1[msg.sender] = len;
            _balances[msg.sender] = _amount;
        } else {
            TreeNode memory oldNode = TreeNode({
                addr: msg.sender,
                balance: _balances[msg.sender]
            });

            _balances[msg.sender] += _amount;

            TreeNode memory newNode = TreeNode({
                addr: msg.sender,
                balance: _balances[msg.sender]
            });

            rootHash = DynamicMerkleTree.update(
                _idx1 - 1,
                len,
                rootHash,
                keccak256(abi.encode(oldNode)),
                keccak256(abi.encode(newNode)),
                _proof
            );
        }
    }

    function unstake(bytes32[] memory _proof) public {
        uint256 _idx1 = _indices1[msg.sender];

        if (_idx1 == 0) {
            return; // not exist
        }

        uint256 amount = _balances[msg.sender];
        TreeNode memory oldNode = TreeNode({addr: msg.sender, balance: amount});

        _balances[msg.sender] = 0;

        TreeNode memory newNode = TreeNode({addr: msg.sender, balance: 0});

        rootHash = DynamicMerkleTree.update(
            _idx1 - 1,
            len,
            rootHash,
            keccak256(abi.encode(oldNode)),
            keccak256(abi.encode(newNode)),
            _proof
        );

        token.safeTransfer(msg.sender, amount);
    }
}
