// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";
import { RNDNFT } from "../src/RNDNFT.sol";

contract RNDNFTTest is Test {

    // support toString library
    using Strings for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    VRFCoordinatorV2Mock public vrfCoordinator;
    RNDNFT public rndnft;
    bytes32 private _keyhash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint64 private _subId;
    uint96 private _amount = 1000000000000000000;
    address private _eoa;
    address public user;
    function setUp() public {
        // first parameter: base fee
        // second parameter: link gas price
        vrfCoordinator = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);
        _eoa = makeAddr("eoa");
        deal(_eoa, 1000 ether);
        vm.startPrank(_eoa);
        // get the subscription id from coordinator
        _subId = vrfCoordinator.createSubscription();
        // fund the subscription address with enough amount of link token
        vrfCoordinator.fundSubscription(_subId, _amount);
        // deploy RNDNFT account
        rndnft = new RNDNFT(_subId, address(vrfCoordinator), _keyhash);
        // add rndnft contract into subscription address
        vrfCoordinator.addConsumer(_subId, address(rndnft));
        vm.stopPrank();
    }

    function testMintBlindBox() public {
        user = makeAddr("user");
        vm.startPrank(user);
        assertEq(rndnft.balanceOf(user), 0, "user NFT balance should be 0 before mint");
        // address 0 transfer notUseful NFT to user
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user, 0);
        rndnft.mint();
        assertEq(rndnft.balanceOf(user), 1, "user NFT balance should be 1 after mint");
        assertEq(rndnft.ownerOf(0), user, "ID 0 token's owner should be user address");
        assertEq(rndnft.tokenURI(0), "https://localhost/collections/default.jpg", "current ID 0 token should be blind box before contract owner unblinding");
        vm.stopPrank();
    }

    function testUnblind() public {
        vm.startPrank(user);
        // should be revert because user is not contract owner
        vm.expectRevert("NotOwner()");
        address(rndnft).call(abi.encodeWithSignature("unblind()"));
        vm.stopPrank();
        vm.startPrank(_eoa);
        vm.roll(100);
        // should be revert when block number have not reach
        vm.expectRevert("BlockNumberNotEnough()");
        address(rndnft).call(abi.encodeWithSignature("unblind()"));
        vm.roll(15000);
        // user blind box should be uncover and get the real tokenuri
        rndnft.unblind();
        // random number should be fulfilled by myself in testnet
        vrfCoordinator.fulfillRandomWords(1, address(rndnft));
        // get the random value
        uint256 rnd = rndnft.getRndForTest();
        uint256 number = (0+rnd)%500;
        assertEq(rndnft.tokenURI(0), string.concat("https://localhost/collections/", number.toString()), "current ID 1 token should be uncover after contract owner unblinding");
        vm.stopPrank();
    }
}