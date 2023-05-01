#!/bin/sh
set -e

redis-server --tls-port 6379 --port 0 \
    --tls-cert-file /tls/server.crt \
    --tls-key-file /tls/server.key \
    --tls-ca-cert-file /tls/ca.crt
