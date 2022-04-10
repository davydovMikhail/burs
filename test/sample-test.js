const { expect } = require("chai");
const { ethers, waffle, hardhat } = require("hardhat");
const { parseEther } = require("ethers/lib/utils");
const provider = waffle.provider;

describe("burse", function () {
  beforeEach(async () => {
    [owner, user1, user2, user3, user4, user5, user6, user7] = await ethers.getSigners();
    TokenF = await ethers.getContractFactory("Token");
    BurseF = await ethers.getContractFactory("Burse");
    tokenACDM = await TokenF.connect(owner).deploy('Academy Token', 'ACDM');
    const primaryTokenPrice = parseEther("0.00001");
    const primaryTradingVolume = parseEther("1");
    roundDuration = 259200;
    burse = await BurseF.connect(owner).deploy(primaryTokenPrice, primaryTradingVolume, roundDuration, tokenACDM.address);
    await tokenACDM.connect(owner).setBurseAddress(burse.address);  
  })

  it("Referal programm", async function () {
    const nullAddress = '0x0000000000000000000000000000000000000000';
    await burse.connect(user7).startSaleRound();
    const firstBuy = 0.2;
    await expect(burse.connect(user1).register(nullAddress)).to.be.revertedWith('You entered null address');
    await expect(burse.connect(user1).register(user1.address)).to.be.revertedWith('You cannot refer yourself as a referral');
    await burse.connect(user1).register(user2.address);
    await expect(burse.connect(user1).register(user2.address)).to.be.revertedWith('You are registered yet');
    await burse.connect(user2).register(user3.address);
    const user2Before = await user2.getBalance();
    const user3Before = await user3.getBalance();
    await burse.connect(user1).buyAcdm({ value: parseEther(firstBuy.toString())});
    const user2After = await user2.getBalance();
    const user3After = await user3.getBalance();
    expect(+user2After).to.equal(+user2Before + +parseEther((`${firstBuy * 0.03}`)));
    expect(+user3After).to.equal(+user3Before + +parseEther((`${firstBuy * 0.02}`)));
    await ethers.provider.send("evm_increaseTime", [roundDuration]);
    await ethers.provider.send("evm_mine");
    await burse.connect(user7).startTradeRound();
    await tokenACDM.connect(user1).approve(burse.address, await tokenACDM.balanceOf(user1.address))
    await burse.connect(user1).addOrder(await tokenACDM.balanceOf(user1.address), parseEther('0.00005'))
    const id = 1;
    const order = await burse.orders(id)
    const valuePrice = (order.price * order.amount).toString();
    const user1BeforeRedeem = await user1.getBalance();
    const user2BeforeRedeem = await user2.getBalance();
    const user3BeforeRedeem = await user3.getBalance();
    await burse.connect(user4).redeemOrder(id, {value: valuePrice})
    const user1AfterRedeem = await user1.getBalance();
    const user2AfterRedeem = await user2.getBalance();
    const user3AfterRedeem = await user3.getBalance();
    expect(+user1AfterRedeem).to.equal(+user1BeforeRedeem + +valuePrice * 0.95);
    expect(+user2AfterRedeem).to.equal(+user2BeforeRedeem + +valuePrice * 0.025);
    expect(+user3AfterRedeem).to.equal(+user3BeforeRedeem + +valuePrice * 0.025);
  });

  it("Bidding", async function () {
    await burse.connect(user7).startSaleRound();
    const firstBuy = 0.2;
    const secondBuy = 0.3;
    const thirdBuy = 0.4;
    await expect(burse.connect(user1).buyAcdm()).to.be.revertedWith('You sent 0 ETH')
    await burse.connect(user1).buyAcdm({ value: parseEther(firstBuy.toString())})
    await burse.connect(user2).buyAcdm({ value: parseEther(secondBuy.toString())})
    await burse.connect(user3).buyAcdm({ value: parseEther(thirdBuy.toString())})
    await expect(burse.connect(user3).buyAcdm({ value: parseEther(thirdBuy.toString())})).to.be.revertedWith('You want to buy more tokens than we have')
    await expect(burse.connect(user7).startSaleRound()).to.be.revertedWith('The Sale mode can be set only after the end of the Trade mode')
    await expect(burse.connect(user7).startTradeRound()).to.be.revertedWith('Round sale while lasts')
    await ethers.provider.send("evm_increaseTime", [roundDuration])
    await ethers.provider.send("evm_mine")
    await expect(burse.connect(user4).buyAcdm({ value: parseEther('0.01')})).to.be.revertedWith('Round Sale Finished')
    await burse.connect(user7).startTradeRound()
    await expect(burse.connect(user7).startTradeRound()).to.be.revertedWith('The Trade mode can be set only after the end of the Sale mode')
    await expect(burse.connect(user7).startSaleRound()).to.be.revertedWith('Round trade while lasts')
    await tokenACDM.connect(user1).approve(burse.address, await tokenACDM.balanceOf(user1.address))
    await burse.connect(user1).addOrder(await tokenACDM.balanceOf(user1.address), parseEther('0.00005'))
    const id1 = 1;
    expect(await tokenACDM.balanceOf(user1.address)).to.be.equal(0)
    await tokenACDM.connect(user2).approve(burse.address, await tokenACDM.balanceOf(user2.address))
    await burse.connect(user2).addOrder(await tokenACDM.balanceOf(user2.address), parseEther('0.00004'))
    const id2 = 2;
    expect(await tokenACDM.balanceOf(user2.address)).to.be.equal(0)
    await tokenACDM.connect(user3).approve(burse.address, await tokenACDM.balanceOf(user3.address))
    await burse.connect(user3).addOrder(await tokenACDM.balanceOf(user3.address), parseEther('0.00003'))
    const id3 = 3;
    expect(await tokenACDM.balanceOf(user3.address)).to.be.equal(0)
    const order3 = await burse.orders(id3)
    await expect(burse.connect(user4).removeOrder(id3)).to.be.revertedWith('You are not the owner of this order')

    await burse.connect(user3).removeOrder(id3)
    await expect(burse.connect(user3).removeOrder(id3)).to.be.revertedWith('Order redemeed or removed')

    expect(await tokenACDM.balanceOf(user3.address)).to.be.equal(order3.amount)
    await expect(burse.connect(user1).buyAcdm({ value: parseEther("0.02")})).to.be.revertedWith('Wait for the sale mode to come')
    const order1 = await burse.orders(id1)
    const amountTokens1 = order1.amount * 0.5
    const valuePrice1 = (order1.price * amountTokens1).toString();
    await expect(burse.connect(user4).redeemOrder(id1, {value: parseEther('100')})).to.be.revertedWith('You sent more than the order price')
    await expect(burse.connect(user4).redeemOrder(id1)).to.be.revertedWith('You sent 0 ETH')

    await burse.connect(user4).redeemOrder(id1, {value: valuePrice1})
    expect(await tokenACDM.balanceOf(user4.address)).to.be.equal(amountTokens1)
    await ethers.provider.send("evm_increaseTime", [roundDuration])
    await ethers.provider.send("evm_mine")
    await burse.connect(user7).startSaleRound();

    await expect(burse.connect(user5).redeemOrder(id2, {value: valuePrice1})).to.be.revertedWith('Wait for the Trade mode to come')

    // await burse.connect(user5).redeemOrder(id2, {value: valuePrice1})

    await ethers.provider.send("evm_increaseTime", [roundDuration])
    await ethers.provider.send("evm_mine")
    await burse.connect(user7).startTradeRound();
  });
});
