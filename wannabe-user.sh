#!/bin/sh
set -e
set -u

usage(){
	printf "Usage: ./%s -u SOURCE_UID -g SOURCE_GID [-x- NEW_UID -y NEW_GID] [-f OWNERSHIP_PATH]" "$0"
}

change_ids() {
	# Build the strings for the final find_chown command
	if [ -n "${SOURCE_UID}" -a -n "${NEW_UID}" ] && [ "${SOURCE_UID}" -ne "${NEW_UID}" ]
	then
		SOURCE_STRING="-user ${SOURCE_UID}"
		NEW_STRING="${NEW_UID}"
		awk_substitute_file "/etc/passwd" "3" "${SOURCE_UID}" "${NEW_UID}"
	fi
	if [ -n "${SOURCE_GID}" -a -n "${NEW_GID}" ] && [ "${SOURCE_GID}" -ne "${NEW_GID}" ]
	then
		SOURCE_STRING="${SOURCE_STRING} -group ${SOURCE_GID}"
		NEW_STRING="${NEW_STRING}:${NEW_GID}"
		awk_substitute_file "/etc/passwd" "4" "${SOURCE_GID}" "${NEW_GID}"
		awk_substitute_file "/etc/group" "3" "${SOURCE_GID}" "${NEW_GID}"
	fi
	if [ -n "${SOURCE_STRING}" -a -n "${NEW_STRING}" ]
	then
		chown_find "${SOURCE_STRING}" "${NEW_STRING}"
	else
		exit 1
	fi
}

# Searches for all files specified in $1 and chowns those to $2
chown_find() {
	find / -path /proc -prune -o -path /sys -prune -o ${1} -exec chown "${2}" {} \;
}

# Substitutes fields in :-separated files
awk_substitute_file() {
	if [ -w "${1}" ]
	then
		awk -v "FIELD=${2}" -v "SOURCE_ID=${3}" -v "NEW_ID=${4}" 'BEGIN{IFS = OFS = FS = ":"} $FIELD == SOURCE_ID { $FIELD = NEW_ID } { print }' ${1} > ${1}.new
		mv -f ${1}.new ${1}
	fi
}

# Initiate variables without emptying them
SOURCE_UID=${SOURCE_UID-}
SOURCE_GID=${SOURCE_GID-}
NEW_UID=${NEW_UID-}
NEW_GID=${NEW_GID-}
OWNERSHIP_PATH=${OWNERSHIP_PATH-}


while getopts ":u:g:x:y:f:m" opt
do
	case $opt in
		u) SOURCE_UID="${OPTARG}"
		;;
		g) SOURCE_GID="${OPTARG}"
		;;
		x) NEW_UID="${OPTARG}"
		;;
		y) NEW_GID="${OPTARG}"
		;;
		f) OWNERSHIP_PATH="${OPTARG}"
		;;
		*) usage
		;;
	esac
done
# Shift all the Opts out to pass a clean $@ to the real CMD after execution
shift $((OPTIND-1))

SOURCE_STRING=
NEW_STRING=
# If in ownership_mode, some variables need to be filled manually
if [ -n "$OWNERSHIP_PATH" ]
then
	NEW_UID=$(stat -c "%u" "${OWNERSHIP_PATH}")
	NEW_GID=$(stat -c "%g" "${OWNERSHIP_PATH}")
	change_ids
else
	change_ids
fi

exec "$@"
