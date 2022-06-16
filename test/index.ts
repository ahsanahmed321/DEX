/* eslint-disable node/no-missing-import */
import { expect } from "chai";
import { ethers } from "hardhat";

import {
  PoolFactory__factory,
  ERC20Token__factory,
  PoolFactory,
  ERC20Token,
  Pool,
  LPToken,
} from "../typechain";

const PoolABI = require("../artifacts/contracts/Pool.sol/Pool.json");
const LPTokenABI = require("../artifacts/contracts/LPToken.sol/LPToken.json");
const ERC20TokenABI = require("../artifacts/contracts/ERC20Token.sol/ERC20Token.json");

describe("DEX", function () {
  let accounts: any;
  let PoolFactory: PoolFactory;
  let LPTokenAddress: string;
  let TokenA: ERC20Token;
  let TokenB: ERC20Token;
  let PoolAddress: string;

  beforeEach(async () => {
    accounts = await ethers.getSigners();

    PoolFactory = await new PoolFactory__factory(accounts[0]).deploy();
    LPTokenAddress = await PoolFactory.LPTokenAddress();

    TokenA = await new ERC20Token__factory(accounts[0]).deploy(
      ethers.utils.parseEther("5000"),
      "AHSAN",
      "AHS"
    );

    TokenB = await new ERC20Token__factory(accounts[0]).deploy(
      ethers.utils.parseEther("5000"),
      "KUMAIL",
      "KUM"
    );

    await PoolFactory.createPool(TokenA.address, TokenB.address);
    [PoolAddress] = await PoolFactory.getPools();
  });

  it("deploys a Factory, LPToken ,pool and Pool Tokens", async () => {
    expect(PoolFactory.address);
    expect(PoolAddress);
    expect(LPTokenAddress);
    expect(TokenA.address);
    expect(TokenB.address);
  });

  it("Add Liquidity and Swap", async () => {
    await TokenA.increaseAllowance(
      PoolAddress,
      ethers.utils.parseEther("1000")
    );
    await TokenB.increaseAllowance(
      PoolAddress,
      ethers.utils.parseEther("1000")
    );

    const PoolContract = new ethers.Contract(
      PoolAddress,
      PoolABI.abi,
      accounts[0]
    ) as Pool;

    await PoolContract.addLiquidity(
      TokenA.address,
      TokenB.address,
      ethers.utils.parseEther("50"),
      ethers.utils.parseEther("50")
    );

    const LPTokenContract = new ethers.Contract(
      LPTokenAddress,
      LPTokenABI.abi,
      accounts[0]
    ) as LPToken;
    const LPBalance = await LPTokenContract.balanceOf(accounts[0].address);

    console.log(ethers.utils.formatEther(LPBalance));
    console.log(ethers.utils.formatEther(await PoolContract.reservesTokenA()));
    console.log(ethers.utils.formatEther(await PoolContract.reservesTokenB()));

    await PoolContract.swap(TokenA.address, ethers.utils.parseEther("10"));

    const TokenAInstance = new ethers.Contract(
      TokenA.address,
      ERC20TokenABI.abi,
      accounts[0]
    );
    const TokenABalance = await TokenAInstance.balanceOf(accounts[0].address);

    const TokenBInstance = new ethers.Contract(
      TokenB.address,
      ERC20TokenABI.abi,
      accounts[0]
    );
    const TokenBBalance = await TokenBInstance.balanceOf(accounts[0].address);

    console.log(ethers.utils.formatEther(TokenABalance));
    console.log(ethers.utils.formatEther(TokenBBalance));

    console.log(ethers.utils.formatEther(await PoolContract.reservesTokenA()));
    console.log(ethers.utils.formatEther(await PoolContract.reservesTokenB()));
  });
});
