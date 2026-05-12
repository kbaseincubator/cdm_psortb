#!/bin/bash
# psort writes results to stdout; CTS only captures files written to /out/.
# This wrapper redirects stdout to /out/<input-basename>.psortb.tsv so
# results survive the job.
set -e
# Last positional argument is the input FASTA (per psort's CLI)
INPUT="${@: -1}"
BASE=$(basename "$INPUT")
BASE="${BASE%.*}"  # strip extension
exec /usr/local/psortb/bin/psort "$@" > "/out/${BASE}.psortb.tsv"
