#!/bin/sh -e

/init.sh
iptables -t nat -A POSTROUTING -s ${VPN_NETWORK} -o ${VPN_DEVICE} -j MASQUERADE
exec ipsec start --nofork "$@"
