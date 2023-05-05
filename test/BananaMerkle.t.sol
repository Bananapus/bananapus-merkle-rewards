// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test, stdJson } from "forge-std/Test.sol";
import {BananaMerkle} from "../src/BananaMerkle.sol";
import "../src/mock/MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BananaMerkle_Unit is Test {
    using stdJson for string;
    event Claimed(address indexed claimer, uint256 amount);

    BananaMerkle bananaMerkle;

    ProofToTest[] proofs;
    ProofToTest[] newProofs;


    bytes32 root = 0x694fd08b0fd824ced0ca9e4617ed454c87d180c0347038663a040660c8b99a3b;
    bytes32 newRoot = 0x2393d9932c6be016ec3e28496db5cc6b55e475e28f5b3e49d03701f68d201f45;
    MockERC20 token;

    // Types need to follow the alphabetical order of the json keys!
    struct ProofToTest {
        address _claimer;
        bytes32 _leaf;
        bytes32[] _proof;
        uint256 _value;
    }

    function setUp() public {
        token = new MockERC20(100_000 ether);
        bananaMerkle = new BananaMerkle(IERC20(token));
        bananaMerkle.updateRoot(root);
        token.transfer(address(bananaMerkle), 50_000 ether);

        string memory json = vm.readFile('./test/proofs.json');
        emit log_string(json);

        bytes memory _proofs = vm.parseJson(json);
        ProofToTest[] memory proofsMem = abi.decode(_proofs, (ProofToTest[]));
        for (uint8 i = 0; i < proofsMem.length; i++) {
            proofs.push(proofsMem[i]);
        }

        json = vm.readFile('./test/new_proofs.json');
        _proofs = vm.parseJson(json);
        proofsMem = abi.decode(_proofs, (ProofToTest[]));
        for (uint8 i = 0; i < proofsMem.length; i++) {
            newProofs.push(proofsMem[i]);
        }
    }

    function test_claimerCanClaimOnce() public {
        for (uint8 i = 0; i < proofs.length; i++) {
          bytes32[] memory _proof = new bytes32[](proofs[i]._proof.length);
          for (uint8 j = 0; j < _proof.length; j++) {
            _proof[j] = proofs[i]._proof[j];
          }  
          uint256 _tokenBalanceBeforeClaim = token.balanceOf(proofs[i]._claimer);

          vm.prank(proofs[i]._claimer);
          bananaMerkle.claim(proofs[i]._value, _proof);

          uint256 _tokenBalanceAfterClaim = token.balanceOf(proofs[i]._claimer);
          uint256 _diff = _tokenBalanceAfterClaim - _tokenBalanceBeforeClaim;
          assertEq(_diff, proofs[i]._value);

          vm.prank(proofs[i]._claimer);
          vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_AlreadyClaimed.selector));
          bananaMerkle.claim(proofs[i]._value, _proof);
        }
    }

    function test_nonClaimerCannotClaim() public {
        for (uint8 i = 0; i < proofs.length; i++) {
          bytes32[] memory _proof = new bytes32[](proofs[i]._proof.length);
          for (uint8 j = 0; j < _proof.length; j++) {
            _proof[j] = proofs[i]._proof[j];
          }  

          vm.prank(address(123));
          vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
          bananaMerkle.claim(proofs[i]._value, _proof);
        }
    }


    function test_ClaimerCannotClaimWithInvalidProof() public {
        for (uint8 i = 0; i < proofs.length; i++) {
          bytes32[] memory _proof = new bytes32[](proofs[i]._proof.length);
          for (uint8 j = 0; j < _proof.length; j++) {
            _proof[j] = proofs[i]._proof[j];
          }  
          _proof[0] = 0x1bd6c175061e5be1e78cf49fcc6d5f1b89225cbfcf568f38f60c52ef141ad44e;

          vm.prank(proofs[i]._claimer);
          vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
          bananaMerkle.claim(proofs[i]._value, _proof);
        }
    }


    function test_claimerCanClaimOnce_when_root_is_updated() public {
        for (uint8 i = 0; i < proofs.length; i++) {
          bytes32[] memory _proof = new bytes32[](proofs[i]._proof.length);
          for (uint8 j = 0; j < _proof.length; j++) {
            _proof[j] = proofs[i]._proof[j];
          }  
          uint256 _tokenBalanceBeforeClaim = token.balanceOf(proofs[i]._claimer);

          vm.prank(proofs[i]._claimer);
          bananaMerkle.claim(proofs[i]._value, _proof);

          uint256 _tokenBalanceAfterClaim = token.balanceOf(proofs[i]._claimer);
          uint256 _diff = _tokenBalanceAfterClaim - _tokenBalanceBeforeClaim;
          assertEq(_diff, proofs[i]._value);

          vm.prank(proofs[i]._claimer);
          vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_AlreadyClaimed.selector));
          bananaMerkle.claim(proofs[i]._value, _proof);
        }

        vm.roll(block.number + 1);
        bananaMerkle.updateRoot(newRoot);

        for (uint8 i = 0; i < newProofs.length; i++) {
          bytes32[] memory _proof = new bytes32[](newProofs[i]._proof.length);
          for (uint8 j = 0; j < _proof.length; j++) {
            _proof[j] = newProofs[i]._proof[j];
          }  
          uint256 _tokenBalanceBeforeClaim = token.balanceOf(newProofs[i]._claimer);

          vm.prank(newProofs[i]._claimer);
          bananaMerkle.claim(newProofs[i]._value, _proof);

          uint256 _tokenBalanceAfterClaim = token.balanceOf(newProofs[i]._claimer);
          uint256 _diff = _tokenBalanceAfterClaim - _tokenBalanceBeforeClaim;
          assertEq(_diff, newProofs[i]._value);

          vm.prank(newProofs[i]._claimer);
          vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_AlreadyClaimed.selector));
          bananaMerkle.claim(newProofs[i]._value, _proof);
        }
    }

    function test_nonClaimerCannotClaim_when_root_is_updated() public {
        vm.roll(block.number + 1);
        bananaMerkle.updateRoot(newRoot);

        for (uint8 i = 0; i < newProofs.length; i++) {
          bytes32[] memory _proof = new bytes32[](newProofs[i]._proof.length);
          for (uint8 j = 0; j < _proof.length; j++) {
            _proof[j] = newProofs[i]._proof[j];
          }  

          vm.prank(address(123));
          vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
          bananaMerkle.claim(newProofs[i]._value, _proof);
        }
    }

    function test_ClaimerCannotClaimWithInvalidProof_when_root_is_updated() public {
        vm.roll(block.number + 1);
        bananaMerkle.updateRoot(newRoot);

        for (uint8 i = 0; i < newProofs.length; i++) {
          bytes32[] memory _proof = new bytes32[](newProofs[i]._proof.length);
          for (uint8 j = 0; j < _proof.length; j++) {
            _proof[j] = newProofs[i]._proof[j];
          }  
          _proof[0] = 0x1bd6c175061e5be1e78cf49fcc6d5f1b89225cbfcf568f38f60c52ef141ad44e;

          vm.prank(newProofs[i]._claimer);
          vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
          bananaMerkle.claim(newProofs[i]._value, _proof);
        }
    }
}
