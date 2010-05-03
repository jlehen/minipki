#!/bin/sh

find . -name crt.txt | cut -b 3- | sort -r | while read crt; do
	echo ${crt%/*}
	sed -n '/Validity/,+2p' $crt
done
