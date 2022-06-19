// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LPToken is ERC20, ERC20Burnable {
    constructor() ERC20("LP_Token", "LPT") {}

    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }
}

interface ILPToken is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
}
