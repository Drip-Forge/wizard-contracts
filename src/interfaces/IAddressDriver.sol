// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAddressDriver
 * @notice Subset of the Drips AddressDriver used by Wizard contracts.
 * @dev Production deployments should point at the canonical AddressDriver for the target chain.
 *      See https://docs.drips.network/the-protocol/overview/
 */
interface IAddressDriver {
    struct SplitsReceiver {
        uint256 accountId;
        uint32 weight;
    }

    /// @notice Sets splits for the caller's AddressDriver account.
    function setSplits(SplitsReceiver[] calldata receivers) external;

    /// @notice Derives the AddressDriver account ID for `addr`.
    function calcAccountId(address addr) external view returns (uint256 accountId);
}
