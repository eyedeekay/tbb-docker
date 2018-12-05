FROM debian:sid
ARG BROWSER_VERSION="7.5.6"
ARG TOR_CONTROL_HOST=127.0.0.1
ARG TOR_CONTROL_PORT=9151
ARG TOR_SOCKS_HOST=127.0.0.1
ARG TOR_SOCKS_PORT=9150
ARG TOR_FORCE_NET_CONFIG=0
ARG TOR_SKIP_LAUNCH=1
ARG TOR_SKIP_CONTROLPORTTEST=1

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/anon \
    TOR_CONTROL_PORT=$TOR_CONTROL_PORT \
    TOR_CONTROL_HOST=$TOR_CONTROL_HOST \
    TOR_SOCKS_PORT=$TOR_SOCKS_PORT \
    TOR_SOCKS_HOST=$TOR_SOCKS_HOST \
    TOR_SKIP_LAUNCH=$TOR_SKIP_LAUNCH \
    TOR_SKIP_CONTROLPORTTEST=$TOR_SKIP_CONTROLPORTTEST

RUN apt-get install -y gnupg2
RUN apt-key --keyring /etc/apt/trusted.gpg.d/whonix.gpg adv --keyserver hkp://pool.sks-keyservers.net --recv-keys 916B8D99C38EAF5E8ADC7A2A8D66066A2EEACCDA
RUN echo "deb http://deb.whonix.org stretch main" | tee /etc/apt/sources.list.d/whonix.list

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

RUN groupadd -g 1000 anon
RUN useradd -m -g 1000 -u 1000 -d /home/anon anon
RUN mkdir /home/anon/.local

USER anon

WORKDIR /home/anon

RUN curl -sSL -o /home/anon/tor.tar.xz \
      https://www.torproject.org/dist/torbrowser/${BROWSER_VERSION}/tor-browser-linux64-${BROWSER_VERSION}_en-US.tar.xz

RUN curl -sSL -o /home/anon/tor.tar.xz.asc \
      https://www.torproject.org/dist/torbrowser/${BROWSER_VERSION}/tor-browser-linux64-${BROWSER_VERSION}_en-US.tar.xz.asc

RUN gpg --keyserver ha.pool.sks-keyservers.net \
      --recv-keys "EF6E 286D DA85 EA2A 4BA7  DE68 4E2C 6E87 9329 8290"

RUN gpg --verify /home/anon/tor.tar.xz.asc

RUN tar xf /home/anon/tor.tar.xz

RUN rm -f /home/anon/tor.tar.xz*

USER root

RUN chown -R anon:anon /home/anon/.local/ && \
    chmod -R o+rw /home/anon/.local/

USER anon

CMD /home/anon/tor-browser_en-US/Browser/start-tor-browser
