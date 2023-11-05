// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/ERC721AToken.sol";
import "../src/ERC721ConsecutiveToken.sol";
import "../src/ERC721EnumerableToken.sol";

contract BenchmarkTest is Test {
    address public owner;
    address public operator;
    address public receiver;

    ERC721AToken public eat;
    // ERC721ConsecutiveToken public ect;
    ERC721EnumerableToken public eet;

    function setUp() public {
        owner = makeAddr("owner");
        operator = makeAddr("operator");
        receiver = makeAddr("receiver");
        eat = new ERC721AToken();
        // ect = new ERC721ConsecutiveToken();
        eet = new ERC721EnumerableToken();
    }

    function testMintFifty() public {
        // use each function to mint 50 NFT
        vm.startPrank(owner);
        eat.mintBatch(owner, 50);
        eet.mintBatch(owner, 50);
        assertEq(eat.ownerOf(49), owner);
        assertEq(eet.ownerOf(49), owner);
        eat.mintERC2309Batch(owner, 50);
        vm.stopPrank();

        // use each function to approve NFT 0
        vm.startPrank(owner);
        eat.approve(operator, 25);
        eet.approve(operator, 25);
        vm.stopPrank();

        // use each function to transfer NFT 0
        vm.startPrank(operator);
        eat.transfer25(owner, receiver);
        eet.transfer25(owner, receiver);
        vm.stopPrank();
    }

    function testTransferFrom() public {
        // use each function to mint one NFT
        vm.startPrank(owner);
        eat.mintOne(owner);
        eet.mintOne(owner);
        eat.mintERC2309One(owner);
        vm.stopPrank();

        // use each function to approve NFT 0
        vm.startPrank(owner);
        eat.approve(operator, 0);
        eet.approve(operator, 0);
        vm.stopPrank();

        // use each function to transfer NFT 0
        vm.startPrank(operator);
        eat.transferFrom(owner, receiver, 0);
        eet.transferFrom(owner, receiver, 0);
        vm.stopPrank();
    }
}
