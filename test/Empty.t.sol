// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test, stdJson } from "forge-std/Test.sol";
import {BananaMerkle} from "../src/BananaMerkle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmptyTest_Unit is Test {
    using stdJson for string;
    event Claimed(address indexed claimer, uint256 amount);

    BananaMerkle bananaMerkle;

// values from https://github.com/Anish-Agnihotri/merkle-airdrop-starter/blob/master/contracts/src/test/utils/MerkleClaimERC20Test.sol
    bytes32 root = 0x374a314108b4a389873020c193eb0d62b176621994066d9807a58bea989eadd1; // 100e18 tokens for 
    bytes32 proof = 0xfd665914581601e397da362d118f4ea98e57f511560e08a29855cfbb4c663f70;
    address claimer = 0x185a4dc360CE69bDCceE33b3784B0282f7961aea;
    address token = 0x3abF2A4f8452cCC2CF7b4C1e4663147600646f66; // just teporary

    // Types need to follow the alphabetical order of the json keys!
    struct ProofToTest {
        address _address;
        bytes32 _leaf;
        bytes32 _proof;
        uint256 _value;
    }

    struct Tmp {
        bytes32 _address;
        bytes32 _leaf;
        bytes32 _proof;
        bytes32 _value;
    }

    function setUp() public {
        bananaMerkle = new BananaMerkle(IERC20(token));
        bananaMerkle.updateRoot(root);

        string memory json = vm.readFile('./test/proofs.json');
        emit log_string(json);

        bytes memory _proofs = vm.parseJson(json);

        ProofToTest[] memory proofs = abi.decode(_proofs, (ProofToTest[]));

        emit log_address(proofs[0]._address);
        emit log_bytes32(proofs[0]._leaf);
        emit log_bytes32(proofs[0]._proof);
        emit log_uint(proofs[0]._value);
        
    }

    function test_claimerCanClaimOnce() public {
        bytes32[] memory _proof = new bytes32[](1);
        _proof[0] = proof;

        vm.prank(claimer);
        bananaMerkle.claim(100e18, _proof);

        vm.prank(claimer);
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_AlreadyClaimed.selector));
        bananaMerkle.claim(100e18, _proof);
    }

    function test_nonClaimerCannotClaim() public {
        bytes32[] memory _proof = new bytes32[](1);
        _proof[0] = proof;

        vm.prank(address(123));
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
        bananaMerkle.claim(100e18, _proof);
    }
}
