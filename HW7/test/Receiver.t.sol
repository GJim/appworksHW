// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Receiver.sol";

contract ReceiverTest is Test {
    NotUseful public notUseful;
    Homework public homework;
    NFTReceiver public receiver;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public {
        notUseful = new NotUseful();
        homework = new Homework();
        // set homework address
        receiver = new NFTReceiver(address(homework));
    }

    function testOnReceive() public {
        address user = makeAddr("user");
        vm.startPrank(user);
        // address 0 transfer notUseful NFT to user
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user, 0);
        notUseful.mint(user);        
        // user transfer notUseful NFT to receiver
        vm.expectEmit(true, true, false, true);
        emit Transfer(user, address(receiver), 0);
        // receiver transfer notUseful NFT back to user
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(receiver), user, 0);
        // Receiver mint homework NFT to user
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user, 0);
        notUseful.safeTransferFrom(user, address(receiver), 0);
        // check user receive the NFT return by Receiver contract
        assertEq(notUseful.balanceOf(user), 1, "user NFT balance should be 1 after Receiver contract return back");
        assertEq(notUseful.ownerOf(0), user, "user should be the NFT 0 owner");
        // user receive homework NFT minted by receiver contract
        assertEq(homework.ownerOf(0), user, "user should be the NFT 0 owner");
        vm.stopPrank();
    }

}