FROM alpine:3.7
ARG TOR_CONTROL_HOST=172.70.70.2
ARG TOR_CONTROL_PORT=9151
ARG TOR_SOCKS_HOST=172.70.70.2
ARG TOR_SOCKS_PORT=9150
RUN apk update && apk add tor go git go-tools pkgconfig
COPY torrc /etc/tor/torrc
RUN sed -i "s|172.70.70.2|$TOR_CONTROL_HOST|g" /etc/tor/torrc
RUN sed -i "s|9151|$TOR_CONTROL_PORT|g" /etc/tor/torrc
RUN sed -i "s|172.70.70.2|$TOR_SOCKS_HOST|g" /etc/tor/torrc
RUN sed -i "s|9150|$TOR_SOCKS_PORT|g" /etc/tor/torrc
RUN mkdir -p /var/lib/tor
RUN chown -R tor /var/lib/tor
RUN chmod -R 2700 /var/lib/tor
RUN chmod -R o+rw /var/lib/tor
USER tor
CMD tor -f /etc/tor/torrc
