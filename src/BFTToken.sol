// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BFTToken
 * @author Jitendra Kumar
 * @dev An ERC20 token implementation for BFT with minting functionality restricted to the contract owner.
 */
contract BFTToken is ERC20, Ownable {
    /**
     * @notice Deploy the BFTToken contract.
     * @dev Sets the token name to "BFT" and symbol to "BFT". Assigns the deployer as the owner.
     */
    constructor() ERC20("BFT", "BFT") Ownable(msg.sender) { }

    /**
     * @notice Mint new tokens.
     * @dev Allows only the contract owner to mint tokens to a specified account.
     * @param account The address to receive the minted tokens.
     * @param amount The amount of tokens to mint.
     *
     * Requirements:
     * - The caller must be the owner.
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
