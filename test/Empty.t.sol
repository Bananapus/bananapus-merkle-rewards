// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test, stdJson } from "forge-std/Test.sol";
import {BananaMerkle} from "../src/BananaMerkle.sol";
import "../src/mock/MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmptyTest_Unit is Test {
    using stdJson for string;
    event Claimed(address indexed claimer, uint256 amount);

    BananaMerkle bananaMerkle;

    bytes32 root = 0xa178a1ba718a2a1ade417f90e7ca571a7fff4707a3639b4932bdddc73659f1ff; 
    bytes32 proof = 0x92c2d04bc90e18ae21acc135a7bc01e36e33ebc5b931163ecd81fd4508fa01f9;
    address claimer = 0x30670D81E487c80b9EDc54370e6EaF943B6EAB39;
    MockERC20 token;
    uint256 claimAmount = 9523809523809523809;

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
        token = new MockERC20(100_000 ether);
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
        bananaMerkle.claim(claimAmount, _proof);

        vm.prank(claimer);
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_AlreadyClaimed.selector));
        bananaMerkle.claim(claimAmount, _proof);
    }

    function test_nonClaimerCannotClaim() public {
        bytes32[] memory _proof = new bytes32[](1);
        _proof[0] = proof;

        vm.prank(address(123));
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
        bananaMerkle.claim(claimAmount, _proof);
    }
}
