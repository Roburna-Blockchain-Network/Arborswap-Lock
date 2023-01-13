const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking", function () {

  before(async function () {
    
    this.Factory = await ethers.getContractFactory("LockFactory")
    this.VestingLock = await ethers.getContractFactory("VestingLockDividendsAndReflections")
    this.NormalLock = await ethers.getContractFactory("TokenLockDividendsAndReflections")
    this.StakingToken = await ethers.getContractFactory("StakingToken")
    this.Admin = await ethers.getContractFactory("Admin")
    this.signers = await ethers.getSigners()
    this.owner = this.signers[0]
    this.vault1 = this.signers[5]
    this.vault2 = this.signers[3]
    this.farm = this.signers[4]
    this.alice = this.signers[2]
    this.bob = this.signers[1]
    this.charlie = this.signers[6]
    this.provider = await ethers.provider
    
    
  

    this.stakingToken = await this.StakingToken.deploy()
    await this.stakingToken.deployed() 

    this.divToken = await this.StakingToken.deploy()
    await this.divToken.deployed() 
    
    this.admin = await this.Admin.deploy([this.owner.address])
    await this.admin.deployed()

    this.factory = await this.Factory.deploy(this.admin.address)
    await this.factory.deployed()
  
    this.vestingLock = await this.VestingLock.deploy(
        this.owner.address, 
        1, 
        ethers.utils.parseEther("100000"), 
        this.stakingToken.address, 
        10,
        9,
        10,
        'logo',
        true);
    await this.vestingLock.deployed()   

    this.normalLock = await this.NormalLock.deploy(
        this.owner.address,
        1,
        ethers.utils.parseEther("100000"),
        this.stakingToken.address, 
        'logo',
        true
        )
    await this.normalLock.deployed()

    

  })

  it("Only reward lock works ", async function () {
    await this.stakingToken.approve(this.factory.address, ethers.utils.parseEther("100000"))
    await this.stakingToken.transfer(this.normalLock.address, ethers.utils.parseEther("100000"))
    await this.normalLock.withdrawDividends(this.divToken.address);
    await this.normalLock.withdrawReflections();
    const factory = await this.normalLock.lockFactory();
    console.log(factory)
    console.log(this.owner.address)
  })

  it("Deploy from factory", async function () {
    await this.stakingToken.approve(this.factory.address, ethers.utils.parseEther("100000"))
    await this.factory.createTokenLock(
        this.owner.address, 
        this.stakingToken.address, 
        ethers.utils.parseEther("10000"),
        1,
        'logo'
        );

    await this.factory.createRewardTokenLock(
        this.owner.address, 
        this.stakingToken.address, 
        ethers.utils.parseEther("10000"),
        1,
        'logo'
        );    
    
  })

  



})  