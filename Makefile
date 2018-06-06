
browser=$(PWD)/browser

UPDATE_URL=https://www.torproject.org/projects/torbrowser/RecommendedTBBVersions

#COMMENT THE FOLLOWING LINE IF YOU WANT TO USE THE EXPERIMENTAL TBB
BROWSER_VERSION=$(shell curl $(UPDATE_URL) 2> /dev/null | head -n 2 | tail -n 1 | tr -d '",')

#UNCOMMENT THE FOLLOWING LINES IF YOU WANT TO USE THE EXPERIMENTAL TBB
#BROWSER_VERSION=8.0a7
#BROWSER_VERSION=0.0.16

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
	docker network create --subnet 255.255.255.248/29 tbb; true

docker-browser: network
	docker build --force-rm \
		--build-arg BROWSER_VERSION="$(BROWSER_VERSION)" \
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
		--net tbb \
		--name tor-host \
		--hostname tor-host \
		--link tor-host \
		--ip $(DEFAULT_HOST) \
		eyedeekay/tor-host

browse: echo docker-browser torhost network docker-clean-host
	docker run --rm -i -t -d \
		-e DISPLAY=$(DISPLAY) \
		-e BROWSER_VERSION="$(BROWSER_VERSION)" \
		--net tbb \
		--name tor-browser \
		--hostname tor-browser \
		--link tor-host \
		--ip $(DEFAULT_BROWSER) \
		--volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
		--volume $(browser):/home/anon/tor-browser_en-US/Browser/Desktop \
		eyedeekay/tor-browser

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
