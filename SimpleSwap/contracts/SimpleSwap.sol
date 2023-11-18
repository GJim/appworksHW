// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {

    address private _tokenA;
    address private _tokenB;
    uint256 private _reserveA;
    uint256 private _reserveB;

    constructor(address tokenA, address tokenB) ERC20("SimpleSwap", "SS") {
        require(tokenA != tokenB, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        require(tokenA.code.length > 0, "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(tokenB.code.length > 0, "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        (_tokenA, _tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /// @notice Swap tokenIn for tokenOut with amountIn
    /// @param tokenIn The address of the token to swap from
    /// @param tokenOut The address of the token to swap to
    /// @param amountIn The amount of tokenIn to swap
    /// @return amountOut The amount of tokenOut received
    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {
        // avoid identical address
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        // avoid input token not A or B
        require(tokenIn == _tokenA || tokenIn == _tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        // avoid output token not A or B
        require(tokenOut == _tokenA || tokenOut == _tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        // check amount valid
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        // get reserve storage into memory
        (uint256 reserveA, uint256 reserveB) = (_reserveA, _reserveB);

        // distinguish tokenA and tokenB
        if(tokenIn == _tokenA) {
            // calculate amount out
            amountOut = _amountOut(amountIn, reserveA, reserveB);
            // update updated reserve by memory variable
            _reserveA = reserveA + amountIn;
            _reserveB = reserveB - amountOut;
        } else {
            amountOut = _amountOut(amountIn, reserveB, reserveA);
            _reserveB = reserveB + amountIn;
            _reserveA = reserveA - amountOut;
        }
        
        // transfer input token into this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // transfer output token with calculated amount for sender
        IERC20(tokenOut).transfer(msg.sender, amountOut);
        // emit event
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @notice Add liquidity to the pool
    /// @param amountAIn The amount of tokenA to add
    /// @param amountBIn The amount of tokenB to add
    /// @return amountA The actually amount of tokenA added
    /// @return amountB The actually amount of tokenB added
    /// @return liquidity The amount of liquidity minted
    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        // check inputs amount valid
        require(amountAIn != 0 && amountBIn != 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        
        // get reserve storage into memory
        (uint256 reserveA, uint256 reserveB) = (_reserveA, _reserveB);

        // find the optimal amounts that matches the proportion of pool
        if (reserveA == 0 && reserveB == 0) {
            // first time add liquidity
            amountA = amountAIn;
            amountB = amountBIn;
        } else {
            uint256 amountBOptimal = _quote(amountAIn, reserveA, reserveB);
            if(amountBOptimal <= amountBIn) {
                // use all of A and some proportion of B
                (amountA, amountB) = (amountAIn, amountBOptimal);
            } else {
                // use all of B and some proportion of A
                // because input A proportion is bigger than B
                uint256 amountAOptimal = _quote(amountBIn, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, amountBIn);
            }
        }

        uint256 _totalSupply = totalSupply();
        // calculate the number of liquidity token to be minted
        if(_totalSupply == 0) {
            // first time add liquidity
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
        }

        // update reserve
        _reserveA = reserveA + amountA;
        _reserveB = reserveB + amountB;

        // transfer token into this contract
        IERC20(_tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), amountB);
        
        // mint liquidity token
        _mint(msg.sender, liquidity);
        
        // emit event
        emit AddLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Remove liquidity from the pool
    /// @param liquidity The amount of liquidity to remove
    /// @return amountA The amount of tokenA received
    /// @return amountB The amount of tokenB received
    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB){
        // check liquidity amount valid
        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");
        
        // transfer sender liqudity token to this contract
        // use "this" to ensure 
        this.transferFrom(msg.sender, address(this), liquidity);
        
        // get reserve storage into memory
        (uint256 reserveA, uint256 reserveB) = (_reserveA, _reserveB);

        // total supply of liqudity token
        uint256 _totalSupply = totalSupply();

        // calculte amount of token need to return
        amountA = liquidity * reserveA / _totalSupply;
        amountB = liquidity * reserveB / _totalSupply;

        // update reserve
        _reserveA = reserveA - amountA;
        _reserveB = reserveB - amountB;

        // burn sender liqudity token
        _burn(address(this), liquidity);

        // return tokens back to user
        IERC20(_tokenA).transfer(msg.sender, amountA);
        IERC20(_tokenB).transfer(msg.sender, amountB);

        // emit event
        emit RemoveLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Get the reserves of the pool
    /// @return reserveA The reserve of tokenA
    /// @return reserveB The reserve of tokenB
    function getReserves() external view returns (uint256 reserveA, uint256 reserveB){
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    /// @notice Get the address of tokenA
    /// @return tokenA The address of tokenA
    function getTokenA() external view returns (address tokenA){
        tokenA = _tokenA;
    }

    /// @notice Get the address of tokenB
    /// @return tokenB The address of tokenB
    function getTokenB() external view returns (address tokenB){
        tokenB = _tokenB;
    }

    /// @notice Calculate the amount of output token that matches the k
    /// [formula] reserve0 * reserve1 = (reserve0 + amount0) * (reserve1 - amount1)
    function _amountOut(uint256 amount0, uint256 reserve0, uint256 reserve1) internal pure returns (uint256 amount1) {
        // this format cause k decrease
        // amount1 = reserve1 - reserve0 * reserve1 / (reserve0 + amount0);

        // this format does not cause k decrease
        amount1 = amount0 * reserve1 / (amount0 + reserve0);
    }

    /// @notice Calculate the amount of token that matches the proportion of current pool
    /// [formula] amount0 / amount1 = reserve0 / reserve1
    function _quote(uint256 amount0, uint256 reserve0, uint256 reserve1) internal pure returns (uint256 amount1) {
        require(amount0 > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserve0 > 0 && reserve1 > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amount1 = amount0 * reserve1 / reserve0;
    }
}