// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FundingParser} from "./FundingParser.sol";
import {IAddressDriver} from "./interfaces/IAddressDriver.sol";
import {SplitsLib} from "./libraries/SplitsLib.sol";

/**
 * @title DependencySplits
 * @notice Concrete FundingParser for Node projects analyzed by wizard-api.
 * @dev wizard-api cannot see Drips account IDs. The UI / integrator maps each dependency
 *      (and the project owner) to a Drips account ID, then submits the sorted receiver list here
 *      together with a hash of the source package.json for an on-chain audit trail.
 */
contract DependencySplits is FundingParser {
    bytes32 public lastSourceHash;

    error UseApplyAnalyzedSplits();

    constructor(address addressDriver_) FundingParser(addressDriver_) {}

    /// @inheritdoc FundingParser
    function parseFunding(string calldata)
        external
        pure
        override
        returns (IAddressDriver.SplitsReceiver[] memory)
    {
        revert UseApplyAnalyzedSplits();
    }

    /**
     * @notice Apply a wizard-api splits proposal after account IDs have been resolved off-chain.
     * @param sourceHash keccak256 of the canonical package.json (or IPFS CID hashed to bytes32).
     * @param receivers Sorted Drips splits receivers. Weights must sum to at most 1_000_000.
     */
    function applyAnalyzedSplits(bytes32 sourceHash, IAddressDriver.SplitsReceiver[] calldata receivers)
        external
        onlyOwner
        returns (bytes32 splitsHash)
    {
        uint32 totalWeight = SplitsLib.validate(receivers);
        lastSourceHash = sourceHash;
        emit FundingParsed(sourceHash, totalWeight);
        splitsHash = _applySplits(receivers);
    }
}
