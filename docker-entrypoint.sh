#!/bin/sh -e

./initial-setup.sh
exec ipsec start --nofork "$@"
