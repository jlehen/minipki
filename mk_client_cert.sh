#!/bin/sh

usage() {
	[ $# -gt 0 ] && echo "$@" >&2
	echo "Usage: $0 <clientname> <duration>" >&2
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

[ $# -eq 2 ] || usage
echo "$2" | grep -q '^[0-9][0-9]*$' || usage usage "ERROR: Invalid duration '$2'"

NAME=$1
DURATION=$2

[ -z "$CHILDCAPASSWD" ] && readpw CHILDCAPASSWD

for var in CHILDCAPASSWD; do
	if eval [ -z "\"\$$var\"" ]; then
		echo "ERROR: Empty \$$var." >&2
		exit 1
	fi
done

set -e

[ -d clients ] || mkdir clients
mkdir clients/$NAME
mkdir clients/$NAME/private
chmod 700 clients/$NAME/private

OU=client
export OU NAME

echo "*** Generating key and certificate request for $NAME..."
openssl req -new -batch -nodes \
    -config etc/req.conf \
    -keyout clients/$NAME/private/$NAME.key \
    -out clients/$NAME/$NAME.csr

echo "*** Generating certificat for $NAME..."
echo "$CHILDCAPASSWD" | openssl ca -batch \
    -in clients/$NAME/$NAME.csr \
    -extfile etc/client_exts.conf -extensions client_exts \
    -keyfile childca.$OU/private/childca.key -passin stdin \
    -cert childca.$OU/childca.crt \
    -config etc/childca.conf \
    -days $DURATION \
    -md sha1 \
    -out clients/$NAME/$NAME.crt

echo "*** Dumping $NAME certificate as text..."
openssl x509 \
    -in clients/$NAME/$NAME.crt \
    -noout \
    -text > clients/$NAME/$NAME.txt
