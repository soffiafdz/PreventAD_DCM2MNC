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
ERROR_LOG="$ROOT"/"$YEAR"_errorlog.txt

[ -d "$WORK_DIR" ] || mkdir "$WORK_DIR"
[ -f "$ERROR_LOG" ] && > "$ERROR_LOG"

# Trap the ERR signal and log errors
trap 'printf "Error occurred. Check log file."' ERR

for tarball in "$MNC_DIR"/*.tar.gz
do
	# Directories
	bname=$(basename "$tarball" .tar.gz) # Basename
	listdir="$LIST_DIR"/"$bname" # Lists directory
	workdir="$WORK_DIR"/"$bname"
	outdir="$MNC_DIR"/output/"$bname" # Output directory

	## Failsafe ##
	if [ ! -d "$listdir" ]
	then
		printf "%s — list directory %s does not exist\n" \
			$(date +%F::%R) $listdir >> "$ERROR_LOG"
		continue
	fi
	## Failsafe ##

	# If started, check for completion to avoid redundant work
	printf "%s — Starting with tarball %s\n" $(date +%F::%R) $bname
	if [ -d "$outdir" ]
	then
		if [ $(ls "$listdir" | wc -l) = $(ls "$outdir" | wc -l) ]
		then
			printf "%s — Tarball %s already completed\n" $(date +%F::%R) $bname
			[ -d "$workdir" ] \
				&& printf "%s — Deleting extracted files\n" $(date +%F::%R) \
				&& rm -rv "$workdir"
			continue
		fi
	else
		if [ ! -d "$workdir" ]
		then
			printf "%s — Extracting: %s\n" $(date +%F::%R) $bname
			if tar -xvzf "$tarball" -C $WORK_DIR
			then
				printf "%s — Extraction finished" $(date +%F::%R)
			else
				printf "%s — Failed to extract: %s\n" \
					$(date +%F::%R) $bname >> "$ERROR_LOG"
				continue
			fi
		fi
	fi

	## Failsafe ##
	if [ ! -d "$workdir" ]
	then
		printf "%s — %s was not extracted with the correct filename\n" \
			$(date +%F::%R) $workdir >> "$ERROR_LOG"
		continue
	fi
	## Failsafe ##

	# Create output directory
	[ -d "$outdir" ] || mkdir -p "$outdir"

	n_lists=$(ls "$listdir" | wc -l)
	for sequence in "$listdir"/*
	do
		seqname=$(basename "$sequence" .lst)
		seqtmp="$workdir"/"$seqname"
		seqdir="$outdir"/"$seqname"

		printf "%s — Starting with sequence %s\n" $(date +%F::%R) $seqname
	## Failsafes ##
		if [ ! -f "$sequence" ]
		then
			printf "%s — listfile %s does not exist\n" \
				$(date +%F::%R) $sequence >> "$ERROR_LOG"
			continue
		fi

		[ -d  "$seqdir" ] \
			&& printf "%s — %s already created" $(date +%F::%R) $seqdir \
			&& continue
	## Failsafes ##

		# Move files
		[ -d  "$seqtmp" ] || mkdir "$seqtmp"
		[ -d "$workdir"/"$bname" ] \
			&& mv -v "$workdir"/"$bname"/* "$workdir" \
			&& rmdir "$workdir"/"$bname"

		incomplete=false
		printf "%s — Checking all files for %s\n" $(date +%F::%R) $seqname
		while IFS= read -r file
		do
			if [ ! -f "$workdir"/"$file" ]
			then
				incomplete=true
				break
			fi
		done < "$sequence"

		if "$incomplete"
		then
			printf "%s — Not all files in %s were found\n" \
				$(date +%F::%R) $sequence >> "$ERROR_LOG"
			#rmdir "$seqtmp"
			rm -r "$seqtmp"
			continue
		else
			printf "${workdir}/%s\n" $(cat "$sequence") \
				| xargs mv -vt "$seqtmp"
		fi

		# CONVERSION #
		mkdir "$seqdir"
		printf "%s — Converting %s: %s\n" $(date +%F::%R) $bname $seqname
		dcm2mnc "$seqtmp" "$seqdir"
	done

	if [ ! "$n_lists" = $(ls "$outdir" | wc -l) ]
	then
		printf "%s — Incomplete sequences for %s\n" \
			$(date +%F::%R) $bname >> "$ERROR_LOG"
	else
		rm -r "$workdir"
	fi
done
