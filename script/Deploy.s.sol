// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DependencySplits} from "../src/DependencySplits.sol";

/**
 * @notice Deploy DependencySplits against a canonical Drips AddressDriver.
 *
 *   ADDRESS_DRIVER=0x... forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
 */
contract DeployScript is Script {
    function run() external {
        address addressDriver = vm.envAddress("ADDRESS_DRIVER");
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        DependencySplits splits = new DependencySplits(addressDriver);
        vm.stopBroadcast();

        require(address(splits.addressDriver()) == addressDriver, "driver mismatch");
    }
}
