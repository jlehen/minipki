#!/bin/sh

usage() {
	[ $# -gt 0 ] && echo "$@" >&2
	echo "Usage: $0 <duration>" >&2
	echo "Duration: in days" >&2
	exit 1
}

readpw() {

	echo "Warning: Double every backslash."
	echo -n "$1? "
	stty -echo
	eval read $1
	stty echo
	echo
}

[ $# -eq 1 ] || usage
echo "$1" | grep -q '^[0-9][0-9]*$' || usage usage "ERROR: Invalid duration '$1'"
DURATION=$1

[ -z "$ROOTCAPASSWD" ] && readpw ROOTCAPASSWD

for var in ROOTCAPASSWD; do
	if eval [ -z "\"\$$var\"" ]; then
		echo "ERROR: Empty \$$var." >&2
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
echo "$ROOTCAPASSWD" | openssl req -new -x509 -verbose \
    -days $DURATION \
    -config etc/rootca_req.conf \
    -keyout rootca/private/rootca.key -passout stdin \
    -out rootca/rootca.crt

echo "*** Dumping rootca certificate as text..."
openssl x509 \
    -in rootca/rootca.crt \
    -noout \
    -text > rootca/rootca.txt
