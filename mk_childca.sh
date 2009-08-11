#!/bin/sh

usage() {
	[ $# -gt 0 ] && echo "$@" >&2
	echo "Usage: $0 <type> <duration>" >&2
	echo "Types: server, client, user" >&2
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

case "$1" in
server|client|user)
	;;
*)
	usage "ERROR: Unknown type '$1'"
	;;
esac

echo "$2" | grep -q '^[0-9][0-9]*$' || usage "ERROR: Invalid duration '$2'"

OU=$1
DURATION=$2

[ -z "$ROOTCAPASSWD" ] && readpw ROOTCAPASSWD
[ -z "$CHILDCAPASSWD" ] && readpw CHILDCAPASSWD

for var in ROOTCAPASSWD CHILDCAPASSWD; do
	if eval [ -z "\"\$$var\"" ]; then
		echo "ERROR: Empty \$$var." >&2
		exit 1
	fi
done

set -e

D=childca.$OU

[ -e $D ] || mkdir $D
[ -e $D/private ] || mkdir $D/private
chmod 700 $D/private
[ -e $D/certs ] || mkdir $D/certs
touch $D/database.txt
echo 01 > $D/serial.txt

NAME=CA
export OU NAME

echo "*** Generating key and certificate request for childca..."
echo "$CHILDCAPASSWD" | openssl req -new \
    -config etc/req.conf \
    -keyout $D/private/childca.key -passout stdin \
    -out $D/childca.csr

echo "*** Generating certificate for childca..."
echo "$ROOTCAPASSWD" | openssl ca -batch \
    -in $D/childca.csr \
    -extfile etc/childca_exts.conf -extensions childca_exts \
    -keyfile rootca/private/rootca.key -passin stdin \
    -cert rootca/rootca.crt \
    -config etc/rootca.conf \
    -days $DURATION \
    -md sha1 \
    -out $D/childca.crt

echo "*** Dumping childca certificate as text..."
openssl x509 \
    -in $D/childca.crt \
    -noout \
    -text > $D/childca.txt
