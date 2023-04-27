
#!/bin/bash

# COPIED/MODIFIED from the redis server gen-certs util
# https://github.com/redis/redis/blob/cc0091f0f9fe321948c544911b3ea71837cf86e3/utils/gen-test-certs.sh

# Generate some test certificates which are used by the regression test suite:
#
#   tls/ca.{crt,key}          Self signed CA certificate.
#   tls/redis.{crt,key}       A certificate with no key usage/policy restrictions.
#   tls/client.{crt,key}      A certificate restricted for SSL client usage.
#   tls/server.{crt,key}      A certificate restricted for SSL server usage.
#   tls/redis.dh              DH Params file.

generate_cert() {
    local name=$1
    local cn="$2"
    local opts="$3"

    local keyfile=tls/${name}.key
    local certfile=tls/${name}.crt

    [ -f $keyfile ] || openssl genrsa -out $keyfile 2048
    openssl req \
        -new -sha256 \
        -subj "/O=Redis Test/CN=$cn" \
        -addext "subjectAltName=DNS:example.com,DNS:localhost,DNS:127.0.0.1" \
        -key $keyfile | \
        openssl x509 \
            -req -sha256 \
            -CA tls/ca.crt \
            -CAkey tls/ca.key \
            -CAserial tls/ca.txt \
            -CAcreateserial \
            -days 365 \
            $opts \
            -out $certfile
}

mkdir -p tls
[ -f tls/ca.key ] || openssl genrsa -out tls/ca.key 4096
openssl req \
    -x509 -new -nodes -sha256 \
    -key tls/ca.key \
    -days 3650 \
    -subj '/O=Redis Test/CN=Certificate Authority' \
    -addext "subjectAltName=DNS:example.com,DNS:localhost,DNS:127.0.0.1" \
    -out tls/ca.crt

cat > tls/openssl.cnf <<_END_
subjectAltName = @alt_names
[alt_names]
DNS.1 = example.com
DNS.2 = localhost
[ server_cert ]
keyUsage = digitalSignature, keyEncipherment
nsCertType = server
[ client_cert ]
keyUsage = digitalSignature, keyEncipherment
nsCertType = client
_END_

generate_cert server "localhost" "-extfile tls/openssl.cnf -extensions server_cert"
generate_cert client "localhost" "-extfile tls/openssl.cnf -extensions client_cert"
generate_cert redis "localhost"

mkdir -p redis/tls
cp tls/redis.* redis/tls
cp tls/ca.crt redis/tls

mkdir -p src/main/resources/tls
cp tls/client.* src/main/resources/tls
cp tls/ca.crt src/main/resources/tls

