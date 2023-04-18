// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import {BananaMerkle} from "../src/BananaMerkle.sol";

contract EmptyTest_Unit is Test {
    event Claimed(address indexed claimer, uint256 amount);

    BananaMerkle bananaMerkle;

// values from https://github.com/Anish-Agnihotri/merkle-airdrop-starter/blob/master/contracts/src/test/utils/MerkleClaimERC20Test.sol
    bytes32 root = 0xd0aa6a4e5b4e13462921d7518eebdb7b297a7877d6cfe078b0c318827392fb55; // 100e18 tokens for 
    bytes32 proof = 0xceeae64152a2deaf8c661fccd5645458ba20261b16d2f6e090fe908b0ac9ca88;
    address claimer = 0x185a4dc360CE69bDCceE33b3784B0282f7961aea;

    function setUp() public {
        bananaMerkle = new BananaMerkle();
        bananaMerkle.updateRoot(root);
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
