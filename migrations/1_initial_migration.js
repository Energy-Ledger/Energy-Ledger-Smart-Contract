// const Migrations = artifacts.require("Migrations");

const ELX = artifacts.require("contracts/ELX");
const SupplyChain = artifacts.require("contracts/SupplyChain");


module.exports = async function (deployer,network) {	

  // deployer.deploy(Migrations);
  await deployer.deploy(ELX);

  let ELX_instance = await ELX.deployed();

  /* Deploy supply chain contract, 1st parameter > tokenAddress, 2nd > Staking address */
  await deployer.deploy(SupplyChain,ELX_instance.address)

  let SupplyChain_instance = await SupplyChain.deployed();

  /* Set exchange rate 1 BNB = 1000 Elx*/
  await ELX_instance.setExchangeRate("1000000000000000000000");

  /* Approve contract address */
  await ELX_instance.approve(SupplyChain_instance.address,"115792089237316195423570985008687907853269984665640564039457584007913129639935");

  /* set supply chain address as a authorized caller */
  await ELX_instance.authorizeCaller(SupplyChain_instance.address);

  /* set action fees ex.add user, edit user */
  await SupplyChain_instance.setActionFee("25000000000000000000","5000000000000000000","5000000000000000000","1000000000000000000","1000000000000000000","1000000000000000000","1000000000000000000","1000000000000000000");

  /*ELX and supply chain instance authorize energy ledger address*/
   await ELX_instance.authorizeCaller("0xe322B6F81b7c35451EA3Ef190504521F0FC38C7E");
   await SupplyChain_instance.authorizeCaller("0xe322B6F81b7c35451EA3Ef190504521F0FC38C7E");

};
