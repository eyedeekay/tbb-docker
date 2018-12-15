# Dockerized Tor Browser Bundle

This is a set of Docker containers, one which runs Tor with a SocksPort,
ControlPort, and Cookie-based authentication, the other which runs a Tor Browser
Bundle configured to use the Tor-hosting docker container. This is an entirely
unofficial effort with no endorsement or guarantee from anyone, least of all
a reputable organization like the Tor Project.

Dockerfile 1: Tor Browser Bundle
================================

This dockerfile downloads and configures a Tor Browser Bundle from the latest
version recommended by the Tor Project. It makes the environment variables
that can configure the Tor Browser Bundle available to docker build and docker
run.

## Inherit base environment
        FROM debian:sid

## Set environment variables
        ARG TOR_CONTROL_HOST=127.0.0.1
        ARG TOR_CONTROL_PORT=9151
        ARG TOR_SOCKS_HOST=127.0.0.1
        ARG TOR_SOCKS_PORT=9150
        ARG TOR_FORCE_NET_CONFIG=0
        ARG TOR_SKIP_LAUNCH=1
        ARG TOR_SKIP_CONTROLPORTTEST=1
        ARG UPDATE_URL=https://www.torproject.org/projects/torbrowser/RecommendedTBBVersions
        ENV DEBIAN_FRONTEND=noninteractive \
            HOME=/home/anon \
            TOR_CONTROL_PORT=$TOR_CONTROL_PORT \
            TOR_CONTROL_HOST=$TOR_CONTROL_HOST \
            TOR_SOCKS_PORT=$TOR_SOCKS_PORT \
            TOR_SOCKS_HOST=$TOR_SOCKS_HOST \
            TOR_SKIP_LAUNCH=$TOR_SKIP_LAUNCH \
            TOR_SKIP_CONTROLPORTTEST=$TOR_SKIP_CONTROLPORTTEST \
            UPDATE_URL=https://www.torproject.org/projects/torbrowser/RecommendedTBBVersions

## Update the container(and add the Whonix repo? I don't think this is required.)
        RUN apt-get update && apt-get install -y gnupg curl xz-utils
        RUN apt-key --keyring /etc/apt/trusted.gpg.d/whonix.gpg adv --keyserver hkp://pool.sks-keyservers.net --recv-keys 916B8D99C38EAF5E8ADC7A2A8D66066A2EEACCDA
        RUN echo "deb http://deb.whonix.org stretch main" | tee /etc/apt/sources.list.d/whonix.list

## Install the necessary dependencies to use Firefox in the container.
        RUN apt-get update && \
            apt-get -y dist-upgrade && \
            sed -i.bak 's/sid main/sid main contrib/g' /etc/apt/sources.list && \
            apt-get update && apt-get install -y \
            gnupg \
            zenity \
            ca-certificates \
            xz-utils \
            curl \
            iceweasel \
            file \
            libgtkextra-dev \
            --no-install-recommends && \
            localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 || :

## Create the local anon user
        RUN groupadd -g 1000 anon
        RUN useradd -m -g 1000 -u 1000 -d /home/anon anon
        RUN mkdir /home/anon/.local

## Switch to the Tor Browser user and go to it's home directory.
        USER anon
        WORKDIR /home/anon

## Download the Browser Bundle and the signature from the Tor Browser Bundle website.
        RUN BROWSER_VERSION=$(curl $UPDATE_URL 2> /dev/null | grep -vi macos | grep -vi windows | grep -vi linux | head -n 2 | tail -n 1 | tr -d '",') && curl -sSL -o /home/anon/tor.tar.xz \
              https://www.torproject.org/dist/torbrowser/${BROWSER_VERSION}/tor-browser-linux64-${BROWSER_VERSION}_en-US.tar.xz
        RUN BROWSER_VERSION=$(curl $UPDATE_URL 2> /dev/null | grep -vi macos | grep -vi windows | grep -vi linux | head -n 2 | tail -n 1 | tr -d '",') && curl -sSL -o /home/anon/tor.tar.xz.asc \
              https://www.torproject.org/dist/torbrowser/${BROWSER_VERSION}/tor-browser-linux64-${BROWSER_VERSION}_en-US.tar.xz.asc

        RUN gpg --keyserver ha.pool.sks-keyservers.net \
              --recv-keys "EF6E 286D DA85 EA2A 4BA7  DE68 4E2C 6E87 9329 8290"
        RUN gpg --verify /home/anon/tor.tar.xz.asc

        RUN tar xf /home/anon/tor.tar.xz
        RUN rm -f /home/anon/tor.tar.xz*

## Set the ownership of the local application data to the user profile.
        USER root
        RUN chown -R anon:anon /home/anon/.local/ && \
            chmod -R o+rw /home/anon/.local/

## Change back to the user account and prepare to launch the browser
        USER anon
        CMD /home/anon/tor-browser_en-US/Browser/start-tor-browser


Experimental Dockerfile 1: Uses tb-updater and tb-starter from Whonix to manage Tor Browser updates
===================================================================================================

This approach has the *distinct* advantage of making it extremely easy to ensure
an up-to-date Tor Browser Bundle is always available. However, I have used it
less and think of it as experimental for now.

## Inherit the base container
        FROM eyedeekay/whonix

## become root, upgrade packages, and install tb-starter and tb-updater from
## the repos.
        USER root
        RUN apt-get update && apt-get dist-upgrade -y
        RUN apt-get install -y tb-starter tb-updater

## Switch back to the user and prepare to download and install the browser.
        USER user
        WORKDIR /home/user

## Install the browser and launch it.
        CMD update-torbrowser --devbuildpassthrough && torbrowser

Dockerfile 2: Tor Router
========================

## Inherit the base container
        FROM alpine:3.7

##
        ARG TOR_CONTROL_HOST=172.70.70.2
        ARG TOR_CONTROL_PORT=9151
        ARG TOR_SOCKS_HOST=172.70.70.2
        ARG TOR_SOCKS_PORT=9150

## Install and configure Tor
        RUN apk update && apk add tor
        COPY torrc /etc/tor/torrc

## Assure that torrc contains the values passed to docker build
        RUN sed -i "s|172.70.70.2|$TOR_CONTROL_HOST|g" /etc/tor/torrc
        RUN sed -i "s|9151|$TOR_CONTROL_PORT|g" /etc/tor/torrc
        RUN sed -i "s|172.70.70.2|$TOR_SOCKS_HOST|g" /etc/tor/torrc
        RUN sed -i "s|9150|$TOR_SOCKS_PORT|g" /etc/tor/torrc

## Create and set permissions on directories for Tor to use
        RUN mkdir -p /var/lib/tor
        RUN chown -R tor /var/lib/tor
        RUN chmod -R 2700 /var/lib/tor
        RUN chmod -R o+rw /var/lib/tor

## Set user to tor router system user and prepare to start Tor
        USER tor
        CMD tor -f /etc/tor/torrc


Optional Dockerfile 3: Snowflake Pluggable Transport
====================================================

I'm a a big fan of Snowflake, conceptually, hopefully someday soon I'll be able
to develop the skills required to help make it suitable for inclusion in the
mainline TBB. Tgus container sets up a Snowflake PT for Tor to use on a
pre-configured container. Be aware that Snowflake is still considered
experimental by TPO and they know what they are doing.

### TL:DR

        make browse

