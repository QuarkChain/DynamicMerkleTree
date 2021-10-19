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

describe("MerklizedERC20", function () {
  it("Mint/Transfer", async function () {
    const Tree = await ethers.getContractFactory("DynamicMerkleTree");
    const tree = await Tree.deploy();
    await tree.deployed();

    const Token = await ethers.getContractFactory("TestMerklizedERC20", {
      libraries: {
        DynamicMerkleTree: tree.address,
      },
    });
    const token = await Token.deploy();
    await token.deployed();

    let nodes = [];
    expect(await token.rootHash()).to.equal(calc_root_hash(nodes));
    const [acc0, acc1, acc2, acc3, acc4] = await ethers.getSigners();

    // Test mint
    await token.mint(acc0.address, 10000, get_append_proof(nodes));
    nodes.push([
      { t: "uint256", v: acc0.address },
      { t: "uint256", v: 10000 },
    ]);
    await token.mint(acc1.address, 20000, get_append_proof(nodes));
    nodes.push([
      { t: "uint256", v: acc1.address },
      { t: "uint256", v: 20000 },
    ]);

    // Test transfer to a new account
    var p0 = get_update_proof(nodes, 1);
    nodes[1][1].v = 19000;
    var p1 = get_append_proof(nodes);
    nodes.push([
      { t: "uint256", v: acc2.address },
      { t: "uint256", v: 1000 },
    ]);

    await token.connect(acc1).transferTo(acc2.address, 1000, p0, p1);

    // Test transfer to an existing account
    var p0 = get_update_proof(nodes, 2);
    nodes[2][1].v -= 500;
    var p1 = get_update_proof(nodes, 0);
    nodes[0][1].v += 500;

    await token.connect(acc2).transferTo(acc0.address, 500, p0, p1);
  });
});
