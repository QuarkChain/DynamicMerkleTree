//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

library DynamicMerkleTree {
    function calcRootHash(
        uint256 _idx,
        uint256 _len,
        bytes32 _leafHash,
        bytes32[] memory _proof
    ) internal pure returns (bytes32 _rootHash) {
        if (_len == 0) {
            return bytes32(0);
        }

        uint256 _proofIdx = 0;
        bytes32 _nodeHash = _leafHash;

        while (_len > 1) {
            uint256 _peerIdx = (_idx / 2) * 2;
            bytes32 _peerHash = bytes32(0);
            if (_peerIdx == _idx) {
                _peerIdx += 1;
            }
            if (_peerIdx < _len) {
                _peerHash = _proof[_proofIdx];
                _proofIdx += 1;
            }

            bytes32 _parentHash = bytes32(0);
            if (_peerIdx >= _len && _idx >= _len) {
                // pass, _parentHash = bytes32(0)
            } else if (_peerIdx > _idx) {
                _parentHash = keccak256(abi.encodePacked(_nodeHash, _peerHash));
            } else {
                _parentHash = keccak256(abi.encodePacked(_peerHash, _nodeHash));
            }

            _len = (_len - 1) / 2 + 1;
            _idx = _idx / 2;
            _nodeHash = _parentHash;
        }

        return _nodeHash;
    }

    function calcRootHashWithoutLength(
        uint256 _idx,
        bytes32 _leafHash,
        bytes32[] memory _proof
    ) internal pure returns (bytes32 _rootHash) {
        bytes32 _nodeHash = _leafHash;

        for (uint256 i = 0; i < _proof.length; i++) {
            uint256 _peerIdx = (_idx / 2) * 2;
            bytes32 _peerHash = _proof[i];
            bytes32 _parentHash = bytes32(0);
            if (_peerIdx > _idx) {
                _parentHash = keccak256(abi.encodePacked(_nodeHash, _peerHash));
            } else {
                _parentHash = keccak256(abi.encodePacked(_peerHash, _nodeHash));
            }

            _idx = _idx / 2;
            _nodeHash = _parentHash;
        }

        return _nodeHash;
    }

    function verify(
        uint256 _idx,
        uint256 _len,
        bytes32 _root,
        bytes32 _oldLeafHash,
        bytes32[] memory _proof
    ) internal pure returns (bool) {
        return calcRootHash(_idx, _len, _oldLeafHash, _proof) == _root;
    }

    function update(
        uint256 _idx,
        uint256 _len,
        bytes32 _oldRoot,
        bytes32 _oldLeafHash,
        bytes32 _newLeafHash,
        bytes32[] memory _proof
    ) internal pure returns (bytes32 _newRoot) {
        require(
            verify(_idx, _len, _oldRoot, _oldLeafHash, _proof),
            "ERR_PROOF"
        );
        return calcRootHash(_idx, _len, _newLeafHash, _proof);
    }

    function append(
        uint256 _len,
        bytes32 _oldRoot,
        bytes32 _leafHash,
        bytes32[] memory _proof
    ) internal pure returns (bytes32 _newRoot) {
        if (_len > 0) {
            if ((_len & (_len - 1)) == 0) {
                // 2^n, a new layer will be added.
                require(_proof[0] == _oldRoot, "ERR_PROOF");
            } else {
                require(
                    verify(_len, _len, _oldRoot, bytes32(0), _proof),
                    "ERR_PROOF"
                );
            }
        }

        return calcRootHash(_len, _len + 1, _leafHash, _proof);
    }
}
