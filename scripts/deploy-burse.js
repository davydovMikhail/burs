const { parseEther } = require("ethers/lib/utils");

async function main() {
    const primaryTokenPrice = parseEther("0.00001");
    const primaryTradingVolume = parseEther("1");
    const roundDuration = 259200;
    const addressToken = '0xA994773AA6ea0E3b7Cfa3110702a486d99500D67';

    console.log(primaryTokenPrice, primaryTradingVolume, roundDuration, addressToken);

    const Burse = await ethers.getContractFactory("Burse");
    const burse = await Burse.deploy(primaryTokenPrice, primaryTradingVolume, roundDuration, addressToken);
    console.log("Burse address:", burse.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });