// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDripsHub
 * @notice Interface for interacting with the DripsHub contract which manages splits and streams.
 */
interface IDripsHub {
    struct SplitsReceiver {
        uint256 userId;
        uint32 weight;
    }

    /**
     * @notice Set the splits configuration for the msg.sender's user ID.
     * @param receivers The list of receivers and their weights.
     * @return splitsHash The hash of the configured splits.
     */
    function setSplits(SplitsReceiver[] calldata receivers) external returns (bytes32 splitsHash);

    /**
     * @notice Get the splits hash for a specific user ID.
     * @param userId The user ID to query.
     * @return splitsHash The current splits hash.
     */
    function getSplitsHash(uint256 userId) external view returns (bytes32 splitsHash);
}
