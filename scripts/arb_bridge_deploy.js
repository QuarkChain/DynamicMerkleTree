const hre = require("hardhat");
const ethers = require("ethers");
const { Bridge } = require("arb-ts");
const { hexDataLength } = require("@ethersproject/bytes");
const { arbLog, requireEnvVariables } = require("arb-shared-dependencies");
requireEnvVariables(["DEVNET_PRIVKEY", "L2RPC", "L1RPC", "INBOX_ADDR"]);

/**
 * Instantiate wallets and providers for bridge
 */

const walletPrivateKey = process.env.DEVNET_PRIVKEY;

const l1Provider = new ethers.providers.JsonRpcProvider(process.env.L1RPC);
const l2Provider = new ethers.providers.JsonRpcProvider(process.env.L2RPC);
const signer = new ethers.Wallet(walletPrivateKey);

const l1Signer = signer.connect(l1Provider);
const l2Signer = signer.connect(l2Provider);

const main = async () => {
  await arbLog("Cross-chain L2 Bridge");
  /**
   * Use wallets to create an arb-ts bridge instance to use its convenience methods
   */
  const bridge = await Bridge.init(l1Signer, l2Signer);

  /**
   * We deploy L1 Bridge to L1, L2 Bridge (source and destination) to L2.
   */

  const L1Bridge = await (
    await hre.ethers.getContractFactory("ArbitrumL1Bridge")
  ).connect(l1Signer); //
  console.log("Deploying L1 Bridge 👋");
  const l1Bridge = await L1Bridge.deploy(
    ethers.constants.AddressZero, // temp l2 addr
    ethers.constants.AddressZero, // temp l2 addr
    process.env.INBOX_ADDR
  );
  await l1Bridge.deployed();
  console.log(`deployed to ${l1Bridge.address}`);

  const L2BridgeSrc = await (
    await hre.ethers.getContractFactory("ArbitrumBridgeSource")
  ).connect(l2Signer);

  console.log("Deploying L2 Bridge Source 👋👋");

  const l2BridgeSrc = await L2BridgeSrc.deploy(
    ethers.constants.AddressZero // temp l1 addr
  );
  await l2BridgeSrc.deployed();
  console.log(`deployed to ${l2BridgeSrc.address}`);

  const L2BridgeDst = await (
    await hre.ethers.getContractFactory("ArbitrumBridgeDestination")
  ).connect(l2Signer);

  console.log("Deploying L2 Bridge Destination 👋👋");

  const l2BridgeDst = await L2BridgeDst.deploy(
    ethers.constants.AddressZero // temp l1 addr
  );
  await l2BridgeDst.deployed();
  console.log(`deployed to ${l2BridgeDst.address}`);

  const updateL1TxForSrc = await l1Bridge.updateL2Source(l2BridgeSrc.address);
  await updateL1TxForSrc.wait();
  const updateL1TxForDst = await l1Bridge.updateL2Target(l2BridgeDst.address);
  await updateL1TxForDst.wait();

  const updateL2SrcTx = await l2BridgeSrc.updateL1Target(l1Bridge.address);
  await updateL2SrcTx.wait();

  const updateL2DstTx = await l2BridgeDst.updateL1Target(l1Bridge.address);
  await updateL2DstTx.wait();

  const L2Token = await (
    await hre.ethers.getContractFactory("TestERC20WithName")
  ).connect(l2Signer);

  console.log("Deploying L2 Source Token 👋👋");

  const l2TokenSrc = await L2Token.deploy("SRC_TOKEN");
  await l2TokenSrc.deployed();
  console.log(`deployed to ${l2TokenSrc.address}`);

  console.log("Deploying L2 Destination Token 👋👋");

  const l2TokenDst = await L2Token.deploy("DST_TOKEN");
  await l2TokenDst.deployed();
  console.log(`deployed to ${l2TokenDst.address}`);

  console.log("Counterpart contract addresses set in all contracts 👍");
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
