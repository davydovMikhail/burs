
async function main() {
  const name = 'Academy Token'
  const symbol = 'ACDM'
  const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy(name, symbol);
  console.log("Token address:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
      console.error(error);
      process.exit(1);
  });