error() {
	echo "$@" >&2
	exit 1
}

readpw() {

	echo "Warning: Double every backslash."
	echo -n "$1? "
	stty -echo
	eval read $1
	stty echo
	if [ -z "$1" ]; then
		echo "ERROR: Empty $1." >&2
		exit 1
	fi
	echo
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
