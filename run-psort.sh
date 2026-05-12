#!/bin/bash
# psort takes input via -i FILE (positional <file> just prints help).
# psort writes results to /tmp/results/<timestamp>_psortb_<organism>.txt.
# Both behaviors are hardcoded inside psort. CTS captures /out/, so we
# locate the result file and move it.
set -e

INPUT="${@: -1}"
ARGS_BUT_LAST=("${@:1:$#-1}")
BASE=$(basename "$INPUT")
BASE="${BASE%.*}"

/usr/local/psortb/bin/psort "${ARGS_BUT_LAST[@]}" -i "$INPUT"

RESULT=$(ls -t /tmp/results/*_psortb_*.txt 2>/dev/null | head -1)
if [ -z "$RESULT" ]; then
    echo "ERROR: psort did not produce a result file in /tmp/results/" >&2
    exit 1
fi
mv "$RESULT" "/out/${BASE}.psortb.tsv"
