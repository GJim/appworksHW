// https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48#code
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import {USDC, Authority} from "../src/USDCv2.sol";

contract USDCv2Test is Test {

    event Transfer(address indexed from, address indexed to, uint256 amount);

    address owner = makeAddr("newOwner");
    // convert new owner address to bytes32
    bytes32 newAdmin = bytes32(uint256(uint160(owner)));
    address nobody = makeAddr("nobody");
    address member = makeAddr("member");

    function testMultiRoles() public {
        vm.startPrank(owner);
        // deploy usdc v2 contract
        USDC usdc2 = new USDC("US Dollar", "USDC", 18);
        // set usdc address as authority
        usdc2.setAuthority(Authority(address(usdc2)));
        // check role setting
        assertEq(usdc2.doesRoleHaveCapability(1, usdc2.mint.selector), true);
        assertEq(usdc2.doesRoleHaveCapability(1, usdc2.transfer.selector), true);
        assertEq(usdc2.doesRoleHaveCapability(1, usdc2.transferFrom.selector), true);
        assertEq(usdc2.doesRoleHaveCapability(1, usdc2.addMember.selector), false);
        assertEq(usdc2.doesRoleHaveCapability(1, usdc2.removeMember.selector), false);
        vm.stopPrank();
        // test failed for unauthorized
        vm.startPrank(nobody);
        vm.expectRevert("UNAUTHORIZED");
        usdc2.mint(nobody, 10 ether);
        vm.expectRevert("UNAUTHORIZED");
        usdc2.transfer(nobody, 10 ether);
        vm.expectRevert("UNAUTHORIZED");
        usdc2.transferFrom(owner, nobody, 10 ether);
        vm.expectRevert("UNAUTHORIZED");
        usdc2.addMember(nobody);
        vm.expectRevert("UNAUTHORIZED");
        usdc2.removeMember(nobody);
        // test success for public user functions
        assertEq(usdc2.balanceOf(nobody), 0);
        vm.stopPrank();

        vm.startPrank(owner);
        // add member into whitelist
        usdc2.addMember(member);
        assertEq(usdc2.doesUserHaveRole(member, 1), true);
        assertEq(usdc2.doesUserHaveRole(member, 0), false);
        vm.stopPrank();
        
        vm.startPrank(member);
        // test failed for unauthorized functions
        vm.expectRevert("UNAUTHORIZED");
        usdc2.addMember(member);
        vm.expectRevert("UNAUTHORIZED");
        usdc2.removeMember(member);
        // test success for whitelist functions
        // test mint
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), member, 2000);
        usdc2.mint(member, 2000);
        assertEq(usdc2.balanceOf(member), 2000);
        // test transfer
        vm.expectEmit(true, true, false, true);
        emit Transfer(member, nobody, 1000);
        usdc2.transfer(nobody, 1000);
        assertEq(usdc2.balanceOf(nobody), 1000);
        // test transferFrom
        vm.expectEmit(true, true, false, true);
        emit Transfer(member, owner, 500);
        usdc2.transferFrom(member, owner, 500);
        assertEq(usdc2.balanceOf(member), 500);
        assertEq(usdc2.balanceOf(owner), 500);
        vm.stopPrank();
    }
}
