// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Pool.sol";
import "./LPToken.sol";

contract PoolFactory {
    address public LPTokenAddress;
    address[] public pools;

    constructor() {
        LPToken LP = new LPToken();
        LPTokenAddress = address(LP);
    }

    function createPool(address tokenA, address tokenB) public payable {
        Pool newPool = new Pool(tokenA, tokenB, LPTokenAddress);
        pools.push(address(newPool));
    }

    function getPools() public view returns (address[] memory) {
        return pools;
    }
}
