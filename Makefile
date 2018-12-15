
browser=$(PWD)/browser

UPDATE_URL=https://www.torproject.org/projects/torbrowser/RecommendedTBBVersions

#COMMENT THE FOLLOWING LINE IF YOU WANT TO USE THE EXPERIMENTAL TBB
#BROWSER_VERSION = $(shell curl $(UPDATE_URL) 2> /dev/null | grep -vi macos | grep -vi windows | grep -vi linux | head -n 2 | tail -n 1 | tr -d '",')

#UNCOMMENT THE FOLLOWING LINES IF YOU WANT TO USE THE EXPERIMENTAL TBB
#BROWSER_VERSION=8.0a10

DEFAULT_SOCKS_PORT=9150
DEFAULT_CONTROL_PORT=9151
DEFAULT_HOST=172.70.70.2
DEFAULT_BROWSER=172.70.70.3

TOR_SOCKS_PORT?=$(DEFAULT_SOCKS_PORT)
TOR_SOCKS_HOST?=$(DEFAULT_HOST)

TOR_CONTROL_PORT?=$(DEFAULT_CONTROL_PORT)
TOR_CONTROL_HOST?=$(DEFAULT_HOST)

DISPLAY = :0

build: echo docker-torhost docker-browser

update: echo docker-clobber-torhost docker-torhost docker-clobber-browser docker-browser

echo:
	@echo "Building variant: $(PORT)"
	@echo "$(BROWSER_VERSION) $(browser)"

network:
	docker network create --subnet 172.70.70.0/29 tbb; true

docker-browser: network
	docker build --force-rm \
		--build-arg TOR_SOCKS_PORT="$(TOR_SOCKS_PORT)" \
		--build-arg TOR_SOCKS_HOST="$(TOR_SOCKS_HOST)" \
		--build-arg TOR_CONTROL_PORT="$(TOR_CONTROL_PORT)" \
		--build-arg TOR_CONTROL_HOST="$(TOR_CONTROL_HOST)" \
		-f Dockerfile -t eyedeekay/tor-browser .

docker-torhost: network
	docker build --force-rm \
		--build-arg TOR_SOCKS_PORT="$(TOR_SOCKS_PORT)" \
		--build-arg TOR_SOCKS_HOST="$(TOR_SOCKS_HOST)" \
		--build-arg TOR_CONTROL_PORT="$(TOR_CONTROL_PORT)" \
		--build-arg TOR_CONTROL_HOST="$(TOR_CONTROL_HOST)" \
		-f Dockerfile.torhost -t eyedeekay/tor-host .

torhost: echo docker-torhost network
	docker run --rm -i -t -d \
		--user tor \
		--net tbb \
		--name tor-host \
		--hostname tor-host \
		--link tor-host \
		--ip $(DEFAULT_HOST) \
		--volume tor-host:/var \
		eyedeekay/tor-host; true

browse: echo docker-browser torhost network docker-clean-browser
	docker run --rm -i -t \
		-e DISPLAY=$(DISPLAY) \
		--net tbb \
		--name tor-browser \
		--hostname tor-browser \
		--link tor-host \
		--ip $(DEFAULT_BROWSER) \
		--volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
		--volume $(browser):/home/anon/tor-browser_en-US/Browser/Desktop \
		eyedeekay/tor-browser

anti-douchelord: docker-snowflake snowflake

docker-snowflake: docker-snowflake-client

docker-snowflake-client:
	docker build -f Dockerfile.snowflake-server \
		-t eyedeekay/snowflake-server .

snowflake:

docker-clean-browser:
	docker rm -f tor-browser; true

docker-clean-host:
	docker rm -f tor-host; true

docker-clobber-browser: docker-clean-browser
	docker rmi -f eyedeekay/tor-browser; true

docker-clobber-host: docker-clean-host
	docker rmi -f eyedeekay/tor-host; true

docker-clean: docker-clean-browser docker-clean-host

docker-clobber: docker-clobber-browser docker-clobber-host

i2p:
		docker run --rm -i -t \
		-e DISPLAY=$(DISPLAY) \
		-e BROWSER_VERSION="$(BROWSER_VERSION)" \
		--net host \
		--name tb-profile-i2p \
		--hostname tb-profile-i2p \
		--volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
		eyedeekay/tb-profile-i2p
