#!/bin/sh

if [ $# -eq 0 ]; then
	echo "Usage: $0 <clientname> <duration>" >&2
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
openssl ca -batch \
    -in clients/$NAME/$NAME.csr \
    -extfile etc/client_exts.conf -extensions client_exts \
    -keyfile childca.$OU/private/childca.key -passin env:CHILDCAPASSWD \
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
