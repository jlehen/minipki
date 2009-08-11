#!/bin/sh

usage() {
	[ $# -gt 0 ] && echo "$@" >&2
	echo "Usage: $0 <name> <mail> <duration>" >&2
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

[ $# -eq 3 ] || usage
echo "$3" | grep -q '^[0-9][0-9]*$' || usage usage "ERROR: Invalid duration '$3'"

NAME=$1
MAIL=$2
DURATION=$3

[ -z "$CHILDCAPASSWD" ] && CHILDCAPASSWD=$(readpw CHILDCAPASSWD)

for var in CHILDCAPASSWD; do
	if eval [ -z "\"\$$var\"" ]; then
		echo "ERROR: Empty \$$var." >&2
		exit 1
	fi
done

set -e

[ -d users ] || mkdir users
mkdir users/$MAIL
mkdir users/$MAIL/private
chmod 700 users/$MAIL/private

OU=user
export OU MAIL TYPE NAME

echo "*** Generating key and certificate request for $NAME ($MAIL)..."
openssl req -new \
    -config etc/req.conf \
    -nodes \
    -keyout users/$MAIL/private/$MAIL.key \
    -out users/$MAIL/$MAIL.csr

for type in auth mail; do
	echo "*** Generating $type certificate for $NAME ($MAIL)..."
	openssl ca -batch \
	    -in users/$MAIL/$MAIL.csr \
	    -extfile etc/user_exts.conf -extensions user_${type}_exts \
	    -keyfile childca.$OU/private/childca.key -passin env:CHILDCAPASSWD \
	    -cert childca.$OU/childca.crt \
	    -config etc/childca.conf \
	    -days $DURATION \
	    -md sha1 \
	    -out users/$MAIL/$MAIL.$type.crt

	echo "*** Dumping $NAME ($MAIL) certificate as text..."
	openssl x509 \
	    -in users/$MAIL/$MAIL.$type.crt \
	    -noout \
	    -text > users/$MAIL/$MAIL.$type.txt

	echo "*** Creating PKCS12 file..."
	openssl pkcs12 \
	    -export -passout pass: \
	    -CAfile rootca/rootca.crt \
	    -in users/$MAIL/$MAIL.$type.crt \
	    -inkey users/$MAIL/private/$MAIL.key \
	    -out users/$MAIL/$MAIL.$type.p12
done
