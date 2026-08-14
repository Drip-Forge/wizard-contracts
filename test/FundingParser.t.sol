// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IAddressDriver} from "../src/interfaces/IAddressDriver.sol";
import {SplitsLib} from "../src/libraries/SplitsLib.sol";
import {FundingParser} from "../src/FundingParser.sol";
import {DependencySplits} from "../src/DependencySplits.sol";

contract MockAddressDriver is IAddressDriver {
    mapping(uint256 => bytes32) public hashes;
    uint32 public constant DRIVER_ID = 0;

    function calcAccountId(address addr) public pure returns (uint256 accountId) {
        accountId = (uint256(DRIVER_ID) << 224) | uint160(addr);
    }

    function setSplits(SplitsReceiver[] calldata receivers) external {
        hashes[calcAccountId(msg.sender)] = keccak256(abi.encode(receivers));
    }
}

contract MockFundingParser is FundingParser {
    constructor(address addressDriver_) FundingParser(addressDriver_) {}

    function parseFunding(string calldata metadataHash)
        external
        override
        returns (IAddressDriver.SplitsReceiver[] memory receivers)
    {
        receivers = new IAddressDriver.SplitsReceiver[](2);
        if (keccak256(bytes(metadataHash)) == keccak256(bytes("ipfs://valid-package-json"))) {
            receivers[0] = IAddressDriver.SplitsReceiver({accountId: 1001, weight: 600_000});
            receivers[1] = IAddressDriver.SplitsReceiver({accountId: 1002, weight: 400_000});
        } else {
            receivers = new IAddressDriver.SplitsReceiver[](1);
            receivers[0] = IAddressDriver.SplitsReceiver({accountId: 9999, weight: 1_000_000});
        }

        bytes32 sourceHash = keccak256(bytes(metadataHash));
        emit FundingParsed(sourceHash, SplitsLib.validate(receivers));
        _applySplits(receivers);
    }
}

contract SplitsLibTest is Test {
    using SplitsLib for IAddressDriver.SplitsReceiver[];

    function _one(uint256 id, uint32 weight) internal pure returns (IAddressDriver.SplitsReceiver[] memory receivers) {
        receivers = new IAddressDriver.SplitsReceiver[](1);
        receivers[0] = IAddressDriver.SplitsReceiver({accountId: id, weight: weight});
    }

    function testEmptyIsValid() public pure {
        IAddressDriver.SplitsReceiver[] memory receivers = new IAddressDriver.SplitsReceiver[](0);
        assertEq(SplitsLib.validate(receivers), 0);
    }

    function testValidPair() public pure {
        IAddressDriver.SplitsReceiver[] memory receivers = new IAddressDriver.SplitsReceiver[](2);
        receivers[0] = IAddressDriver.SplitsReceiver({accountId: 1, weight: 250_000});
        receivers[1] = IAddressDriver.SplitsReceiver({accountId: 2, weight: 750_000});
        assertEq(SplitsLib.validate(receivers), 1_000_000);
    }

    function testRevertZeroWeight() public {
        vm.expectRevert(abi.encodeWithSelector(SplitsLib.ZeroWeight.selector, 7));
        this.externalValidate(_one(7, 0));
    }

    function testRevertUnsorted() public {
        IAddressDriver.SplitsReceiver[] memory receivers = new IAddressDriver.SplitsReceiver[](2);
        receivers[0] = IAddressDriver.SplitsReceiver({accountId: 9, weight: 1});
        receivers[1] = IAddressDriver.SplitsReceiver({accountId: 3, weight: 1});
        vm.expectRevert(abi.encodeWithSelector(SplitsLib.ReceiversNotSorted.selector, uint256(9), uint256(3)));
        this.externalValidate(receivers);
    }

    function testRevertDuplicate() public {
        IAddressDriver.SplitsReceiver[] memory receivers = new IAddressDriver.SplitsReceiver[](2);
        receivers[0] = IAddressDriver.SplitsReceiver({accountId: 4, weight: 1});
        receivers[1] = IAddressDriver.SplitsReceiver({accountId: 4, weight: 1});
        vm.expectRevert(abi.encodeWithSelector(SplitsLib.ReceiversNotSorted.selector, uint256(4), uint256(4)));
        this.externalValidate(receivers);
    }

    function testRevertWeightsTooHigh() public {
        vm.expectRevert(abi.encodeWithSelector(SplitsLib.WeightsSumTooHigh.selector, uint256(1_000_001)));
        this.externalValidate(_one(1, 1_000_001));
    }

    function externalValidate(IAddressDriver.SplitsReceiver[] calldata receivers) external pure returns (uint32) {
        return SplitsLib.validate(receivers);
    }
}

contract FundingParserTest is Test {
    MockAddressDriver internal dripsHub;
    MockFundingParser internal parser;
    DependencySplits internal dependencySplits;

    event FundingParsed(bytes32 indexed sourceHash, uint32 totalWeight);
    event SplitsUpdated(bytes32 splitsHash, uint32 totalWeight);

    function setUp() public {
        dripsHub = new MockAddressDriver();
        parser = new MockFundingParser(address(dripsHub));
        dependencySplits = new DependencySplits(address(dripsHub));
    }

    function testConstructor() public view {
        assertEq(address(parser.addressDriver()), address(dripsHub));
        assertEq(parser.owner(), address(this));
    }

    function testRevertInvalidDriver() public {
        vm.expectRevert(FundingParser.InvalidAddressDriver.selector);
        new MockFundingParser(address(0));
    }

    function testParseFundingValid() public {
        bytes32 sourceHash = keccak256(bytes("ipfs://valid-package-json"));
        vm.expectEmit(true, true, true, true);
        emit FundingParsed(sourceHash, 1_000_000);

        IAddressDriver.SplitsReceiver[] memory receivers = parser.parseFunding("ipfs://valid-package-json");

        assertEq(receivers.length, 2);
        assertEq(receivers[0].accountId, 1001);
        assertEq(receivers[0].weight, 600_000);
        assertEq(receivers[1].accountId, 1002);
        assertEq(receivers[1].weight, 400_000);

        uint256 accountId = dripsHub.calcAccountId(address(parser));
        assertEq(dripsHub.hashes(accountId), keccak256(abi.encode(receivers)));
    }

    function testParseFundingDefault() public {
        IAddressDriver.SplitsReceiver[] memory receivers = parser.parseFunding("ipfs://other-metadata");
        assertEq(receivers.length, 1);
        assertEq(receivers[0].accountId, 9999);
        assertEq(receivers[0].weight, 1_000_000);
    }

    function testDependencySplitsAppliesAnalyzedReceivers() public {
        IAddressDriver.SplitsReceiver[] memory receivers = new IAddressDriver.SplitsReceiver[](2);
        receivers[0] = IAddressDriver.SplitsReceiver({accountId: 11, weight: 800_000});
        receivers[1] = IAddressDriver.SplitsReceiver({accountId: 22, weight: 200_000});
        bytes32 sourceHash = keccak256(bytes('{"name":"demo"}'));

        vm.expectEmit(true, false, false, true);
        emit FundingParsed(sourceHash, 1_000_000);

        bytes32 splitsHash = dependencySplits.applyAnalyzedSplits(sourceHash, receivers);
        assertEq(dependencySplits.lastSourceHash(), sourceHash);
        assertEq(splitsHash, keccak256(abi.encode(receivers)));
        assertEq(dripsHub.hashes(dripsHub.calcAccountId(address(dependencySplits))), splitsHash);
    }

    function testDependencySplitsParseFundingReverts() public {
        vm.expectRevert(DependencySplits.UseApplyAnalyzedSplits.selector);
        dependencySplits.parseFunding("ipfs://anything");
    }

    function testOnlyOwnerCanApply() public {
        IAddressDriver.SplitsReceiver[] memory receivers = new IAddressDriver.SplitsReceiver[](0);
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        dependencySplits.applySplits(receivers);
    }
}
