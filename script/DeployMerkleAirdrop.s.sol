// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MerkleAirdrop, IERC20 } from "../src/MerkleAirdrop.sol";
import { Script } from "forge-std/Script.sol";
import { BFTToken } from "../src/BFTToken.sol";
import { console } from "forge-std/console.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public ROOT = 0x51326eca4720e5a2669b827c49e333e0e586a60bfc91e33ec94872a4e0289a56;
    uint256 public AMOUNT_TO_TRANSFER = 4 * (25 * 1e18);

    function deployMerkleAirdrop() public returns (MerkleAirdrop, BFTToken) {
        vm.startBroadcast();
        BFTToken bftToken = new BFTToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(ROOT, IERC20(bftToken));
        bftToken.mint(bftToken.owner(), AMOUNT_TO_TRANSFER);
        IERC20(bftToken).transfer(address(airdrop), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
        return (airdrop, bftToken);
    }

    function run() external returns (MerkleAirdrop, BFTToken) {
        return deployMerkleAirdrop();
    }
}