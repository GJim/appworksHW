// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "../src/WETH.sol";

contract WETHScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        WETH weth = new WETH();
        vm.stopBroadcast();
    }
}
