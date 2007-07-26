#!/bin/sh

for var in ROOTCAPASSWD ROOTCAMAIL; do
	eval if [ -z "\$$var" ]; then
		echo "Please set \$$var in the environment." >&2
		exit 1
	fi
done

export CLIENTNAME=
export SERVERNAME=
export USERMAIL=

set -e

mkdir rootca
mkdir rootca/private
chmod 700 rootca/private

echo "*** Generating key and self-signed certificate for rootca..."
openssl req -new -x509 \
    -days 3650 \
    -config rootca.config \
    -keyout rootca/private/rootca.key -passout env:ROOTCAPASSWD \
    -out rootca/rootca.crt

echo "*** Dumping rootca certificate as text..."
openssl x509 \
    -in rootca/rootca.crt \
    -noout \
    -text > rootca/rootca.txt
