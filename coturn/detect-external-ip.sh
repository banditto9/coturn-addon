#!/bin/sh
# detect-external-ip.sh
# Detects the public external IP address of this machine.

set -e

IPV6=0
if [ "${1}" = "--ipv6" ]; then
    IPV6=1
fi

if [ "${IPV6}" = "1" ]; then
    IP=$(wget -qO- https://api6.ipify.org 2>/dev/null || true)
else
    # Try multiple HTTP providers in order — all return a bare IP and nothing else
    IP=$(wget -qO- https://api.ipify.org 2>/dev/null || true)
    if [ -z "${IP}" ]; then
        IP=$(wget -qO- https://ifconfig.me 2>/dev/null || true)
    fi
    if [ -z "${IP}" ]; then
        IP=$(wget -qO- https://icanhazip.com 2>/dev/null || true)
    fi
fi

# Strip any whitespace/newlines just in case
IP=$(echo "${IP}" | tr -d '[:space:]')

if [ -z "${IP}" ]; then
    echo "ERROR: Could not detect external IP" >&2
    exit 1
fi

echo "${IP}"
