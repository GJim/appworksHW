// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";

interface IBAYC {
    function mintApe(uint256 numberOfTokens) external payable;
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract BAYCTest is Test {
    address bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString("ALCHEMY_RPC_URL"));
        vm.selectFork(forkId);
        vm.rollFork(12299047);
    }

    function testMint() public {
        uint256 BAYCBalance = address(bayc).balance;
        address eoa = makeAddr("EOA");
        deal(eoa, 8 ether);
        vm.startPrank(eoa);
        for (uint256 i = 1; i <= 5; i++) {
            IBAYC(bayc).mintApe{value: 1.6 ether}(20);
        }
        assertEq(IBAYC(bayc).balanceOf(eoa), 100);
        assertEq(bayc.balance, BAYCBalance + 8 ether);
        vm.stopPrank();
    }
}
