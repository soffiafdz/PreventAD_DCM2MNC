#!/usr/bin/env bash

## From a specific year, extract the tarballs containing the DCM images
## Using the list of files for each sequence, cp them to a tmp directory
## and create a minc volume of the sequences in the correct directory.

set -e

# Check input
if [ "$#" -ne 1 ]
then
	echo "Usage: "$0" <year>"
	exit 1
fi

YEAR="$1"
ROOT=/ipl/ipl28/PreventAD/STOP-AD
LIST_DIR="$ROOT"/lists/"$YEAR"
MNC_DIR="$ROOT"/mnc/"$YEAR"
WORK_DIR="$MNC_DIR"/extracted # Directory for extracted files
ERROR_LOG="$ROOT"/"$YEAR"_errorlog_2pass.txt
[ -f "$ERROR_LOG" ] && > "$ERROR_LOG"

# Existing subjects
SUBS=($(ls "$LIST_DIR"))

# Remove phantoms
SUBS=( "${SUBS[@]/*phantom*/}" )

# Incomplete or missing
MISSING=()
PARTIAL=()
for bname in "${SUBS[@]}"
do
	listdir="${LIST_DIR}"/"${bname}" # Lists directory
	workdir="${WORK_DIR}"/"${bname}"
	outdir="${MNC_DIR}"/output/"${bname}" # Output directory

	if [ -d "$outdir" ]
	then
		[ $(ls "$listdir" | wc -l) != $(ls "$outdir" | wc -l) ] \
			&& PARTIAL+=("$bname")
	else
		MISSING+=("$bname")
	fi
done

if [ "${#MISSING[@]}" != 0 ]
then
	MISSING_FILE="${MNC_DIR}/not_extracted.lst"
	[ -f "$MISSING_FILE" ] && > "$MISSING_FILE"
	for bname in "${MISSING[@]}"
	do
		printf "%s\n" "$bname" >> "$MISSING_FILE"
	done
fi

if [ "${#PARTIAL[@]}" != 0 ]
then
	PARTIAL_FILE="${MNC_DIR}/not_completed.lst"
	[ -f "$PARTIAL_FILE" ] && > "$PARTIAL_FILE"
	for bname in "${PARTIAL[@]}"
	do
		printf "%s\n" "$bname" >> "$PARTIAL_FILE"
	done
fi
