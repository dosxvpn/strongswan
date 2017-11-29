#!/bin/sh -e

/initial-setup.sh
iptables -t nat -A POSTROUTING -s ${VPN_NETWORK} -o ${VPN_DEVICE} -j MASQUERADE
exec ipsec start --nofork "$@"
