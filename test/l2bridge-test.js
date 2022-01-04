const { web3 } = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

function calc_root_hash(nodes) {
  hl = nodes.map((x) => web3.utils.soliditySha3(...x));

  if (hl.length == 0) {
    return "0x0000000000000000000000000000000000000000000000000000000000000000";
  }

  while (hl.length > 1) {
    let nhl = [];
    for (let i = 0; i < hl.length; i += 2) {
      nhl.push(
        web3.utils.soliditySha3(
          { t: "uint256", v: hl[i] },
          {
            t: "uint256",
            v:
              i + 1 < hl.length
                ? hl[i + 1]
                : "0x0000000000000000000000000000000000000000000000000000000000000000",
          }
        )
      );
    }

    hl = nhl;
  }

  return hl[0];
}

function get_update_proof(nodes, idx) {
  hl = nodes.map((x) => web3.utils.soliditySha3(...x));
  if (idx == hl.length) {
    // append
    hl.push(
      "0x0000000000000000000000000000000000000000000000000000000000000000"
    );
  }
  let proof = [];

  while (hl.length > 1 || idx != 0) {
    nidx = Math.floor(idx / 2) * 2;
    if (nidx == idx) {
      nidx += 1;
    }

    if (nidx < hl.length) {
      proof.push(hl[nidx]);
    }

    let nhl = [];
    for (let i = 0; i < hl.length; i += 2) {
      let left = hl[i];
      let right =
        i + 1 < hl.length
          ? hl[i + 1]
          : "0x0000000000000000000000000000000000000000000000000000000000000000";
      nhl.push(web3.utils.soliditySha3(left, right));
    }

    hl = nhl;
    idx = Math.floor(idx / 2);
  }

  return proof;
}

function get_append_proof(nodes) {
  return get_update_proof(nodes, nodes.length);
}

describe("L2Bridge", function () {
  it("simple l2bridge deposit/buy/withdraw test", async function () {
    const Tree = await ethers.getContractFactory("DynamicMerkleTree");
    const tree = await Tree.deploy();
    await tree.deployed();

    const BridgeSource = await ethers.getContractFactory("TestL2BridgeSource", {
      libraries: {
        DynamicMerkleTree: tree.address,
      },
    });
    const bridgeSrc = await BridgeSource.deploy();
    await bridgeSrc.deployed();

    const Token = await ethers.getContractFactory("TestERC20");
    const tokenSrc = await Token.deploy();
    await tokenSrc.deployed();

    const tokenDst = await Token.deploy();
    await tokenDst.deployed();

    const BridgeDestination = await ethers.getContractFactory(
      "L2BridgeDestination",
      {
        libraries: {
          DynamicMerkleTree: tree.address,
        },
      }
    );
    const bridgeDst = await BridgeDestination.deploy();
    await bridgeDst.deployed();

    const [acc0, acc1, acc2, acc3, acc4] = await ethers.getSigners();

    await tokenSrc.mint(acc0.address, 10000);
    await tokenSrc.approve(bridgeSrc.address, 10000);

    let xferData = {
      srcTokenAddress: tokenSrc.address,
      dstTokenAddress: tokenDst.address,
      destination: acc1.address,
      amount: 1000,
      fee: 0,
      startTime: 0,
      feeRampup: 0,
      expiration: 100000000000, // not expire
    };

    await bridgeSrc.deposit(xferData);

    let nodes = [];
    await tokenDst.mint(acc2.address, 1000);
    await tokenDst.connect(acc2).approve(bridgeDst.address, 1000);
    await bridgeDst.connect(acc2).buy(xferData, get_append_proof(nodes));

    nodes.push([
      { t: "uint256", v: await bridgeSrc.getReceiptHash(xferData) },
      { t: "uint256", v: 10000 },
    ]);

    await bridgeSrc.updateReceiptRoot(await bridgeDst.receiptRoot());
    await bridgeSrc
      .connect(acc2)
      .withdraw(xferData, 0, 1, get_update_proof(nodes, 0));

    expect(await tokenDst.balanceOf(acc1.address)).to.equal(1000);
    expect(await tokenSrc.balanceOf(acc2.address)).to.equal(1000);
  });

  it("simple l2bridge deposit/expire test", async function () {
    const Tree = await ethers.getContractFactory("DynamicMerkleTree");
    const tree = await Tree.deploy();
    await tree.deployed();

    const BridgeSource = await ethers.getContractFactory("TestL2BridgeSource", {
      libraries: {
        DynamicMerkleTree: tree.address,
      },
    });
    const bridgeSrc = await BridgeSource.deploy();
    await bridgeSrc.deployed();

    const Token = await ethers.getContractFactory("TestERC20");
    const tokenSrc = await Token.deploy();
    await tokenSrc.deployed();

    const tokenDst = await Token.deploy();
    await tokenDst.deployed();

    const BridgeDestination = await ethers.getContractFactory(
      "L2BridgeDestination",
      {
        libraries: {
          DynamicMerkleTree: tree.address,
        },
      }
    );
    const bridgeDst = await BridgeDestination.deploy();
    await bridgeDst.deployed();

    const [acc0, acc1, acc2, acc3, acc4] = await ethers.getSigners();

    await tokenSrc.mint(acc0.address, 10000);
    await tokenSrc.approve(bridgeSrc.address, 10000);

    let xferData = {
      srcTokenAddress: tokenSrc.address,
      dstTokenAddress: tokenDst.address,
      destination: acc1.address,
      amount: 1000,
      fee: 0,
      startTime: 0,
      feeRampup: 0,
      expiration: 0, // any time expire
    };

    await bridgeSrc.deposit(xferData);

    await bridgeSrc.refund(xferData);

    expect(await tokenSrc.balanceOf(acc1.address)).to.equal(1000);
  });
});
