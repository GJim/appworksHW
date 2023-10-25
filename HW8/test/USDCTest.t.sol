// https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48#code
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";

contract USDCTest is Test {
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address owner = makeAddr("newOwner");
    // convert new owner address to bytes32
    bytes32 newAdmin = bytes32(uint256(uint160(owner)));
    address nobody = makeAddr("nobody");
    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString("ALCHEMY_RPC_URL"));
        vm.selectFork(forkId);
        // convert new owner address to bytes32
        bytes32 newAdmin = bytes32(uint256(uint160(owner)));
        // define the slot of the usdc contract admin storage
        bytes32 ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;
        // set new owner to usdc contract admin, which mean set the value at admin slot to new owner address
        vm.store(usdc, ADMIN_SLOT, newAdmin);
    }

    function testOwner() public {
        vm.startPrank(nobody);
        // assertEq(usdc.admin(), owner);
        // owner address are not the admin to the contract yet
        vm.expectRevert("EvmError: Revert");
        (bool success, bytes memory data) = address(usdc).call(abi.encodeWithSignature("admin()"));
        vm.stopPrank();

        vm.startPrank(owner);
        // check the new owner address is the admin of usdc contract
        (success, data) = address(usdc).call(abi.encodeWithSignature("admin()"));
        assertEq(bytes32(data), newAdmin);
        vm.stopPrank();
    }

    function testWhitelist() public {
        vm.startPrank(owner);
        vm.stopPrank();
    }


}