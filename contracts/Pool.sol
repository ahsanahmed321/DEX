// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./LPToken.sol";

contract Pool {
    using SafeMath for uint256;

    address public factory;
    address public tokenA;
    address public tokenB;
    address public LPTokenAddress;
    uint256 public reservesTokenA;
    uint256 public reservesTokenB;
    uint256 public k;

    constructor(
        address tokenAC,
        address tokenBC,
        address LPTokenC
    ) {
        factory = msg.sender;
        tokenA = tokenAC;
        tokenB = tokenBC;
        LPTokenAddress = LPTokenC;
    }

    function _getAmountOut(address tokenFrom, uint256 amountFrom)
        private
        returns (uint256)
    {
        uint256 _amountA = tokenFrom == tokenA ? amountFrom : 0;
        uint256 _amountB = tokenFrom == tokenB ? amountFrom : 0;
        uint256 amountOut;
        if (_amountB == 0) {
            uint256 newReservesTokenA = reservesTokenA.add(amountFrom);
            uint256 newReservesTokenB = k.div(newReservesTokenA);
            amountOut = reservesTokenB.sub(newReservesTokenB);
            reservesTokenA = newReservesTokenA;
            reservesTokenB = reservesTokenB.sub(amountOut);
        }
        if (_amountA == 0) {
            uint256 newReservesTokenB = reservesTokenB.add(amountFrom);
            uint256 newReservesTokenA = k.div(newReservesTokenB);
            amountOut = reservesTokenA.sub(newReservesTokenA);
            reservesTokenA = reservesTokenA.sub(amountOut);
            reservesTokenB = newReservesTokenB;
        }

        return amountOut;
    }

    function addLiquidity(
        address tokenAL,
        address tokenBL,
        uint256 amountTokenA,
        uint256 amountTokenB
    ) public payable {
        IERC20(tokenAL).transferFrom(msg.sender, address(this), amountTokenA);
        reservesTokenA = reservesTokenA.add(amountTokenA);

        IERC20(tokenBL).transferFrom(msg.sender, address(this), amountTokenB);
        reservesTokenB = reservesTokenB.add(amountTokenB);

        k = amountTokenA.mul(amountTokenB);

        ILPToken(LPTokenAddress).mint(msg.sender, amountTokenA);
    }

    function swap(address tokenFrom, uint256 amountFrom) public payable {
        address tokenTo = tokenFrom == tokenA ? tokenB : tokenA;

        uint256 amountOut = _getAmountOut(tokenFrom, amountFrom);

        IERC20(tokenFrom).transferFrom(msg.sender, address(this), amountFrom);
        IERC20(tokenTo).transfer(msg.sender, amountOut);
    }
}
