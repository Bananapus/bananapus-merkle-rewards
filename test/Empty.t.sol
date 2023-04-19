// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test, stdJson } from "forge-std/Test.sol";
import {BananaMerkle} from "../src/BananaMerkle.sol";

contract EmptyTest_Unit is Test {
    using stdJson for string;
    event Claimed(address indexed claimer, uint256 amount);

    BananaMerkle bananaMerkle;

// values from https://github.com/Anish-Agnihotri/merkle-airdrop-starter/blob/master/contracts/src/test/utils/MerkleClaimERC20Test.sol
    bytes32 root = 0xd0aa6a4e5b4e13462921d7518eebdb7b297a7877d6cfe078b0c318827392fb55; // 100e18 tokens for 
    bytes32 proof = 0xceeae64152a2deaf8c661fccd5645458ba20261b16d2f6e090fe908b0ac9ca88;
    address claimer = 0x185a4dc360CE69bDCceE33b3784B0282f7961aea;

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
        bananaMerkle = new BananaMerkle();
        bananaMerkle.updateRoot(root);

        string memory json = vm.readFile('./test/proofs.json');

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
