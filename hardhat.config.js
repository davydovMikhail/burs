require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3");
require('solidity-coverage');
require('dotenv').config();
require("@nomiclabs/hardhat-etherscan");

const { API_URL, PRIVATE_KEY, ETH_API_KEY } = process.env;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 module.exports = {
  solidity: "0.8.4",
  networks: {
    rinkeby: {
      url: API_URL, 
      accounts: [`0x${PRIVATE_KEY}`]
    }
  },
  etherscan: {
    apiKey: ETH_API_KEY
  }
};
