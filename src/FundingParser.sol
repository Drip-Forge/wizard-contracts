// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDripsHub.sol";

/**
 * @title FundingParser
 * @notice Abstract base contract for parsing project dependency/funding configurations and translating them into Drips configurations.
 */
abstract contract FundingParser is Ownable {
    
    // Reference to the DripsHub contract
    IDripsHub public immutable dripsHub;
    
    event FundingParsed(string indexed ipfsHash, uint256 totalWeight);
    event SplitsUpdated(uint256 indexed receiverUserId, bytes32 splitsHash);

    constructor(address _dripsHub) Ownable(msg.sender) {
        require(_dripsHub != address(0), "Invalid DripsHub address");
        dripsHub = IDripsHub(_dripsHub);
    }

    /**
     * @notice Parses dependency funding configuration metadata.
     * @dev Must be implemented by inheriting contracts to parse specific formats (e.g. package.json, Cargo.toml).
     * @param metadataHash The IPFS or content hash containing the configuration.
     * @return receivers Array of splits receiver configurations to be sent to DripsHub.
     */
    function parseFunding(string calldata metadataHash) 
        external 
        virtual 
        returns (IDripsHub.SplitsReceiver[] memory receivers);
        
    /**
     * @notice Updates the Drips splits configuration for a project user.
     * @param receiverUserId The Drips account ID to update.
     * @param receivers The split receivers configuration.
     */
    function _updateSplits(uint256 receiverUserId, IDripsHub.SplitsReceiver[] memory receivers) internal {
        // Core implementation to write/register splits to DripsHub
        bytes32 hash = dripsHub.setSplits(receivers);
        emit SplitsUpdated(receiverUserId, hash);
    }
}
