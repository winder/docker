.PHONY: algod clean algod-mainnet algod-rebuild algod-private

algod:
	docker build \
		-t algod_test \
		--build-arg CHANNEL=stable \
		algod
		#--build-arg URL \
		#--build-arg BRANCH \
		#--build-arg SHA \
		#--build-arg GO_VERSION \

algod-rebuild:
	docker build \
		-t algod_test \
		--build-arg CHANNEL=beta \
		--no-cache \
		algod

branch:
	docker build \
		-t algod_branch \
		--build-arg CHANNEL= \
		--build-arg URL=http://github.com/winder/go-algorand \
		--build-arg BRANCH=will/allow-empty-network-dir \
		--no-cache \
		algod

branch-private:
	docker run --rm -it \
		-p 4190:4190 \
		--name algod-branch-run \
		-v ${PWD}/data:/node/data/private_network/Node/ \
		-e TOKEN=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
		algod_branch

clean:
	docker rm algod_test

algod-mainnet:
	docker run --rm -it \
		-p 4190:4190 \
		--name algod-test-run \
		-e NETWORK=mainnet \
		-e FAST_CATCHUP=1 \
		-e TOKEN=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
		-v ${PWD}/data:/node/data \
		algod_test

algod-private:
	docker run --rm -it \
		-p 4190:4190 \
		--name algod-test-run \
		-e DEV_MODE=1 \
		-e TOKEN=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
		algod_test
		#-v ${PWD}/data:/node/data \
		#--user "$(shell id -u ):$(shell id -g )" \
