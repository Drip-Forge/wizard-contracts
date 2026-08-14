// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDrips
 * @notice Read-only subset of the Drips protocol contract.
 */
interface IDrips {
    /// @notice Returns the hash of the current splits configuration for `accountId`.
    function splitsHash(uint256 accountId) external view returns (bytes32);
}
