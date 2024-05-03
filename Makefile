# DEPENDENCIES:
#
# forge
# https://github.com/foundry-rs/foundry 
#
# jq
# brew install jq

SHELL := /bin/bash

ANVIL_RPC:=http://localhost:8545

ANVIL_WALLET:=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
ANVIL_WALLET_PRIVATE_KEY:=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

ANVIL_CONTRACT_ADDRESS:=$(shell cat secrets/anvil_contract_address.txt)

WETH_CONTRACT_ADDRESS:=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

FUNDING_AMOUNT:="2.035 ether"
WITHDRAW_AMOUNT:="1.035 ether"
WRAP_AMOUNT:="0.5 ether"
UNWRAP_AMOUNT:=500000000000000000

PEPE_CONTRACT_ADDRESS:=0x6982508145454Ce325dDbE47a25d4ec3d2311933
PEPE_WHALE_ADDRESS:=0xF977814e90dA44bFA03b6295A0616a897441aceC

DAI=0x6b175474e89094c44da98b954eedeac495271d0f
DAI_HOST=0xfc2eE3bD619B7cfb2dE2C797b96DeeCbD7F68e46

print_anvil_rpc:
	@echo ${ANVIL_RPC}

print_anvil_wallet:
	@echo ${ANVIL_WALLET}

print_anvil_wallet_private_key:
	@echo ${ANVIL_WALLET_PRIVATE_KEY}

anvil_create_contract:
	forge create --constructor-args ${WETH_CONTRACT_ADDRESS} -r ${ANVIL_RPC} --optimize --private-key ${ANVIL_WALLET_PRIVATE_KEY} --json src/Contract.sol:Vault | jq -r '.deployedTo' | cat > secrets/anvil_contract_address.txt

anvil_fund_vault:
	cast send --value ${FUNDING_AMOUNT} -r ${ANVIL_RPC} ${ANVIL_CONTRACT_ADDRESS} "depositETH()" --from ${ANVIL_WALLET} --private-key ${ANVIL_WALLET_PRIVATE_KEY}

anvil_withdraw_eth:
	cast send -r ${ANVIL_RPC} ${ANVIL_CONTRACT_ADDRESS} "withdrawETH(uint256)" ${WITHDRAW_AMOUNT} --from ${ANVIL_WALLET} --private-key ${ANVIL_WALLET_PRIVATE_KEY}

anvil_get_vault_balance_on_weth_contract:
	cast call -r ${ANVIL_RPC} ${WETH_CONTRACT_ADDRESS} "balanceOf(address)(uint256)" ${ANVIL_CONTRACT_ADDRESS}

anvil_get_eth_balance:
	@result=`cast call -r ${ANVIL_RPC} ${ANVIL_CONTRACT_ADDRESS} "ethBalances(address)" ${ANVIL_WALLET}`; cast to-unit $$result ether;

anvil_wrap_eth:
	cast send -r ${ANVIL_RPC} ${ANVIL_CONTRACT_ADDRESS} "wrapETH(uint256)" ${WRAP_AMOUNT} --from ${ANVIL_WALLET} --private-key ${ANVIL_WALLET_PRIVATE_KEY}

anvil_unwrap_weth:
	cast send -r ${ANVIL_RPC} ${ANVIL_CONTRACT_ADDRESS} "unwrapWETH(uint256)" ${WRAP_AMOUNT} --from ${ANVIL_WALLET} --private-key ${ANVIL_WALLET_PRIVATE_KEY}

anvil_get_weth_balance:
	@result=`cast call -r ${ANVIL_RPC} ${ANVIL_CONTRACT_ADDRESS} "getTokenBalance(address, address)" ${WETH_CONTRACT_ADDRESS} ${ANVIL_WALLET}  --from ${ANVIL_WALLET}`; cast to-unit $$result;

anvil_setup_dai_in_wallet:
	cast rpc anvil_impersonateAccount ${DAI_HOST}
	cast send ${DAI} --from ${DAI_HOST} "transfer(address,uint256)(bool)" ${ANVIL_WALLET} 300000000000000000000000 --unlocked
	cast rpc anvil_impersonateAccount ${DAI_HOST}
	cast send ${DAI} --from ${ANVIL_WALLET} "approve(address,uint256)(bool)" ${ANVIL_CONTRACT_ADDRESS} 300000000000000000000000 --unlocked

anvil_get_dai_wallet_balance:
	cast call ${DAI} "balanceOf(address)(uint256)" ${ANVIL_WALLET}

anvil_deposit_dai:
	cast send -r ${ANVIL_RPC} ${ANVIL_CONTRACT_ADDRESS} "depositTokens(address, uint256)" ${DAI} 3 --from ${ANVIL_WALLET} --private-key ${ANVIL_WALLET_PRIVATE_KEY}

anvil_get_dai_balance:
	@result=`cast call -r ${ANVIL_RPC} ${ANVIL_CONTRACT_ADDRESS} "getTokenBalance(address, address)" ${DAI} ${ANVIL_WALLET}  --from ${ANVIL_WALLET}`; cast to-unit $$result;

anvil_setup_pepe_in_wallet:
	cast rpc anvil_impersonateAccount ${PEPE_WHALE_ADDRESS}
	cast send ${PEPE_CONTRACT_ADDRESS} --from ${PEPE_WHALE_ADDRESS} "transfer(address,uint256)(bool)" ${ANVIL_WALLET} 300000000000000000000000 --unlocked
	cast rpc anvil_impersonateAccount ${PEPE_WHALE_ADDRESS}
	cast send ${PEPE_CONTRACT_ADDRESS} --from ${ANVIL_WALLET} "approve(address,uint256)(bool)" ${ANVIL_CONTRACT_ADDRESS} 300000000000000000000000 --unlocked

anvil_get_pepe_wallet_balance:
	cast call ${PEPE_CONTRACT_ADDRESS} "balanceOf(address)(uint256)" ${ANVIL_WALLET}

anvil_deposit_pepe:
	cast send -r ${ANVIL_RPC} ${ANVIL_CONTRACT_ADDRESS} "depositTokens(address, uint256)" ${PEPE_CONTRACT_ADDRESS} 300000000000000000000000 --from ${ANVIL_WALLET} --private-key ${ANVIL_WALLET_PRIVATE_KEY}

anvil_get_pepe_balance:
	@result=`cast call -r ${ANVIL_RPC} ${ANVIL_CONTRACT_ADDRESS} "getTokenBalance(address, address)" ${PEPE_CONTRACT_ADDRESS} ${ANVIL_WALLET}  --from ${ANVIL_WALLET}`; cast to-unit $$result;

anvil_deposit_weth_direct:
	cast send --value ${WRAP_AMOUNT} -r ${ANVIL_RPC} ${WETH_CONTRACT_ADDRESS} "deposit(uint256)" ${WRAP_AMOUNT} --from ${ANVIL_WALLET} --private-key ${ANVIL_WALLET_PRIVATE_KEY}

anvil_get_weth_balance_direct:
	cast call -r ${ANVIL_RPC} ${WETH_CONTRACT_ADDRESS} "balanceOf(address)(uint256)" ${ANVIL_WALLET}

anvil_withdraw_weth_direct:
	cast send -r ${ANVIL_RPC} ${WETH_CONTRACT_ADDRESS} "withdraw(uint256)" ${WRAP_AMOUNT} --from ${ANVIL_WALLET} --private-key ${ANVIL_WALLET_PRIVATE_KEY}

estimate_gas_cost_contract_creation:
	@cast estimate --create $$(forge inspect src/Contract.sol:Vault bytecode)

clean:
	rm -rf target out cache

test:
	forge test --gas-report

# This will stop make linking directories with these names to make commands
.PHONY: all test clean
