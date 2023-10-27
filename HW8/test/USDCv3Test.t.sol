// https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48#code
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import {FiatTokenV3} from "../src/USDCv3.sol";

contract USDCv3Test is Test {

    event InitailizeV3Event(address newOwner);
    event AddWhilelistMember(address member);
    event RemoveWhilelistMember(address member);
    event Transfer(address indexed from, address indexed to, uint256 value);

    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address admin = makeAddr("admin");
    address owner = makeAddr("newOwner");
    // convert new owner address to bytes32
    bytes32 newAdmin = bytes32(uint256(uint160(admin)));
    address nobody = makeAddr("nobody");
    address member = makeAddr("member");
    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString("ALCHEMY_RPC_URL"));
        vm.selectFork(forkId);
        // define the slot of the usdc contract admin storage
        bytes32 ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;
        // set new owner to usdc contract admin, which mean set the value at admin slot to new owner address
        vm.store(usdc, ADMIN_SLOT, newAdmin);
    }

    function testOwner() public {
        vm.startPrank(nobody);
        // owner address are not the admin to the contract yet
        vm.expectRevert("EvmError: Revert");
        (bool success, bytes memory data) = address(usdc).call(abi.encodeWithSignature("admin()"));
        vm.stopPrank();

        vm.startPrank(admin);
        // check the new owner address is the admin of usdc contract
        (success, data) = address(usdc).call(abi.encodeWithSignature("admin()"));
        assertEq(bytes32(data), newAdmin);
        vm.stopPrank();
    }

    function testUpgrade() public {
        vm.startPrank(admin);
        // deploy usdc v3 contract
        FiatTokenV3 usdc3 = new FiatTokenV3();
        // upgrade usdc contract and test initializeV3 event can be triggered
        vm.expectEmit(true, false, false, false);
        emit InitailizeV3Event(owner);
        usdc.call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(usdc3), abi.encodeWithSignature("initializeV3(address)", owner)));
        (bool success, bytes memory data) = usdc.call(abi.encodeWithSignature("implementation()"));
        // tset new implementation address is usdc v3
        assertEq(bytes32(data), bytes32(uint256(uint160(address(usdc3)))));
        vm.stopPrank();

        // prank as usdc v3 implementation new owner
        vm.startPrank(owner);
        (success, ) = usdc.call(abi.encodeWithSignature("addMember(address)", member));
        assertEq(success, true);
        // define usdc v3 instance for test convincence
        FiatTokenV3 usdcProxy = FiatTokenV3(usdc);
        // test addMember and removeMember
        vm.expectEmit(true, false, false, false);
        emit AddWhilelistMember(member);
        usdcProxy.addMember(member);
        emit RemoveWhilelistMember(nobody);
        usdcProxy.removeMember(nobody);
        vm.stopPrank();

        // prank as member which is in whitelist
        vm.startPrank(member);
        // test minting and tranfering
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), member, 10 ether);
        usdcProxy.minting(member, 10 ether);
        vm.expectEmit(true, true, false, true);
        emit Transfer(member, nobody, 5 ether);
        usdcProxy.transfering(nobody, 5 ether);
        // test failed for addMember and removeMember
        vm.expectRevert("Ownable: caller is not the owner");
        usdcProxy.addMember(nobody);
        vm.expectRevert("Ownable: caller is not the owner");
        usdcProxy.removeMember(nobody);
        vm.stopPrank();

        // prank as nobody which is not in whitelist
        vm.startPrank(nobody);
        // test failed for whitelist
        vm.expectRevert("FiatToken: caller is not in whitelist");
        usdcProxy.minting(nobody, 10 ether);
        vm.expectRevert("FiatToken: caller is not in whitelist");
        usdcProxy.transfering(nobody, 3 ether);
        // test success for public user functions
        assertEq(usdcProxy.balanceOf(nobody), 5 ether);
        vm.stopPrank();
    }

}
