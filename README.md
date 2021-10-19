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

# Disclaimer
The code is not audited.  USE AT YOUR OWN RISK.

