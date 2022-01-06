# On-Chain Dynamic Merkle Tree

This project implements an on-chain dynamic Merkle tree library with some examples.  The key features are:
- efficient updating/appending a node in the tree with O(1) storage write cost;
- example javascript code to generate Merkle proof for updating/appending (in test/);
- examples of Merkelized Staking and Merkelized ERC20.


# To Play

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

# Cross L2 Bridge Example

This project implements an token transfer between two arbitrum instances using Dynamic Merkle Tree


## To Play

Try running some of the following tasks:

```shell
npm run arb_bridge_deploy
```

## Deployed Contracts on Arbitrum Testnet

- L1 Bridge: [0x972096D19c43aAdFaBA7C433bF33f34be568330F](https://rinkeby.etherscan.io/address/0x972096D19c43aAdFaBA7C433bF33f34be568330F#code)
- L2 Bridge Source: [0xc31dB9BC7d5bfD1e0aEBe936b20E025831bCb3Be](https://testnet.arbiscan.io/address/0xc31dB9BC7d5bfD1e0aEBe936b20E025831bCb3Be#code)
- L2 Bridge Destination: [0xa4f7e85327BE5648488844A85a00197af9ef136a](https://testnet.arbiscan.io/address/0xa4f7e85327BE5648488844A85a00197af9ef136a#code)
- L2 Token Source: [0x1158F18eFe4DAF4e71b31b077b340927A8A9f5Ef](https://testnet.arbiscan.io/address/0x1158F18eFe4DAF4e71b31b077b340927A8A9f5Ef#code)
- L2 Token Destination: [0x68e7155dF845635DF488fdED81BFC76C8210FBB2](https://testnet.arbiscan.io/address/0x68e7155dF845635DF488fdED81BFC76C8210FBB2#code)


## Deployed Contracts on Optimism Testnet

- L1 Bridge: [0x5095135E861845dee965141fEA9061F38C85c699](https://kovan.etherscan.io/address/0x5095135E861845dee965141fEA9061F38C85c699#code)
- L2 Bridge Source: [0x5095135E861845dee965141fEA9061F38C85c699](https://kovan-optimistic.etherscan.io/address/0x5095135E861845dee965141fEA9061F38C85c699#code)
- L2 Bridge Destination: [0xcC3C762734E54F65c7597Db7c479164fC6C3dFA0](https://kovan-optimistic.etherscan.io/address/0xcC3C762734E54F65c7597Db7c479164fC6C3dFA0#code)
- L2 Token Source: [0xd36AD433b356b304442d23b884bed706Cdf49583](https://kovan-optimistic.etherscan.io/address/0xd36AD433b356b304442d23b884bed706Cdf49583#code)
- L2 Token Destination: [0xB515eb506C43C468F616fa0Ad9BD4B94B90B71e9](https://kovan-optimistic.etherscan.io/address/0xB515eb506C43C468F616fa0Ad9BD4B94B90B71e9#code)


# Disclaimer
The code is not audited.  USE AT YOUR OWN RISK.

