#!/bin/sh

if [ $# -eq 0 ]; then
	echo "Usage: $0 <servername>"
	exit
fi

for var in ROOTCAPASSWD ROOTCAMAIL; do
	if eval [ -z "\$$var" ]; then
		echo "Please set \$$var in the environment." >&2
		exit 1
	fi
done

export CLIENTNAME=
export SERVERNAME=$1
export USERMAIL=

set -e

[ -d servers ] || mkdir servers
mkdir servers/$SERVERNAME
mkdir servers/$SERVERNAME/private
chmod 700 servers/$SERVERNAME/private

echo "*** Generating key and certificate request for $SERVERNAME..."
openssl req -new \
    -config server.config \
    -nodes \
    -keyout servers/$SERVERNAME/private/$SERVERNAME.key \
    -out servers/$SERVERNAME/$SERVERNAME.req

echo "*** Generating certificat for $SERVERNAME..."
openssl x509 -req \
    -in servers/$SERVERNAME/$SERVERNAME.req \
    -extfile rootca.config -extensions server_exts \
    -CAkey rootca/private/rootca.key -passin env:ROOTCAPASSWD \
    -sha1 \
    -days 365 \
    -CA rootca/rootca.crt \
    -out servers/$SERVERNAME/$SERVERNAME.crt

echo "*** Dumping $SERVERNAME certificate as text..."
openssl x509 \
    -in servers/$SERVERNAME/$SERVERNAME.crt \
    -noout \
    -text > servers/$SERVERNAME/$SERVERNAME.txt
