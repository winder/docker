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
		--build-arg BRANCH=will/create-logging-in-data \
		--no-cache \
		algod

branch-mainnet:
	docker run --rm -it \
		-p 4190:8080 \
		--name algod-branch-run \
		-v ${PWD}/data:/algod/data/ \
		-e NETWORK=mainnet \
		-e FAST_CATCHUP=1 \
		-e TOKEN=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
		algod_branch

branch-private:
	docker run --rm -it \
		-p 4190:8080 \
		--name algod-branch-run \
		-e TOKEN=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
		-e ADMIN_TOKEN=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
		-e NETWORK_NUM_ROUNDS=30001 \
		-v ${PWD}/data:/algod/ \
		algod_branch

clean:
	docker rm algod_test

algod-mainnet:
	docker run --rm -it \
		-p 4190:8080 \
		--name algod-test-run \
		-e NETWORK=mainnet \
		-e FAST_CATCHUP=1 \
		-e TOKEN=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
		-v ${PWD}/data:/algod/data \
		algod_test

algod-private:
	docker run --rm -it \
		-p 4190:8080 \
		--name algod-test-run \
		-e DEV_MODE=1 \
		-e TOKEN=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
		algod_test
		#-v ${PWD}/data:/algod/data \
		#--user "$(shell id -u ):$(shell id -g )" \
