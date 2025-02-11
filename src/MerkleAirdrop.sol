// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Merkle Airdrop
 * @author Jitendra Kumar
 * @dev A contract for managing token airdrops using a Merkle tree. Users can claim tokens by providing a valid proof
 * and signature.
 */
contract MerkleAirdrop is EIP712 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    /// @notice Thrown when the provided Merkle proof is invalid.
    error MerkleAirdrop__InvalidProof();

    /// @notice Thrown when a user tries to claim tokens they have already claimed.
    error MerkleAirdrop__AlreadyClaimed();

    /// @notice Thrown when the signature provided for a claim is invalid.
    error MerkleAirdrop__InvalidSignature();

    /// @notice Token to be distributed in the airdrop.
    IERC20 private immutable i_airdropToken;

    /// @notice Root of the Merkle tree representing eligible airdrop claims.
    bytes32 private immutable i_merkleRoot;

    /// @notice Tracks addresses that have already claimed their tokens.
    mapping(address => bool) private s_hasClaimed;

    /// @notice EIP-712 type hash for airdrop claims.
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    /// @notice Structure to represent an airdrop claim.
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /// @notice Emitted when a user successfully claims their tokens.
    /// @param account The address of the user who claimed tokens.
    /// @param amount The amount of tokens claimed.
    event Claimed(address account, uint256 amount);

    /// @notice Emitted when the Merkle root is updated.
    /// @param newMerkleRoot The new Merkle root.
    event MerkleRootUpdated(bytes32 newMerkleRoot);

    /**
     * @dev Initializes the contract with a Merkle root and the airdrop token.
     * @param merkleRoot The Merkle root of the eligible claims.
     * @param airdropToken The ERC20 token to be distributed.
     */
    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("Merkle Airdrop", "1.0.0") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /**
     * @notice Allows eligible users to claim their airdrop tokens.
     * @param account The address of the user making the claim.
     * @param amount The amount of tokens to be claimed.
     * @param merkleProof The Merkle proof validating the user's eligibility.
     * @param v The recovery id of the signature.
     * @param r The r value of the signature.
     * @param s The s value of the signature.
     */
    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        s_hasClaimed[account] = true;
        emit Claimed(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    /**
     * @notice Computes the EIP-712 message hash for a claim.
     * @param account The address of the claimant.
     * @param amount The amount of tokens being claimed.
     * @return The EIP-712 typed data hash for the claim.
     */
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({ account: account, amount: amount })))
        );
    }

    /**
     * @notice Returns the Merkle root used in the contract.
     * @return The Merkle root of the eligible claims.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    /**
     * @notice Returns the token being distributed in the airdrop.
     * @return The ERC20 token contract address.
     */
    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    /**
     * @dev Validates the signature for a claim.
     * @param signer The expected signer of the message.
     * @param digest The message hash.
     * @param _v The recovery id of the signature.
     * @param _r The r value of the signature.
     * @param _s The s value of the signature.
     * @return True if the signature is valid, false otherwise.
     */
    function _isValidSignature(
        address signer,
        bytes32 digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
        pure
        returns (bool)
    {
        (
            address actualSigner,
            /*ECDSA.RecoverError recoverError*/
            ,
            /*bytes32 signatureLength*/
        ) = ECDSA.tryRecover(digest, _v, _r, _s);
        return (actualSigner == signer);
    }
}
