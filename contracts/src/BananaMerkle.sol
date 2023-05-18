// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BananaMerkle
 * @notice BananaMerkle allows its owner to upload new merkle roots over time, allowing different addresses to claim pre-defined amounts of the contract's claimable ERC-20 token. Claimable amounts and recipients are defined in the merkle tree specified by the root, and the ERC-20 token is defined during construction.
 * @dev The merkle root can be updated by this contract's owner at any time.
 * @dev This contract uses OpenZeppelin's [MerkleProof](https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof) utilities. Also see the [@openzeppelin/merkle-tree](https://github.com/OpenZeppelin/merkle-tree) JavaScript library.
 */
contract BananaMerkle is Ownable {
    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//
    error BananaMerkle_AlreadyClaimed();
    error BananaMerkle_NothingToClaim();

    // Claim event
    event Claimed(address indexed claimer, uint256 amount);

    /**
     * @notice The current merkle root.
     */
    bytes32 public currentRoot;

    /**
     * @notice The block in which the current merkle root was last updated.
     */
    uint256 public blockHeightForCurrentRoot;

    /**
     * @notice The address of the ERC-20 token which can be claimed from this contract.
     */
    IERC20 public immutable claimableToken;

    /**
     * @notice The most recent block number at which an address has claimed.
     * @dev Mapping of claimer address => block number they last called claim(...).
     * @return lastClaimedBlockNumber The block number at which an address last called claim(...).
     */
    mapping(address _claimer => uint256 lastClaimedBlockNumber) public lastClaimOf;

    /**
     * @param _claimableToken The ERC-20 token which can be claimed from this contract.
     */
    constructor(IERC20 _claimableToken) {
        claimableToken = _claimableToken;
    }

    /**
     * @notice Check if the sender can claim tokens using the provided proof, and if they can, claim the ERC-20 tokens.
     * @param amount The number of claimable ERC-20 tokens to claim.
     * @param proof The merkle proof which proves that the sender's address and amount are within the merkle tree defined by the root.
     * @dev proof is a [MerkleProof](https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof) proof.
     */
    function claim(uint256 amount, bytes32[] calldata proof) external {
        // Revert if the sender has already claimed under the current merkle root.
        if (lastClaimOf[msg.sender] >= blockHeightForCurrentRoot) revert BananaMerkle_AlreadyClaimed();

        // Verify the claimer and amount using the merkle proof.
        bytes32 msgSenderLeaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));
        if (!MerkleProof.verifyCalldata(proof, currentRoot, msgSenderLeaf)) revert BananaMerkle_NothingToClaim();

        // Store the current block as the claimer's last claimed block number.
        lastClaimOf[msg.sender] = block.number;

        // Transfer tokens.
        bool success = claimableToken.transfer(msg.sender, amount);
        if (!success) revert();

        emit Claimed(msg.sender, amount);
    }

    /**
     * @notice Update the merkle root. This function can only be called by the contract's owner.
     * @param newRoot The new merkle root.
     * @dev Uses OpenZeppelin's [MerkleProof](https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof) library.
     */
    function updateRoot(bytes32 newRoot) external onlyOwner {
        currentRoot = newRoot;
        blockHeightForCurrentRoot = block.number;
    }
}
