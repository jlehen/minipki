#!/bin/sh
# $Id: mk_rootCA.sh,v 1.4 2009/09/23 21:23:57 jlh Exp $

usage() {
	local me=`basename $0`

	[ $# -gt 0 ] && echo "$@" >&2
	cat >&2 << EOF
Usage: $me <-d|-f> <lifespan> <country> <organization>
-d: Deep layout; -f: Flat layout.
Lifespan: in days.
Country: first component of the DN.
Organization: second component of the DN.
EOF
	exit 1
}

set -e
. $(dirname $0)/lib.sh

#
# Sanity checks.
[ $# -eq 4 ] || usage
deepOrFlat "$1" || usage
shift
LIFESPAN=$1
C="$2"
O="$3"

echo "$LIFESPAN" | grep -q '^[0-9][0-9]*$' || \
    usage "ERROR: Invalid lifespan '$LIFESPAN'"

if [ -z "$ROOTCAPASSWD" ]; then
	readpw -v ROOTCAPASSWD
	ROOTCAPASSWD="$PW"
fi

#
# Let the show begin.
D=$(builddir "C=$C" "O=$O")
mkCAhierarchy "$D"
writeconf C O > "$D/config.sh"

export C O

echo "*** Generating key and self-signed certificate for rootCA..."
echo "$ROOTCAPASSWD" | openssl req -new -x509 -verbose \
    -days $LIFESPAN \
    -config etc/rootCA_req.conf \
    -keyout "$D/key.pem" -passout stdin \
    -out "$D/crt.pem"

echo "*** Dumping rootCA certificate as text..."
dumpcert "$D/crt.pem" > "$D/crt.txt"
