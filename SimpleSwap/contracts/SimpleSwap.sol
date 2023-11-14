// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {

   // event AddLiquidity(address indexed sender, uint256 amountA, uint256 amountB, uint256 liquidity);
   // event RemoveLiquidity(address indexed sender, uint256 amountA, uint256 amountB, uint256 liquidity);
   // event Swap(
   //     address indexed sender,
   //     address indexed tokenIn,
   //     address indexed tokenOut,
   //     uint256 amountIn,
   //     uint256 amountOut
   // );

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

   }

   /// @notice Remove liquidity from the pool
   /// @param liquidity The amount of liquidity to remove
   /// @return amountA The amount of tokenA received
   /// @return amountB The amount of tokenB received
   function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB){

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
}