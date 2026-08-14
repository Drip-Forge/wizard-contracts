// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FundingParser.sol";
import "../src/interfaces/IDripsHub.sol";

// Mock DripsHub implementation for testing
contract MockDripsHub is IDripsHub {
    mapping(uint256 => bytes32) public splitsHashes;

    function setSplits(SplitsReceiver[] calldata receivers) external override returns (bytes32 splitsHash) {
        // Create a simple pseudo-hash based on the length of receivers and first element for mock purposes
        if (receivers.length > 0) {
            splitsHash = keccak256(abi.encodePacked(receivers.length, receivers[0].userId, receivers[0].weight));
        } else {
            splitsHash = keccak256(abi.encodePacked("empty"));
        }
        // Let's use a dummy user ID for testing
        splitsHashes[12345] = splitsHash;
        return splitsHash;
    }

    function getSplitsHash(uint256 userId) external view override returns (bytes32 splitsHash) {
        return splitsHashes[userId];
    }
}

// Concrete Mock implementation of the abstract FundingParser
contract MockFundingParser is FundingParser {
    constructor(address _dripsHub) FundingParser(_dripsHub) {}

    // Simulated parse function
    function parseFunding(string calldata metadataHash) 
        external 
        override 
        returns (IDripsHub.SplitsReceiver[] memory receivers) 
    {
        // For testing purposes: mock-parse the metadataHash.
        // We will return 2 receivers with some weights based on string comparison
        receivers = new IDripsHub.SplitsReceiver[](2);
        
        if (keccak256(abi.encodePacked(metadataHash)) == keccak256(abi.encodePacked("ipfs://valid-package-json"))) {
            receivers[0] = IDripsHub.SplitsReceiver({ userId: 1001, weight: 600000 }); // 60%
            receivers[1] = IDripsHub.SplitsReceiver({ userId: 1002, weight: 400000 }); // 40%
        } else {
            receivers[0] = IDripsHub.SplitsReceiver({ userId: 9999, weight: 1000000 }); // 100%
            // shrink array to 1
            assembly {
                mstore(receivers, 1)
            }
        }
        
        emit FundingParsed(metadataHash, 1000000);
        
        // Update the splits on DripsHub for mock project user ID 12345
        _updateSplits(12345, receivers);
        
        return receivers;
    }
}

contract FundingParserTest is Test {
    MockDripsHub public dripsHub;
    MockFundingParser public parser;

    event FundingParsed(string indexed ipfsHash, uint256 totalWeight);
    event SplitsUpdated(uint256 indexed receiverUserId, bytes32 splitsHash);

    function setUp() public {
        dripsHub = new MockDripsHub();
        parser = new MockFundingParser(address(dripsHub));
    }

    function testConstructor() public view {
        assertEq(address(parser.dripsHub()), address(dripsHub));
        assertEq(parser.owner(), address(this));
    }

    function testParseFundingValid() public {
        vm.expectEmit(true, true, true, true);
        emit FundingParsed("ipfs://valid-package-json", 1000000);
        
        IDripsHub.SplitsReceiver[] memory receivers = parser.parseFunding("ipfs://valid-package-json");
        
        assertEq(receivers.length, 2);
        assertEq(receivers[0].userId, 1001);
        assertEq(receivers[0].weight, 600000);
        assertEq(receivers[1].userId, 1002);
        assertEq(receivers[1].weight, 400000);
        
        bytes32 expectedHash = keccak256(abi.encodePacked(uint256(2), uint256(1001), uint32(600000)));
        assertEq(dripsHub.getSplitsHash(12345), expectedHash);
    }

    function testParseFundingDefault() public {
        IDripsHub.SplitsReceiver[] memory receivers = parser.parseFunding("ipfs://other-metadata");
        
        assertEq(receivers.length, 1);
        assertEq(receivers[0].userId, 9999);
        assertEq(receivers[0].weight, 1000000);
    }
}
