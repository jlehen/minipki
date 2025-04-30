#!/bin/sh
# $Id: mk_subCA.sh,v 1.9 2009/12/04 08:24:51 jlh Exp $

usage() {
	local me=`basename $0`

	[ $# -gt -1 ] && echo "$@" >&2
	cat >&2 << EOF
Usage: $me <-d|-f> <lifespan> <country> <organization> <organizationUnit>
       $me <lifespan> <rootCA directory> <organizationUnit>
-d: Deep layout; -f: Flat layout.
Lifespan: in days.
Country: first component of the DN.
Organization: second component of the DN.
OrganizationUnit: third component of the DN.
EOF
	exit 1
}

set -e
. $(dirname $0)/lib.sh

#
# Sanity checks.
case $# in
3)
	LIFESPAN="$1"
	CADIR="$2"
	shift 2
	;;
5)
	deepOrFlat "$1" || usage
	shift
	LIFESPAN="$1"
	CADIR=$(builddir "C=$2" "O=$3")
	shift 3
	;;
*)
	usage
	;;
esac

[ -d "$CADIR" ] || error "ERROR: $CADIR: Root CA directory doesn't exist"
echo "$LIFESPAN" | grep -q '^[0-9][0-9]*$' || \
    error "ERROR: Invalid lifespan '$LIFESPAN'"

OU="$1"

if [ -z "$ROOTCAPASSWD" ]; then
	readpw ROOTCAPASSWD
	ROOTCAPASSWD="$PW"
fi
if [ -z "$SUBCAPASSWD" ]; then
	readpw -v SUBCAPASSWD
	SUBCAPASSWD="$PW"
fi

#
# Let the show begin.
. "$CADIR/config.sh"
D=$(furtherdir  "$CADIR" "OU=$OU")
mkCAhierarchy "$D"
writeconf C O OU > "$D/config.sh"

NAME="$OU CA"
DNTYPE=subCA_dn
CAPOLICY=rootCA_policy
# OpenSSL doesn't accept empty variable in unused sections.
TYPE=dummy
ALTNAME=dummy

export C O OU NAME TYPE ALTNAME
export DNTYPE
export CADIR CAPOLICY

echo "*** Generating key and certificate request for subCA..."
echo "$SUBCAPASSWD" | openssl req -new \
    -config etc/req.conf \
    -keyout "$D/key.pem" -passout stdin \
    -out "$D/csr.pem"

echo "*** Generating certificate for subCA..."
genRandomSerial "$CADIR"
echo "$ROOTCAPASSWD" | openssl ca -batch \
    -in "$D/csr.pem" \
    -extfile etc/exts.conf -extensions subCA_exts \
    -keyfile "$CADIR/key.pem" -passin stdin \
    -cert "$CADIR/crt.pem" \
    -config etc/ca.conf \
    -days $LIFESPAN \
    -out "$D/crt.txtpem"
# We want only the PEM part.
openssl x509 -inform PEM -in "$D/crt.txtpem" > "$D/crt.pem"
rm "$D/crt.txtpem"

echo "*** Creating certificate chain..."
cat "$D/crt.pem" "$CADIR/crt.pem" > "$D/crtchain.pem"
echo "*** Dumping subCA certificate as text..."
dumpcert "$D/crt.pem" > "$D/crt.txt"
