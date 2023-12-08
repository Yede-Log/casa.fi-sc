// SPDX-License-Identifier: UNLICENSED 
pragma solidity >0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

contract RENToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("REN Token", "REN") Ownable(_msgSender()) {
        _mint(msg.sender, initialSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(uint256 _amount) onlyOwner() external {
        _mint(_msgSender(), _amount);
    }
}
