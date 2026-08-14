// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAddressDriver} from "../interfaces/IAddressDriver.sol";

/**
 * @title SplitsLib
 * @notice Pure validation for Drips splits receivers lists.
 * @dev Rules match the Drips protocol: sorted unique account IDs, non-zero weights,
 *      at most 200 receivers, total weight at most 1_000_000.
 */
library SplitsLib {
    uint32 public constant TOTAL_SPLITS_WEIGHT = 1_000_000;
    uint256 public constant MAX_SPLITS_RECEIVERS = 200;

    error TooManyReceivers(uint256 count);
    error ZeroWeight(uint256 accountId);
    error ReceiversNotSorted(uint256 previousId, uint256 accountId);
    error WeightsSumTooHigh(uint256 totalWeight);

    function validate(IAddressDriver.SplitsReceiver[] memory receivers) internal pure returns (uint32 totalWeight) {
        uint256 length = receivers.length;
        if (length > MAX_SPLITS_RECEIVERS) {
            revert TooManyReceivers(length);
        }

        uint256 previousId;
        uint256 runningWeight;
        for (uint256 i; i < length; ++i) {
            IAddressDriver.SplitsReceiver memory receiver = receivers[i];
            if (receiver.weight == 0) {
                revert ZeroWeight(receiver.accountId);
            }
            if (i > 0 && receiver.accountId <= previousId) {
                revert ReceiversNotSorted(previousId, receiver.accountId);
            }
            previousId = receiver.accountId;
            runningWeight += receiver.weight;
        }

        if (runningWeight > TOTAL_SPLITS_WEIGHT) {
            revert WeightsSumTooHigh(runningWeight);
        }
        totalWeight = uint32(runningWeight);
    }

    function hashReceivers(IAddressDriver.SplitsReceiver[] memory receivers) internal pure returns (bytes32) {
        return keccak256(abi.encode(receivers));
    }
}
