#!/usr/bin/env bash

## From a specific year, extract the tarballs from the DCM/ directory
## containing the metadata.
## From the *.meta files, extract the FILES and ACQUISITION sections.
## Move everything to the corresponding METADATA/ directory.

# Check input
if [ "$#" -ne 1 ]
then
	echo "Usage: "$0" <year>"
	exit 1
fi

YEAR="$1"
ROOT=/ipl/ipl28/PreventAD/STOP-AD
INPUT="$ROOT"/DCM/"$YEAR"
OUT_MNC="$ROOT"/mnc/"$YEAR"
OUT_META="$ROOT"/metadata/"$YEAR"

# Check input is an existing file
if [ ! -d "$INPUT" ]
then
	printf "Error: %s is not a directory or does not exist.\n" "$INPUT"
	exit 1
fi

# Create missing output directories if necessary
for outdir in "$OUT_MNC" "$OUT_META"
do
	[ -d "$outdir" ] || mkdir -p "$outdir"
done

# Link files
# Save storage and prevent deletion
for tarball in "$INPUT"/*.tar
do
	ln -fv "$tarball" "$OUT_META"
done

# Extract files
for tarball in "$OUT_META"/*.tar
do
	echo "Extracting $tarball"
	tar -xvf "$tarball" -C "$OUT_META"
	rm "$tarball"
done

# Extract relevant info
for meta_file in "$OUT_META"/*.meta
do
# ACQUISITIONS
output="${meta_file/.meta/.acquis}"
printf "Creating %s.\n" "$output"
awk \
	'/<ACQUISITIONS>/, /<\/ACQUISITIONS>/' \
	"$meta_file" |
	sed '1d;$d' > "$output"
printf "%s created.\n" "$output"

# FILES
output=${meta_file/.meta/.files}
printf "Creating %s.\n" "$output"
awk \
	'/<FILES>/, /<\/FILES>/' \
	"$meta_file" |
	sed '1d;$d' > $output
printf "%s created.\n" "$output"
done

# Move DCM tarballs to MNC directory
mv -v "$OUT_META"/*.tar.gz "$OUT_MNC"
