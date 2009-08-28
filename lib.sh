error() {
	echo "$@" >&2
	exit 1
}

# Result in $PW global variable.
readpw() {
	local verify pw1 pw2

	if [ "x$1" = "x-v" ]; then
		verify=1
		shift
	fi

	while : ; do
		echo "Warning: Double every backslash."
		echo -n "$1? "
		stty -echo
		read pw1
		stty echo
		echo

		if [ -z "$pw1" ]; then
			echo "ERROR: Empty $1." >&2
			continue
		fi

		[ -z "$verify" ] && break

		echo -n "$1 again? "
		stty -echo
		read pw2
		stty echo
		echo

		[ "x$pw1" = "x$pw2" ] && break

		echo "ERROR: Passwords mismatch." >&2
	done
	PW="$pw1"
}

mkCAhierarchy() {
	local d="$1"

	mkdir -p "$d"
	touch "$d/key.pem"
	chmod 600 "$d/key.pem"
	touch "$d/database.txt"
	echo 01 > "$d/serial.txt"
}

dumpcert() {
	local c="$1"

	openssl x509 -in "$c" -noout -text
}

writeconf() {

	case "$RDNSEP" in
	,|/) : ;;
	*) echo "ASSERTION FAILED: Invalid RDNSEP"; exit 127 ;;
	esac

	echo RDNSEP=\"$RDNSEP\"
	echo
	for var in "$@"; do
		eval echo $var=\\\"\""\$$var"\"\\\"
	done
}

furtherdir() {
	local d i

	case "$RDNSEP" in
	,|/) : ;;
	*) echo "ASSERTION FAILED: Invalid RDNSEP"; exit 127 ;;
	esac

	d="$1"
	shift
	for i in "$@"; do
		d="${d}${RDNSEP}${i}"
	done
	echo "$d"
}

builddir() {
	local d

	d=$(furtherdir "" "$@")
	echo "${d#$RDNSEP}"
}

deepOrFlat() {

	case "$1" in
	-f) RDNSEP=',' ;;
	-d) RDNSEP='/' ;;
	*)  return 1 ;;
	esac

	return 0
}

genRandomSerial() {
	local d s
	local N=4

	d="$1"
	while : ; do
		s=$(openssl rand $N | od -t x$N | awk 'NR == 1 {print $2}' | tr 'a-z' 'A-Z')
		cat "$d/database.txt" | awk "\$3 ~ /^$s$/ { exit 1 }" && break
	done
	echo "$s" > "$d/serial.txt"
}
