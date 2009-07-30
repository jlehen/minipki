#!/bin/sh

if [ $# -lt 1 ]; then
	echo "Usage: $0 <mail> [name]"
	exit
fi

for var in ROOTCAPASSWD ROOTCAMAIL; do
	if eval [ -z "'\$$var'" ]; then
		echo "Please set \$$var in the environment." >&2
		exit 1
	fi
done

export CLIENTNAME=
export SERVERNAME=
export USERMAIL=$1
export USERNAME="$2"

[ -z "$USERNAME" ] && USERNAME="$USERMAIL"

set -e

[ -d users ] || mkdir users
mkdir users/$USERMAIL
mkdir users/$USERMAIL/private
chmod 700 users/$USERMAIL/private

echo "*** Generating key and certificate request for $USERMAIL..."
openssl req -new \
    -config user.config \
    -nodes \
    -keyout users/$USERMAIL/private/$USERMAIL.key \
    -out users/$USERMAIL/$USERMAIL.req

for type in auth sign crypt; do
	echo "*** Generating $type certificate for $USERMAIL..."
	openssl x509 -req \
	    -in users/$USERMAIL/$USERMAIL.req \
	    -extfile rootca.config -extensions user_${type}_exts \
	    -CAkey rootca/private/rootca.key -passin env:ROOTCAPASSWD \
	    -sha1 \
	    -days 365 \
	    -CA rootca/rootca.crt \
	    -out users/$USERMAIL/$USERMAIL.$type.crt

	echo "*** Dumping $USERMAIL certificate as text..."
	openssl x509 \
	    -in users/$USERMAIL/$USERMAIL.$type.crt \
	    -noout \
	    -text > users/$USERMAIL/$USERMAIL.$type.txt

	echo "*** Creating PKCS12 file..."
	openssl pkcs12 \
	    -export -passout pass: \
	    -CAfile rootca/rootca.crt \
	    -in users/$USERMAIL/$USERMAIL.$type.crt \
	    -inkey users/$USERMAIL/private/$USERMAIL.key \
	    -out users/$USERMAIL/$USERMAIL.$type.p12
done
