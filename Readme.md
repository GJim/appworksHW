# AppworksHW

### Clone project
```
git clone --recurse-submodules https://github.com/GJim/appworksHW.git
```

### HW6
```shell
cd HW6
# test weth
forge test --mc WETHTest -vvvv
# test bayc
forge test --mc BAYCTest -vvvv

# deploy on devnet(anvil)
anvil
# copy private key into .env
forge script script/WETH.s.sol:WETHScript --rpc-url http://localhost:8545 --broadcast --verify -vvvv
# use send to mint weth token with interative
cast send 0x5fbdb2315678afecb367f032d93f642f64180aa3 "deposit()" --value 10ether -i
# call total supply with private key
cast call 0x5fbdb2315678afecb367f032d93f642f64180aa3 "totalSupply()(uint256)" --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

### HW7
```shell
cd HW7
# test question 1
forge test --mc Receiver -vvvv
# test question 2
forge test --mc RNDNFT -vvvv
```

### HW8
```shell
cd HW8
# test question 1
forge test --mc TradingCenter -vvvv
# test question 2
forge test --mc USDCv3 -vvvv
# Experimental implementation (solmate ERC20 & MultiRolesAuthority)
forge test --mc USDCv2 -vvvv
```