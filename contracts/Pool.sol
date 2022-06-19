// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./LPToken.sol";
import "hardhat/console.sol";

contract Pool {
    using SafeMath for uint256;

    address public factory;
    address public tokenA;
    address public tokenB;
    address public LPTokenAddress;
    uint256 public reservesTokenA;
    uint256 public reservesTokenB;
    uint256 public k;
    uint256 public totalSupplyOfLP;

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

    function getRatio() public view returns (uint256) {
        uint256 ratio = reservesTokenA / reservesTokenB;
        console.log(ratio, "yeh dekho ratio");
        return ratio;
    }

    function updateReserve(uint256 newReservesTokenA, uint256 newReservesTokenB) internal {
        reservesTokenA = newReservesTokenA;
        reservesTokenB = newReservesTokenB;
    }

    function removeLiquidity(uint256 LPTokenAmount) public {
        console.log("LPTokenAmount : %s", LPTokenAmount);
        console.log("totalSupplyOfLP : %s", totalSupplyOfLP);
        uint256 share = LPTokenAmount.mul(100).div(totalSupplyOfLP);
        console.log("share %s :", share);
        uint256 sharesInReserveA = share.mul(reservesTokenA).div(100);
        console.log("sharesInReserveA %s :", sharesInReserveA);
        uint256 sharesInReserveB = share.mul(reservesTokenB).div(100);
        console.log("sharesInReserveB %s :", sharesInReserveB);

        // updateReserve(reservesTokenA.sub(sharesInReserveA), reservesTokenB.sub(sharesInReserveB));

        uint256 bal = ILPToken(LPTokenAddress).balanceOf(msg.sender);
        console.log("bal is %s:", bal);
        ILPToken(LPTokenAddress).burnFrom(msg.sender, LPTokenAmount);
        IERC20(tokenA).transfer(msg.sender, sharesInReserveA);
        IERC20(tokenB).transfer(msg.sender, sharesInReserveB);

    }

    function addLiquidity(
        address tokenAL,
        address tokenBL,
        uint256 amountTokenA
    ) public payable {

        uint256 ratio = 1;
        if (reservesTokenA > 0 && reservesTokenB > 0) {
            ratio = reservesTokenA.div(reservesTokenB);
        }
        
        uint256 amountTokenB = amountTokenA.div(ratio);
        console.log("kumail", amountTokenB);

        IERC20(tokenAL).transferFrom(msg.sender, address(this), amountTokenA);
        reservesTokenA = reservesTokenA.add(amountTokenA);

        IERC20(tokenBL).transferFrom(msg.sender, address(this), amountTokenB);
        reservesTokenB = reservesTokenB.add(amountTokenB);

        k = amountTokenA.mul(amountTokenB);
        console.log("LPTokensToMint at start is %s tokens", totalSupplyOfLP);
        if(totalSupplyOfLP == 0){
            ILPToken(LPTokenAddress).mint(msg.sender, 100 ether);
            totalSupplyOfLP += 100 * 10**18;
            console.log("LPTokensToMint when ts = 0 %s tokens", totalSupplyOfLP);

        }   
        else{
            uint256 LPTokensToMint = calculateLPToken(amountTokenA, amountTokenB);
            console.log("LPTokensToMint after calculation is", LPTokensToMint);
            totalSupplyOfLP = totalSupplyOfLP + LPTokensToMint.mul(10**18);
            ILPToken(LPTokenAddress).mint(msg.sender, LPTokensToMint.mul(10**18));
        }

        //ILPToken(LPTokenAddress).mint(msg.sender, amountTokenA);
    }

    function calculateLPToken(uint256 amountTokenA, uint256 amountTokenB) internal view returns(uint256 LPTokensToMint) {
        //uint256 ratio = ti();
        uint256 total = amountTokenA.add(amountTokenB);
        console.log("total %s",total);

        uint256 totalReserve = reservesTokenA.add(reservesTokenB);
        console.log("totalReserve %s",totalReserve);
        
        uint256 shareOfLP = total.mul(100).div(totalReserve);
        console.log("shareOfLP %s",shareOfLP);
        
        uint256 shareOfPreviousLPs = 100 - shareOfLP;
        console.log("shareOfPreviousLPs %s",shareOfPreviousLPs);
        
        LPTokensToMint = 100 * shareOfLP / shareOfPreviousLPs; 
        console.log("LPTokensToMint is %s tokens",LPTokensToMint);

        // uint256 shareOfLPs = (reservesTokenA + reservesTokenB / totalReserve) * 100;

    }

    function swap(address tokenFrom, uint256 amountFrom) public payable {
        address tokenTo = tokenFrom == tokenA ? tokenB : tokenA;

        uint256 amountOut = _getAmountOut(tokenFrom, amountFrom);

        IERC20(tokenFrom).transferFrom(msg.sender, address(this), amountFrom);
        IERC20(tokenTo).transfer(msg.sender, amountOut);
    }
}
