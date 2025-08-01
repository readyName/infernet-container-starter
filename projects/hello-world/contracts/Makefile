# phony targets are targets that don't actually create a file
.PHONY: deploy

# anvil's third default address
sender := $PRIVATE_KEY
RPC_URL := $RPC_URL

# deploying the contract
deploy:
	@PRIVATE_KEY=$(sender) forge script script/Deploy.s.sol:Deploy --broadcast --rpc-url $(RPC_URL)

# calling sayGM()
call-contract:
	@PRIVATE_KEY=$(sender) forge script script/CallContract.s.sol:CallContract --broadcast --rpc-url $(RPC_URL)
