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

describe("MerklizedStaking", function () {
  it("Stake", async function () {
    const Tree = await ethers.getContractFactory("DynamicMerkleTree");
    const tree = await Tree.deploy();
    await tree.deployed();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy();
    await token.deployed();

    const Staking = await ethers.getContractFactory("MerklizedStaking", {
      libraries: {
        DynamicMerkleTree: tree.address,
      },
    });
    const staking = await Staking.deploy(token.address);
    await staking.deployed();

    let nodes = [];
    expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));
    const [acc0, acc1, acc2, acc3, acc4] = await ethers.getSigners();

    // append acc0 with 1000 tokens
    await token.mint(acc0.address, 1000);
    await token.approve(staking.address, 1000);
    await staking.stake(1000, get_append_proof(nodes));
    nodes.push([
      { t: "uint256", v: acc0.address },
      { t: "uint256", v: 1000 },
    ]);
    expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));

    // append acc1 with 2000 tokens
    await token.mint(acc1.address, 2000);
    await token.connect(acc1).approve(staking.address, 2000);
    await staking.connect(acc1).stake(2000, get_append_proof(nodes));

    nodes.push([
      { t: "uint256", v: acc1.address },
      { t: "uint256", v: 2000 },
    ]);
    expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));

    // append acc2 with 3000 tokens
    await token.mint(acc2.address, 3000);
    await token.connect(acc2).approve(staking.address, 3000);
    await staking.connect(acc2).stake(3000, get_append_proof(nodes));

    nodes.push([
      { t: "uint256", v: acc2.address },
      { t: "uint256", v: 3000 },
    ]);
    expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));

    // update acc1 with 1000 tokens
    await token.mint(acc1.address, 1000);
    await token.connect(acc1).approve(staking.address, 1000);
    await staking.connect(acc1).stake(1000, get_update_proof(nodes, 1));

    nodes[1] = [
      { t: "uint256", v: acc1.address },
      { t: "uint256", v: 3000 },
    ];
    expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));

    // update acc2 with 2000 tokens
    await token.mint(acc2.address, 2000);
    await token.connect(acc2).approve(staking.address, 2000);
    await staking.connect(acc2).stake(2000, get_update_proof(nodes, 2));

    nodes[2] = [
      { t: "uint256", v: acc2.address },
      { t: "uint256", v: 5000 },
    ];
    expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));

    // unstake acc0
    await staking.connect(acc0).unstake(get_update_proof(nodes, 0));
    nodes[0] = [
      { t: "uint256", v: acc0.address },
      { t: "uint256", v: 0 },
    ];
    expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));
    expect(await token.balanceOf(acc0.address)).to.equal(1000);

    // stake acc0 again
    await token.connect(acc0).approve(staking.address, 500);
    await staking.connect(acc0).stake(500, get_update_proof(nodes, 0));
    nodes[0] = [
      { t: "uint256", v: acc0.address },
      { t: "uint256", v: 500 },
    ];
    expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));
    expect(await token.balanceOf(acc0.address)).to.equal(500);
  });

  it("Stake 20", async function () {
    const Tree = await ethers.getContractFactory("DynamicMerkleTree");
    const tree = await Tree.deploy();
    await tree.deployed();

    const Token = await ethers.getContractFactory("TestERC20");
    const token = await Token.deploy();
    await token.deployed();

    const Staking = await ethers.getContractFactory("MerklizedStaking", {
      libraries: {
        DynamicMerkleTree: tree.address,
      },
    });
    const staking = await Staking.deploy(token.address);
    await staking.deployed();

    let nodes = [];
    expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));
    for (let i = 0; i < 20; i++) {
      let acc = await ethers.getSigner(i);
      await token.mint(acc.address, i + 100);
      await token.connect(acc).approve(staking.address, i + 100);
      await staking.connect(acc).stake(i + 100, get_append_proof(nodes));

      nodes.push([
        { t: "uint256", v: acc.address },
        { t: "uint256", v: i + 100 },
      ]);
      expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));
    }

    expect(await staking.rootHash()).to.equal(calc_root_hash(nodes));
  });
});
