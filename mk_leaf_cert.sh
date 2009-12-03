#!/bin/sh
# $Id: mk_leaf_cert.sh,v 1.7 2009/12/03 23:51:29 jlh Exp $

usage() {
	local me=`basename $0`

	[ $# -gt 0 ] && echo "$@" >&2
	cat >&2 << EOF
Usage: $me <-d|-f> <lifespan> <country> <organization> \\
           <organizationUnit> <type> <subject> <alt. subject>
       $me <lifespan> <subsubCA directory> <subject> <alt. subject>
-d: Deep layout; -f: Flat layout.
Lifespan: in days.
Country: first component of the DN.
Organization: second component of the DN.
OrganizationUnit: third component of the DN.
Type: fourth component of the DN (Server, Client, UserAuth or UserMail).
Subject: fifth component of the DN.
Alt. subject: alternate subject name (FQDN for Server/Client, mail for User*)
EOF
	exit 1
}

set -e
. $(dirname $0)/lib.sh

#
# Sanity checks.
case $# in
4)
	LIFESPAN="$1"
	CADIR="$2"
	shift 2
	;;
8)
	deepOrFlat "$1" || usage
	shift
	LIFESPAN="$1"
	CADIR=$(builddir "C=$2" "O=$3" "OU=$4" "OU=$5")
	shift 5
	;;
*)
	usage
	;;
esac

[ -d "$CADIR" ] || error "ERROR: $CADIR: Sub sub CA directory doesn't exist"
echo "$LIFESPAN" | grep -q '^[0-9][0-9]*$' || \
    error "ERROR: Invalid lifespan '$LIFESPAN'"

NAME="$1"
ALTNAME="$2"

if [ -z "$SUBSUBCAPASSWD" ]; then
	readpw SUBSUBCAPASSWD
	SUBSUBCAPASSWD="$PW"
fi

#
# Let the show begin.
. "$CADIR/config.sh"
D=$(furtherdir "$CADIR" "CN=$NAME")
mkCAhierarchy "$D"
writeconf C O OU TYPE NAME > "$D/config.sh"

case "$TYPE" in
Server) EXTTYPE=server_exts ;;
Client) EXTTYPE=client_exts ;;
UserAuth) EXTTYPE=userauth_exts ;;
UserMail) EXTTYPE=userauth_exts ;;
esac

DNTYPE=subsubCA_dn
CAPOLICY=subsubCA_policy

export C O OU TYPE NAME ALTNAME
export DNTYPE
export CADIR CAPOLICY

echo "*** Generating key and certificate request for $NAME..."
openssl req -new -batch -nodes \
    -config etc/req.conf \
    -keyout "$D/key.pem" \
    -out "$D/csr.pem"

echo "*** Generating certificate for $NAME..."
genRandomSerial "$CADIR"
echo "$SUBSUBCAPASSWD" | openssl ca -batch \
    -in "$D/csr.pem" \
    -extfile etc/exts.conf -extensions $EXTTYPE \
    -keyfile "$CADIR/key.pem" -passin stdin \
    -cert "$CADIR/crt.pem" \
    -config etc/ca.conf \
    -days $LIFESPAN \
    -md sha1 \
    -out "$D/crt.txtpem"
# We want only the PEM part.
openssl x509 -inform PEM -in "$D/crt.txtpem" > "$D/crt.pem"
rm "$D/crt.txtpem"

echo "*** Creating certificate chain..."
cat "$CADIR/crtchain.pem" "$D/crt.pem" > "$D/crtchain.pem"
echo "*** Dumping $NAME certificate as text..."
dumpcert "$D/crt.pem" > "$D/crt.txt"

echo "*** Creating PKCS12 file..."
openssl pkcs12 \
    -export -passout pass: \
    -CAfile "$CADIR/crt.pem" \
    -in "$D/crt.pem" \
    -inkey "$D/key.pem" \
    -out "$D/pack.p12"
