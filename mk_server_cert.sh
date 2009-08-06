#!/bin/sh

if [ $# -ne 2 ]; then
	echo "Usage: $0 <servername> <duration>" >&2
	exit
fi

for var in CHILDCAPASSWD; do
	if eval [ -z "\"\$$var\"" ]; then
		echo "Please set \$$var in the environment." >&2
		exit 1
	fi
done

NAME=$1
DURATION=$2

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
