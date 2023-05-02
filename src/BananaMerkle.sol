// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BananaMerkle is Ownable {
    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//
    error BananaMerkle_AlreadyClaimed();
    error BananaMerkle_NothingToClaim();
   
    // claim event 
    event Claimed(address indexed claimer, uint256 amount);

    /** 
    @notice 
    current merkle root.
    */
    bytes32 public currentRoot;

    /** 
    @notice 
    current block height.
    */
    uint256 public blockHeightOfCurrentRoot;

    /** 
    @notice 
    claimable token address.
    */
    IERC20 public immutable claiableToken;

    /** 
    @notice 
    user address => lastClaimedBlockNumber.
    */
    mapping(address _claimer=>uint256 lastClaimedBlockNumber) public lastClaimOf;

    /**
      @param _claiableToken claimable token address
    */
    constructor(IERC20 _claiableToken) {
        claiableToken = _claiableToken;
    }

    /** 
    @notice claim tokens depending on merkel root verification
    @param amount  amount to claim
    @param proof  merkel proof to verify
    */
    function claim(uint256 amount, bytes32[] calldata proof) external {
        // Has already claimed during this period?
        if (lastClaimOf[msg.sender] >= blockHeightOfCurrentRoot) revert BananaMerkle_AlreadyClaimed();

        // Check if in the tree
        bytes32 msgSenderLeaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));
        if(!MerkleProof.verifyCalldata(proof, currentRoot, msgSenderLeaf)) revert BananaMerkle_NothingToClaim();

        // Update last claimed block number
        lastClaimOf[msg.sender] = block.number;

        // Transfer token or start vesting
        bool success = claiableToken.transfer(msg.sender, amount);
        if (!success) revert();
 
        //TODO vesting logic

        // emit event 
        emit Claimed(msg.sender, amount);
    }

    /** 
    @notice update merkel root
    @param newRoot new merkel root
    */
    function updateRoot(bytes32 newRoot) external onlyOwner {
        currentRoot = newRoot;
        blockHeightOfCurrentRoot = block.number;
    }
}
