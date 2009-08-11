#!/bin/sh

usage() {
	[ $# -gt 0 ] && echo "$@" >&2
	echo "Usage: $0 <servername> <duration>" >&2
	echo "Duration: in days" >&2
	exit 1
}

readpw() {
	local pw

	stty -echo
	echo -n "$1? "
	read pw
	stty echo
	echo "$pw"
}

[ $# -eq 2 ] || usage
echo "$2" | grep -q '^[0-9][0-9]*$' || usage usage "ERROR: Invalid duration '$2'"

NAME=$1
DURATION=$2

[ -z "$CHILDCAPASSWD" ] && CHILDCAPASSWD=$(readpw CHILDCAPASSWD)

for var in CHILDCAPASSWD; do
	if eval [ -z "\"\$$var\"" ]; then
		echo "ERROR: Empty \$$var." >&2
		exit 1
	fi
done

set -e

[ -d servers ] || mkdir servers
mkdir servers/$NAME
mkdir servers/$NAME/private
chmod 700 servers/$NAME/private

OU=server
export OU NAME

echo "*** Generating key and certificate request for $NAME..."
openssl req -new -batch -nodes \
    -config etc/req.conf \
    -keyout servers/$NAME/private/$NAME.key \
    -out servers/$NAME/$NAME.csr

echo "*** Generating certificate for $NAME..."
openssl ca -batch \
    -in servers/$NAME/$NAME.csr \
    -extfile etc/server_exts.conf -extensions server_exts \
    -keyfile childca.$OU/private/childca.key -passin env:CHILDCAPASSWD \
    -cert childca.$OU/childca.crt \
    -config etc/childca.conf \
    -days $DURATION \
    -md sha1 \
    -out servers/$NAME/$NAME.crt

echo "*** Dumping $NAME certificate as text..."
openssl x509 \
    -in servers/$NAME/$NAME.crt \
    -noout \
    -text > servers/$NAME/$NAME.txt
