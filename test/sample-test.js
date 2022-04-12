const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("mintFlower", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Flower = await ethers.getContractFactory("Flower");
    const flower = await Flower.deploy();
    await flower.deployed();
    console.log(flower.address, 'miniCar address');
    console.log(await flower.mintFlower(), 'mint')
  });
});
