#!/bin/sh
# $Id: list_validity.sh,v 1.2 2010/05/03 13:03:58 jlh Exp $

find . -name crt.txt | cut -b 3- | sort -r | while read crt; do
	echo ${crt%/*}
	sed -n '/Validity/,+2p' $crt
done
