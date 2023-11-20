// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Callee } from "v2-core/interfaces/IUniswapV2Callee.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router01 } from "v2-periphery/interfaces/IUniswapV2Router01.sol";
import { IWETH } from "v2-periphery/interfaces/IWETH.sol";
import { IFakeLendingProtocol } from "./interfaces/IFakeLendingProtocol.sol";

// This is liquidator contract for testing,
// all you need to implement is flash swap from uniswap pool and call lending protocol liquidate function in uniswapV2Call
// lending protocol liquidate rule can be found in FakeLendingProtocol.sol
contract Liquidator is IUniswapV2Callee, Ownable {
    address internal immutable _FAKE_LENDING_PROTOCOL;
    address internal immutable _UNISWAP_ROUTER;
    address internal immutable _UNISWAP_FACTORY;
    address internal immutable _WETH9;
    uint256 internal constant _MINIMUM_PROFIT = 0.01 ether;

    struct CallbackData {
        address repayToken;
        address borrowToken;
        uint256 repayAmount;
        uint256 borrowAmount;
    }

    constructor(address lendingProtocol, address uniswapRouter, address uniswapFactory) {
        _FAKE_LENDING_PROTOCOL = lendingProtocol;
        _UNISWAP_ROUTER = uniswapRouter;
        _UNISWAP_FACTORY = uniswapFactory;
        _WETH9 = IUniswapV2Router01(uniswapRouter).WETH();
    }

    //
    // EXTERNAL NON-VIEW ONLY OWNER
    //

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, amount), "Withdraw failed");
    }

    //
    // EXTERNAL NON-VIEW
    //

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external override {
        require(sender == address(this), "sender must be this contract");
        require(amount0 > 0 || amount1 > 0, "one of amount must greater than 0");
        // [state change] receive (usdc) borrowAmount from uniswap
        // decode data
        CallbackData memory decode = abi.decode(data, (CallbackData));
        // approve usdc
        IERC20(decode.borrowToken).approve(_FAKE_LENDING_PROTOCOL, decode.borrowAmount);
        // execute liquidate position
        IFakeLendingProtocol(_FAKE_LENDING_PROTOCOL).liquidatePosition();
        // [state change] receive ETH from fake lending protocol
        // mint WETH from _WETH9
        IWETH(_WETH9).deposit{value: decode.repayAmount}();
        // repay token to pair
        // msg.sender would be uniswap contract
        IERC20(decode.repayToken).transfer(msg.sender, decode.repayAmount);
    }

    // we use single hop path for testing
    function liquidate(address[] calldata path, uint256 amountOut) external {
        require(amountOut > 0, "AmountOut must be greater than 0");
        // get pair
        address pair = IUniswapV2Factory(_UNISWAP_FACTORY).getPair(path[0], path[1]);
        // calculate (weth) repayToken using (usdc) borrowAmount
        uint256[] memory amountsIn = IUniswapV2Router01(_UNISWAP_ROUTER).getAmountsIn(amountOut, path);
        // encode callback data
        CallbackData memory data = CallbackData(path[0], path[1], amountsIn[0], amountOut);
        // call swap
        IUniswapV2Pair(pair).swap(0, amountOut, address(this), abi.encode(data));
    }

    receive() external payable {}
}
