#!/bin/sh

if [ $# -eq 0 ]; then
	echo "Usage: $0 <clientname>"
	exit
fi

for var in ROOTCAPASSWD ROOTCAMAIL; do
	if eval [ -z "\$$var" ]; then
		echo "Please set \$$var in the environment." >&2
		exit 1
	fi
done

export CLIENTNAME=$1
export SERVERNAME=
export USERMAIL=

set -e

[ -d clients ] || mkdir clients
mkdir clients/$CLIENTNAME
mkdir clients/$CLIENTNAME/private
chmod 700 clients/$CLIENTNAME/private

echo "*** Generating key and certificate request for $CLIENTNAME..."
openssl req -new \
    -config client.config \
    -nodes \
    -keyout clients/$CLIENTNAME/private/$CLIENTNAME.key \
    -out clients/$CLIENTNAME/$CLIENTNAME.req

echo "*** Generating certificat for $CLIENTNAME..."
openssl x509 -req \
    -in clients/$CLIENTNAME/$CLIENTNAME.req \
    -extfile rootca.config -extensions client_exts \
    -CAkey rootca/private/rootca.key -passin env:ROOTCAPASSWD \
    -sha1 \
    -days 365 \
    -CA rootca/rootca.crt \
    -out clients/$CLIENTNAME/$CLIENTNAME.crt

echo "*** Dumping $CLIENTNAME certificate as text..."
openssl x509 \
    -in clients/$CLIENTNAME/$CLIENTNAME.crt \
    -noout \
    -text > clients/$CLIENTNAME/$CLIENTNAME.txt
