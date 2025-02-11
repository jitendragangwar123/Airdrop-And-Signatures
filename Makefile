-include .env


.PHONY: all test clean deploy fund help install snapshot format anvil


DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80


help:
   @echo "Usage:"
   @echo "  make deploy CONTRACT=<ContractName> [ARGS=...]\n    example: make deploy CONTRACT=DeploySENZ ARGS=\"--network sepolia\""
   @echo ""
   @echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""


all: clean remove install update build


# Clean the repo
clean:; forge clean


# Remove modules
remove:; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"


install:; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit


# Update Dependencies
update:; forge update


build:; forge build


test:; forge test -vvvv


snapshot:; forge snapshot


coverage:; forge coverage


format:; forge fmt


anvil:; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1


NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast


# make deploy CONTRACT=DeploySENZ ARGS="--network sepolia"
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
   NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv
endif


# make deploy CONTRACT=DeploySENZ ARGS="--network mainnet"
ifeq ($(findstring --network mainnet,$(ARGS)),--network mainnet)
   NETWORK_ARGS := --rpc-url $(MAINNET_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv
endif


deploy:
   @if [ -z "$(CONTRACT)" ]; then \
       echo "Error: CONTRACT variable not specified. Use make deploy CONTRACT=<ContractName> [ARGS=...]"; \
       exit 1; \
   else \
       forge script script/$(CONTRACT).s.sol:$(CONTRACT) $(NETWORK_ARGS); \
   fi
