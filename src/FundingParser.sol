// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAddressDriver} from "./interfaces/IAddressDriver.sol";
import {SplitsLib} from "./libraries/SplitsLib.sol";

/**
 * @title FundingParser
 * @notice Abstract adapter that turns off-chain funding metadata into a Drips splits configuration.
 * @dev Calling `setSplits` through this contract configures the *contract's* AddressDriver account.
 *      That is the intended pattern for a protocol treasury or splitter contract.
 *      GitHub repositories claimed via FUNDING.json are instead managed by the Drips RepoDriver
 *      in the Drips app — see docs/integration.md.
 */
abstract contract FundingParser is Ownable {
    IAddressDriver public immutable addressDriver;

    event FundingParsed(bytes32 indexed sourceHash, uint32 totalWeight);
    event SplitsUpdated(bytes32 splitsHash, uint32 totalWeight);

    error InvalidAddressDriver();

    constructor(address addressDriver_) Ownable(msg.sender) {
        if (addressDriver_ == address(0)) revert InvalidAddressDriver();
        addressDriver = IAddressDriver(addressDriver_);
    }

    /**
     * @notice Parse a content hash (IPFS CID, git SHA, or keccak of package.json) into receivers.
     * @dev Implementations may fetch metadata off-chain (via an oracle) or simply document that
     *      callers should use `applySplits` with receivers produced by wizard-api.
     */
    function parseFunding(string calldata metadataHash)
        external
        virtual
        returns (IAddressDriver.SplitsReceiver[] memory receivers);

    /**
     * @notice Validate `receivers` against Drips rules and write them to AddressDriver.
     * @dev Splits are applied to this contract's AddressDriver account (`msg.sender` inside the driver).
     */
    function applySplits(IAddressDriver.SplitsReceiver[] calldata receivers)
        public
        onlyOwner
        returns (bytes32 splitsHash)
    {
        return _applySplits(receivers);
    }

    function _applySplits(IAddressDriver.SplitsReceiver[] memory receivers) internal returns (bytes32 splitsHash) {
        uint32 totalWeight = SplitsLib.validate(receivers);
        addressDriver.setSplits(receivers);
        splitsHash = SplitsLib.hashReceivers(receivers);
        emit SplitsUpdated(splitsHash, totalWeight);
    }
}
