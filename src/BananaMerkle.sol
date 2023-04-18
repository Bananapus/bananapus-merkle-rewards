// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract BananaMerkle is Ownable {
    error BananaMerkle_AlreadyClaimed();

    error BananaMerkle_NothingToClaim();

    event Claimed(address indexed claimer, uint256 amount);

    bytes32 public currentRoot;

    uint256 public blockHeightOfCurrentRoot;

    mapping(address _claimer=>uint256 lastClaimedBlockNumber) public lastClaimOf;

    constructor() {}

    function claim(uint256 amount, bytes32[] calldata proof) external {
        // Has already claimed during this period?
        if (lastClaimOf[msg.sender] > blockHeightOfCurrentRoot) revert BananaMerkle_AlreadyClaimed();

        // Check if in the tree
        bytes32 msgSenderLeaf = keccak256(abi.encodePacked(msg.sender, amount));
        if(!MerkleProof.verify(proof, currentRoot, msgSenderLeaf)) revert BananaMerkle_NothingToClaim();

        // Update last claimed block number
        lastClaimOf[msg.sender] = block.number;

        // Transfer token or start vesting

        // -- insert here --

        // Some event 
        emit Claimed(msg.sender, amount);
    }

    function updateRoot(bytes32 newRoot) external onlyOwner {
        currentRoot = newRoot;
        blockHeightOfCurrentRoot = block.number;
    }
}
