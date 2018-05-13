#!/bin/sh -e

if [ -e /etc/ipsec.d/ipsec.conf ]; then
    echo "VPN has already been setup!"
    exit 0
fi

echo "Initializing..."
VPN_P12_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
echo ${VPN_P12_PASSWORD} > /etc/ipsec.d/client.cert.p12.password

touch /etc/ipsec.d/triplets.dat
cat > /etc/ipsec.d/ipsec.conf <<_EOF_
config setup
    uniqueids=never
    charondebug="ike 2, knl 2, cfg 2, net 2, esp 2, dmn 2,  mgr 2"

conn %default
    fragmentation=yes
    rekey=no
    dpdaction=clear
    keyexchange=ikev2
    compress=yes
    dpddelay=21600s

    ike=${IKE_CIPHERS}
    esp=${ESP_CIPHERS}

    left=%any
    leftauth=pubkey
    leftid="${VPN_DOMAIN}"
    leftcert=server.cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0,::/0

    right=%any
    rightauth=pubkey
    rightsourceip=${VPN_NETWORK_IPV4},${VPN_NETWORK_IPV6}
    rightsubnets=${DUMMY_DEVICE}
    rightdns=${VPN_DNS}

conn ikev2-pubkey
    auto=add
_EOF_

cat > /etc/ipsec.d/ipsec.secrets <<_EOF_
: ECDSA server.pem
_EOF_

# gen ca key and cert
ipsec pki --gen --type ecdsa --size 256 --outform pem > /etc/ipsec.d/private/ca.pem

ipsec pki --self \
          --in /etc/ipsec.d/private/ca.pem \
          --dn "C=CN, O=strongSwan, CN=strongSwan Root CA" \
          --ca \
          --lifetime 3650 \
          --outform pem > /etc/ipsec.d/cacerts/ca.cert.pem

# gen server key and cert
ipsec pki --gen --type ecdsa --size 256 --outform pem > /etc/ipsec.d/private/server.pem

ipsec pki --pub --in /etc/ipsec.d/private/server.pem --type ecdsa |
    ipsec pki --issue --lifetime 3650 --cacert /etc/ipsec.d/cacerts/ca.cert.pem \
              --cakey /etc/ipsec.d/private/ca.pem --dn "C=CN, O=strongSwan, CN=${VPN_DOMAIN}" \
              --san="${VPN_DOMAIN}" --flag serverAuth --flag ikeIntermediate \
              --outform pem > /etc/ipsec.d/certs/server.cert.pem

# gen client key and cert
ipsec pki --gen --type ecdsa --size 256 --outform pem > /etc/ipsec.d/private/client.pem

ipsec pki --pub --in /etc/ipsec.d/private/client.pem --type ecdsa |
    ipsec pki --issue \
              --cacert /etc/ipsec.d/cacerts/ca.cert.pem \
              --cakey /etc/ipsec.d/private/ca.pem --dn "C=CN, O=strongSwan, CN=${VPN_DOMAIN}" \
              --san="${VPN_DOMAIN}" \
              --outform pem > /etc/ipsec.d/certs/client.cert.pem

openssl pkcs12 -export \
               -inkey /etc/ipsec.d/private/client.pem \
               -in /etc/ipsec.d/certs/client.cert.pem \
               -name "${VPN_DOMAIN}" \
               -certfile /etc/ipsec.d/cacerts/ca.cert.pem \
               -caname "strongSwan Root CA" \
               -out /etc/ipsec.d/client.cert.p12 \
               -passout pass:${VPN_P12_PASSWORD}
