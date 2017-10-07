FROM alpine

RUN apk add --no-cache iptables openssl strongswan util-linux \
    && ln -sf /etc/ipsec.d/ipsec.conf /etc/ipsec.conf \
    && ln -sf /etc/ipsec.d/ipsec.secrets /etc/ipsec.secrets

COPY initial-setup.sh /initial-setup.sh
COPY docker-entrypoint.sh /docker-entrypoint.sh

VOLUME /etc/ipsec.d /etc/strongswan.d

ENV VPN_DEVICE="eth0"
ENV VPN_NETWORK="10.20.30.0/24"
ENV VPN_DNS="8.8.8.8,8.8.4.4"
ENV IKE_CIPHERS="aes256-sha256-modp1024,3des-sha1-modp1024,aes256-sha1-modp1024!"
ENV ESP_CIPHERS="aes256-sha256,3des-sha1,aes256-sha1!"
ENV LAN_NETWORK="1.1.1.1/32"

EXPOSE 500/udp 4500/udp

ENTRYPOINT ["/docker-entrypoint.sh"]
