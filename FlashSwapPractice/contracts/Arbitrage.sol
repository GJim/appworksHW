// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Callee } from "v2-core/interfaces/IUniswapV2Callee.sol";

// This is a practice contract for flash swap arbitrage
contract Arbitrage is IUniswapV2Callee, Ownable {

    //
    // EXTERNAL NON-VIEW ONLY OWNER
    //

    struct Callback {
        address weth;
        address usdc;
        address priceLowerPool;
        address priceHigherPool;
        uint256 borrowAmount;
        uint256 payBackAmount;
    }

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
        
        //////          Method 1          //////
        // *[we got the borrowed eth now]
        // decode the callback data encoded in arbitrage function
        Callback memory decode = abi.decode(data, (Callback));
        // [swap WETH for USDC in higher price pool]
        // in order to calculate how much usdc we can swap for borrowed weth
        // we need to get the reserves from higher price pool
        (uint256 wethReserve, uint256 usdcReserve,) = IUniswapV2Pair(decode.priceHigherPool).getReserves();
        // use the _getAmountOut to calculate the amount of usdc for exact weth we can deposit
        uint256 revenue = _getAmountOut(decode.borrowAmount, wethReserve, usdcReserve);
        // deposit exact weth into higher price pool before swap
        IERC20(decode.weth).transfer(decode.priceHigherPool, decode.borrowAmount);
        // *[we do not have any asset now]
        // trigger higher price pool swap function to receive usdc
        IUniswapV2Pair(decode.priceHigherPool).swap(0, revenue, address(this), "");
        // *[we got the revenue of usdc now]
        // [repay USDC to lower pool]
        IERC20(decode.usdc).transfer(decode.priceLowerPool, decode.payBackAmount);

        //////          Method 2          //////
        // // *[we got the borrowed usdc now]
        // // decode the callback data encoded in arbitrage function
        // Callback memory decode = abi.decode(data, (Callback));
        // // [swap USDC for WETH in lower pool]
        // // in order to calculate how much weth we can swap for borrowed usdc
        // // we need to get the reserves from lower price pool
        // (uint256 wethReserve, uint256 usdcReserve,) = IUniswapV2Pair(decode.priceLowerPool).getReserves();
        // // use the _getAmountOut to calculate the amount of weth for exact usdc we can deposit
        // uint256 revenue = _getAmountOut(decode.borrowAmount, usdcReserve, wethReserve);
        // // deposit exact usdc into lower pool before swap
        // IERC20(decode.usdc).transfer(decode.priceLowerPool, decode.borrowAmount);
        // // *[we do not have any asset now]
        // // trigger lower price pool swap function to receive weth
        // IUniswapV2Pair(decode.priceLowerPool).swap(revenue, 0, address(this), "");
        // // *[we got the revenue of weth now]
        // // [repay WETH to higher pool]
        // IERC20(decode.weth).transfer(decode.priceHigherPool, decode.payBackAmount);
    }

    // Method 1 is
    //  - borrow WETH from lower price pool
    //  - swap WETH for USDC in higher price pool
    //  - repay USDC to lower pool
    // Method 2 is
    //  - borrow USDC from higher price pool
    //  - swap USDC for WETH in lower pool
    //  - repay WETH to higher pool
    // for testing convenient, we implement the method 1 here
    function arbitrage(address priceLowerPool, address priceHigherPool, uint256 borrowAmount) external {
        require(borrowAmount > 0, "Borrow amount must be greater than 0");

        //////          Method 1          //////
        // get weth and usdc address from any pool
        address weth = IUniswapV2Pair(priceLowerPool).token0();
        address usdc = IUniswapV2Pair(priceLowerPool).token1();
        // [borrow WETH from lower price pool]
        // in order to calculate how much usdc we need to pay back
        // we need to get the reserves from lower price pool
        (uint256 wethReserve, uint256 usdcReserve,) = IUniswapV2Pair(priceLowerPool).getReserves();
        // use the _getAmountIn to calculate the amount of usdc for exact weth we want to borrow
        uint256 payBackAmount = _getAmountIn(borrowAmount, usdcReserve, wethReserve);
        Callback memory data = Callback(weth, usdc, priceLowerPool, priceHigherPool, borrowAmount, payBackAmount);
        // trigger lower price pool swap function
        IUniswapV2Pair(priceLowerPool).swap(borrowAmount, 0, address(this), abi.encode(data));

        //////          Method 2          //////
        // // get weth and usdc address from any pool
        // address weth = IUniswapV2Pair(priceLowerPool).token0();
        // address usdc = IUniswapV2Pair(priceLowerPool).token1();
        // // [borrow USDC from higher price pool]
        // // in order to calculate how much weth we need to pay back
        // // we need to get the reserves from higher price pool
        // (uint256 wethReserve, uint256 usdcReserve,) = IUniswapV2Pair(priceHigherPool).getReserves();
        // // use the _getAmountIn to calculate the amount of weth for exact usdc we want to borrow
        // uint256 payBackAmount = _getAmountIn(borrowAmount, wethReserve, usdcReserve);
        // Callback memory data = Callback(weth, usdc, priceLowerPool, priceHigherPool, borrowAmount, payBackAmount);
        // // trigger higher price pool swap function
        // IUniswapV2Pair(priceHigherPool).swap(0, borrowAmount, address(this), abi.encode(data));
    }

    //
    // INTERNAL PURE
    //

    // copy from UniswapV2Library
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // copy from UniswapV2Library
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
