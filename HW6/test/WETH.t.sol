// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/WETH.sol";

contract WETHTest is Test {
    WETH public weth;

    event Deposit(address indexed to, uint256 value);
    event Withdraw(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        weth = new WETH();
    }

    function testContract() public {
        // create a temporary eoa account with 1000 eth
        address eoa = makeAddr("eoa");
        deal(eoa, 1000 ether);
        vm.startPrank(eoa);
        // 測項 3: deposit 應該要 emit Deposit event
        // event has 4 argument, first 3 arguments are indexed value
        // and the last argument is data
        // in Deposit() case, only "to" using indexed
        // so first argument should be equal to eoa account
        // and the last argument should be equal to 10 ether
        vm.expectEmit(true, false, false, true);
        // mint action should transfer from address 0 to eoa account with 10 ether
        emit Deposit(eoa, 10 ether);
        // use address call to send 10 eth into weth
        (bool success, ) = address(weth).call{value: 10 ether}(abi.encodeWithSignature("deposit()"));
        assertEq(success, true, "Failed to deposit ETH into WETH");
        // 測項 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
        assertEq(weth.balanceOf(eoa), 10 ether, "WETH balance should be 10 ether after deposit");
        // 測項 2: deposit 應該將 msg.value 的 ether 轉入合約
        assertEq(address(weth).balance, 10 ether, "WETH's contract ETH balance should be 10 ether after deposit");
        // eoa balance should be decrease 
        assertEq(eoa.balance, 990 ether, "EOA ETH balance should be 990 ether after deposit");
        // WETH contract total supply should become 10 ether after mint
        assertEq(weth.totalSupply(), 10 ether, "Total supply of WETH should be 10 ether after deposit");
        // Should fail to withdraw cause by InsufficientBalance
        vm.expectRevert("InsufficientBalance()");
        (success, ) = address(weth).call(abi.encodeWithSignature("withdraw(uint256)", 11 ether));
        // 測項 6: withdraw 應該要 emit Withdraw event
        vm.expectEmit(true, false, false, true);
        // burn action should transfer from eoa account to address 0 with 5 ether
        emit Withdraw(eoa, 5 ether);
        (success, ) = address(weth).call(abi.encodeWithSignature("withdraw(uint256)", 5 ether));
        assertEq(success, true, "Failed to withdraw WETH back to ETH");
        // 測項 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
        // burn mean decrease the total supply and user's balance
        assertEq(weth.totalSupply(), 5 ether, "Total supply of WETH should be 5 ether after burn");
        assertEq(weth.balanceOf(eoa), 5 ether, "WETH balance should be 5 ether after burn");
        // 測項 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
        assertEq(eoa.balance, 995 ether, "EOA ETH balance should be 995 ether after withdraw");
        // create a second temporary eoa
        address eoa2 = makeAddr("eoa2");
        // should fail to transfer cause by InsufficientBalance
        vm.expectRevert("InsufficientBalance()");
        (success, ) = address(weth).call(abi.encodeWithSignature("transfer(address,uint256)", eoa2, 11 ether));
        // should fail to transfer cause by InvalidAccount
        vm.expectRevert("InvalidAccount()");
        (success, ) = address(weth).call(abi.encodeWithSignature("transfer(address,uint256)", address(0), 1 ether));
        // 測項 7: transfer 應該要將 erc20 token 轉給別人
        vm.expectEmit(true, true, false, true);
        // transfer action would transfer from eao address to eoa2 address with 3 ether
        emit Transfer(eoa, eoa2, 3 ether);
        // trigger transfer action
        (success, ) = address(weth).call(abi.encodeWithSignature("transfer(address,uint256)", eoa2, 3 ether));
        assertEq(success, true, "Failed to transfer WETH from eoa to eoa2 address");
        // eoa address should become 2 WETH
        assertEq(weth.balanceOf(eoa), 2 ether, "WETH balance should be 5 ether after transfer");
        // eoa2 address should become 3 WETH
        assertEq(weth.balanceOf(eoa2), 3 ether, "WETH balance should be 3 ether after transfer");
        vm.stopPrank();
        // switch msg sender address to eoa2
        vm.startPrank(eoa2);
        // should fail to approve invalid account
        vm.expectRevert("InvalidAccount()");
        (success, ) = address(weth).call(abi.encodeWithSignature("approve(address,uint256)", address(0), 1 ether));
        // emit approval event after approve method triggered
        // eoa2 approve 2 ether to eoa address
        vm.expectEmit(true, true, false, true);
        emit Approval(eoa2, eoa, 2 ether);
        (success, ) = address(weth).call(abi.encodeWithSignature("approve(address,uint256)", eoa, 2 ether));
        // 測項 8: approve 應該要給他人 allowance
        assertEq(weth.allowance(eoa2, eoa), 2 ether, "The allowance should be 2 ether after approve");
        vm.stopPrank();
        // switch msg sender address back to eoa
        vm.startPrank(eoa);
        vm.expectRevert("InsufficientAllowance()");
        (success, ) = address(weth).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", eoa2, eoa, 3 ether));
        // 測項 9: transferFrom 應該要可以使用他人的 allowance
        // should emit transfer event after transfer successfully
        vm.expectEmit(true, true, false, true);
        emit Transfer(eoa2, eoa, 1 ether);
        (success, ) = address(weth).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", eoa2, eoa, 1 ether));
        assertEq(success, true, "Failed to call transferfrom method");
        // 測項 10: transferFrom 後應該要減除用完的 allowance
        assertEq(weth.allowance(eoa2, eoa), 1 ether, "The allowance should be 1 ether after transferfrom 1 ether");
        vm.stopPrank();
    }
}
