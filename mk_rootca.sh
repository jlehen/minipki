#!/bin/sh

usage() {
	echo "Usage: $0 <duration>" >&2
	exit 1
}

DURATION=$1

for var in ROOTCAPASSWD; do
	if eval [ -z "\"\$$var\"" ]; then
		echo "Please set \$$var in the environment." >&2
		exit 1
	fi
done

set -e

[ -e rootca ] || mkdir rootca
[ -e rootca/private ] || mkdir rootca/private
chmod 700 rootca/private
[ -e rootca/certs ] || mkdir rootca/certs
touch rootca/database.txt
echo 01 > rootca/serial.txt

echo "*** Generating key and self-signed certificate for rootca..."
openssl req -new -x509 -verbose \
    -days $DURATION \
    -config etc/rootca_req.conf \
    -keyout rootca/private/rootca.key -passout env:ROOTCAPASSWD \
    -out rootca/rootca.crt

echo "*** Dumping rootca certificate as text..."
openssl x509 \
    -in rootca/rootca.crt \
    -noout \
    -text > rootca/rootca.txt
