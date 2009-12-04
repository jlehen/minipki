#!/bin/sh
# $Id: mk_subsubCA.sh,v 1.9 2009/12/04 08:24:51 jlh Exp $

usage() {
	local me=`basename $0`

	[ $# -gt 0 ] && echo "$@" >&2
	cat >&2 << EOF
Usage: $me <-d|-f> <lifespan> <country> <organization> \\
           <organizationUnit> <type>
       $me <lifespan> <subCA directory> <type>
-d: Deep layout; -f: Flat layout.
Lifespan: in days.
Country: first component of the DN.
Organization: second component of the DN.
OrganizationUnit: third component of the DN.
Type: fourth component of the DN (Server, Client, UserAuth, UserMail).
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
6)
	deepOrFlat "$1" || usage
	shift
	LIFESPAN="$1"
	CADIR=$(builddir "C=$2" "O=$3" "OU=$4")
	shift 4
	;;
*)
	usage
	;;
esac

[ -d "$CADIR" ] || error "ERROR: $CADIR: Sub CA directory doesn't exist"
echo "$LIFESPAN" | grep -q '^[0-9][0-9]*$' || \
    error "ERROR: Invalid lifespan '$LIFESPAN'"
case "$1" in
[Ss][Ee][Rr][Vv][Ee][Rr])
	TYPE="Server"
	;;
[Cc][Ll][Ii][Ee][Nn][Tt])
	TYPE="Client"
	;;
[Uu][Ss][Ee][Rr][Aa][Uu][Tt][Hh])
	TYPE="UserAuth"
	;;
[Uu][Ss][Ee][Rr][Mm][Aa][Ii][Ll])
	TYPE="UserMail"
	;;
*)
	usage "ERROR: Unknown type '$1'"
	;;
esac

if [ -z "$SUBCAPASSWD" ]; then
	readpw SUBCAPASSWD
	SUBCAPASSWD="$PW"
fi
if [ -z "$SUBSUBCAPASSWD" ]; then
	readpw -v SUBSUBCAPASSWD
	SUBSUBCAPASSWD="$PW"
fi

#
# Let the show begin.
. "$CADIR/config.sh"
D=$(furtherdir "$CADIR" "OU=$TYPE")
mkCAhierarchy "$D"
writeconf C O OU TYPE > "$D/config.sh"

NAME="$OU $TYPE CA"
DNTYPE=subsubCA_dn
CAPOLICY=subCA_policy
# OpenSSL doesn't accept empty variable in unused sections.
ALTNAME=dummy

export C O OU TYPE NAME ALTNAME
export DNTYPE
export CADIR CAPOLICY

echo "*** Generating key and certificate request for subsubCA..."
echo "$SUBSUBCAPASSWD" | openssl req -new \
    -config etc/req.conf \
    -keyout "$D/key.pem" -passout stdin \
    -out "$D/csr.pem"

echo "*** Generating certificate for subsubCA..."
genRandomSerial "$CADIR"
echo "$SUBCAPASSWD" | openssl ca -batch \
    -in "$D/csr.pem" \
    -extfile etc/exts.conf -extensions subsubCA_exts \
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
cat "$D/crt.pem" "$CADIR/crtchain.pem" > "$D/crtchain.pem"
echo "*** Dumping subsubCA certificate as text..."
dumpcert "$D/crt.pem" > "$D/crt.txt"
