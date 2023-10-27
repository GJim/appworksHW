// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {MultiRolesAuthority, Authority} from "solmate/auth/authorities/MultiRolesAuthority.sol";

contract USDC is ERC20, MultiRolesAuthority {

    event WhiteList(address indexed member, bool indexed allowed);

    mapping(address => bool) private _whitelist;

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals) MultiRolesAuthority(msg.sender, Authority(address(0))){
        // define contract admin role
        setRoleCapability(0, getSelector("addMember(address)"), true);
        setRoleCapability(0, getSelector("removeMember(address)"), true);
        // define whitelist role
        setRoleCapability(1, getSelector("mint(address,uint256)"), true);
        setRoleCapability(1, getSelector("transfer(address,uint256)"), true);
        setRoleCapability(1, getSelector("transferFrom(address,address,uint256)"), true);
        // setRoleCapability(1, this.mint.selector, true);
        // setRoleCapability(1, this.transfer.selector, true);
        // setRoleCapability(1, this.transferFrom.selector, true);
    }

    function getSelector(string memory functionName) public pure returns (bytes4) {
        return bytes4(keccak256(bytes(functionName)));
    }

    function addMember(address member) public requiresAuth {
        setUserRole(member, 1, true);
    }

    function removeMember(address member) public requiresAuth {
        setUserRole(member, 1, false);
    }

    function mint(address to, uint256 amount) public requiresAuth {
        _mint(to, amount);
    }

    function transfer(address to, uint256 amount) public virtual override requiresAuth returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override requiresAuth returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }
}
