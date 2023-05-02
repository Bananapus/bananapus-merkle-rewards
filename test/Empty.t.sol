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

    bytes32 root = 0xa178a1ba718a2a1ade417f90e7ca571a7fff4707a3639b4932bdddc73659f1ff; // 4761904761904761904 tokens for 
    bytes32[] proof = [
      bytes32(0x5aec4f2d7e5259a3b6f3d63f1d8c4250d66ba45666f356e403b116f56032a392),
      bytes32(0x033a2a3dc993fe3b6b3cc3b6732daab111a77d48f5ad78d492110a4c807c2081),
      bytes32(0x1bd6c175061e5be1e78cf49fcc6d5f1b89225cbfcf568f38f60c52ef141ad42e)
    ];
    address claimer = 0x5427B5141A6CC8228A9E74248F51210380adbaE9;
    MockERC20 token;
    uint256 claimAmount = 4761904761904761904;

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

        // bytes memory _proofs = vm.parseJson(json);
        // ProofToTest[] memory proofs = abi.decode(_proofs, (ProofToTest[]));

        // emit log_address(proofs[0]._address);
        // emit log_bytes32(proofs[0]._leaf);
        // emit log_bytes32(proofs[0]._proof);
        // emit log_uint(proofs[0]._value);
    }

    function test_claimerCanClaimOnce() public {
        bytes32[] memory _proof = new bytes32[](3);
        for (uint8 i = 0; i < proof.length; i++) {
            _proof[i] = proof[i];
        }

        vm.prank(claimer);
        bananaMerkle.claim(claimAmount, _proof);

        vm.prank(claimer);
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_AlreadyClaimed.selector));
        bananaMerkle.claim(claimAmount, _proof);
    }

    function test_nonClaimerCannotClaim() public {
        bytes32[] memory _proof = new bytes32[](3);
        for (uint8 i = 0; i < proof.length; i++) {
            _proof[i] = proof[i];
        }

        vm.prank(address(123));
        vm.expectRevert(abi.encodeWithSelector(BananaMerkle.BananaMerkle_NothingToClaim.selector));
        bananaMerkle.claim(claimAmount, _proof);
    }
}
