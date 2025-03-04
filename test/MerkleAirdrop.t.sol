// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";
import { BFTToken } from "../src/BFTToken.sol";
import { ZkSyncChainChecker } from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import { DeployMerkleAirdrop } from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop public merkleAirdrop;
    BFTToken public token;

    address user;
    uint256 userPrivateKey;

    address gasPayer;

    bytes32 public ROOT = 0x51326eca4720e5a2669b827c49e333e0e586a60bfc91e33ec94872a4e0289a56;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

    bytes32 proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proof2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proof1, proof2];

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (merkleAirdrop, token) = deployer.run();
        } else {
            token = new BFTToken();
            merkleAirdrop = new MerkleAirdrop(ROOT, token);
            token.mint(token.owner(), AMOUNT_TO_SEND);
            token.transfer(address(merkleAirdrop), AMOUNT_TO_SEND);
        }
        (user, userPrivateKey) = makeAddrAndKey("Jacob");
        gasPayer = makeAddr("Jenny");
    }

    function signMessage(uint256 privKey, address account) public view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = merkleAirdrop.getMessageHash(account, AMOUNT_TO_CLAIM);
        (v, r, s) = vm.sign(privKey, hashedMessage);
    }

    function testUsersCanClaim() public {
        uint256 startingBal = token.balanceOf(user);
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);
        vm.stopPrank();

        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        uint256 endingBal = token.balanceOf(user);
        assertEq(endingBal - startingBal, AMOUNT_TO_CLAIM);
    }

    function testCannotClaimTwice() public {
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);
        vm.stopPrank();

        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }

    function testCannotClaimWithInvalidSignature() public {
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);
        vm.stopPrank();

        bytes32 invalidR = bytes32(uint256(r) + 1);

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, invalidR, s);
    }

    function testMerkleRootIsCorrect() public view {
        assertEq(merkleAirdrop.getMerkleRoot(), ROOT);
    }

    function testCannotClaimForAnotherUser() public {
        address anotherUser = makeAddr("AnotherUser");

        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);
        vm.stopPrank();

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        vm.prank(gasPayer);
        merkleAirdrop.claim(anotherUser, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }

    function testClaimEventEmitted() public {
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);
        vm.stopPrank();

        vm.prank(gasPayer);
        vm.expectEmit(true, true, false, true);
        emit MerkleAirdrop.Claimed(user, AMOUNT_TO_CLAIM);

        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }

    function testCannotClaimZeroAmount() public {
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);
        vm.stopPrank();

        vm.expectRevert();
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, 0, PROOF, v, r, s);
    }

    function testAirdropContractHasSufficientTokens() public view {
        uint256 contractBalance = token.balanceOf(address(merkleAirdrop));
        assert(contractBalance >= AMOUNT_TO_CLAIM);
    }

    function testCannotClaimWithAnotherUsersSignature() public {
        address anotherUser = makeAddr("AnotherUser");
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, anotherUser);

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
    }

    function testMerkleRootAndTokenAreCorrect() public view {
        assertEq(merkleAirdrop.getMerkleRoot(), ROOT);
        assertEq(address(merkleAirdrop.getAirdropToken()), address(token));
    }
}
