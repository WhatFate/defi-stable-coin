
.PHONY: install test build clean fmt lint coverage help

install : 
	forge install cyfrin/foundry-devops@0.1.0 && forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 && forge install foundry-rs/forge-std@v1.5.3 && forge install openzeppelin/openzeppelin-contracts@v4.8.3

build: 
	@forge build

test:
	forge test -vvv

coverage:
	forge coverage --report lcov
	genhtml lcov.info --output-directory coverage

snapshot :
	@forge snapshot

fmt:
	@forge fmt

clean:
	@forge clean

anvil :
	 anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployDSC.s.sol:DeployDSC $(NETWORK_ARGS)
