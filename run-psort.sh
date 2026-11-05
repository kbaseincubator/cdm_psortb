#!/bin/bash
# CTS wrapper for PSORTb.
#
# psort takes input via -i FILE (a positional file just prints help) and
# writes results to /tmp/results/<timestamp>_psortb_<organism>.txt. CTS only
# captures /out/, so we run psort once per input file and move each result to
# /out/<input-basename>.psortb.tsv.
#
# Usage: run-psort <psort flags...> <input.faa> [<input2.faa> ...]
#   Input files are the arguments that are existing files with a FASTA
#   extension (.faa .fa .fasta .fas .pep, optionally .gz). Everything else is
#   passed to psort as flags (e.g. --negative --output terse).
#
# Fails (non-zero exit) instead of reporting success when:
#   - no input file is given, or two inputs share a basename
#   - an input has no sequences
#   - psort produces no result file, or an empty one
#   - with --output terse, the number of result rows differs from the number
#     of input sequences
# A per-input log (/out/<basename>.psortb.log) is written because CTS does not
# keep container logs for successful jobs.
set -euo pipefail

PSORT_BIN="${PSORT_BIN:-/usr/local/psortb/bin/psort}"
RESULTS_DIR="${PSORT_RESULTS_DIR:-/tmp/results}"
OUT_DIR="${PSORT_OUT_DIR:-/out}"

die() { echo "ERROR: $*" >&2; exit 1; }

is_fasta() {
    [ -f "$1" ] && case "$1" in
        *.faa|*.fa|*.fasta|*.fas|*.pep|*.faa.gz|*.fa.gz|*.fasta.gz|*.fas.gz|*.pep.gz) return 0 ;;
        *) return 1 ;;
    esac
}

FLAGS=()
INPUTS=()
for arg in "$@"; do
    if is_fasta "$arg"; then INPUTS+=("$arg"); else FLAGS+=("$arg"); fi
done
[ ${#INPUTS[@]} -gt 0 ] || die "no input FASTA given (expected a .faa/.fa/.fasta file among the arguments)"

# Output format decides how results are row-counted. psort's default is long.
FORMAT="long"
prev=""
for arg in ${FLAGS[@]+"${FLAGS[@]}"}; do
    case "$prev" in -o|--output) FORMAT="$arg" ;; esac
    case "$arg" in --output=*) FORMAT="${arg#--output=}" ;; esac
    prev="$arg"
done

# Reject duplicate basenames up front, so one input can never overwrite another.
SEEN=" "
for f in "${INPUTS[@]}"; do
    b=$(basename "$f"); b="${b%.gz}"; b="${b%.*}"
    case "$SEEN" in *" $b "*) die "two inputs share the basename '$b'; outputs would collide" ;; esac
    SEEN="$SEEN$b "
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$RESULTS_DIR" "$OUT_DIR"

for f in "${INPUTS[@]}"; do
    b=$(basename "$f"); b="${b%.gz}"; b="${b%.*}"
    log="$OUT_DIR/$b.psortb.log"

    case "$f" in
        *.gz) src="$WORK/$b.faa"; gzip -dc "$f" > "$src" ;;
        *) src="$f" ;;
    esac

    nseq=$(grep -c '^>' "$src" || true)
    [ "$nseq" -gt 0 ] || die "$f contains no sequences"

    # Clear old results so the file we pick up is from this run.
    rm -f "$RESULTS_DIR"/*_psortb_*.txt

    echo "input: $f ($nseq sequences)" > "$log"
    echo "command: $PSORT_BIN ${FLAGS[*]+${FLAGS[*]}} -i $src" >> "$log"
    if ! "$PSORT_BIN" ${FLAGS[@]+"${FLAGS[@]}"} -i "$src" >> "$log" 2>&1; then
        cat "$log" >&2
        die "psort failed on $f (see $log)"
    fi

    result=$(ls -t "$RESULTS_DIR"/*_psortb_*.txt 2>/dev/null | head -1 || true)
    [ -n "$result" ] || die "psort produced no result file for $f"
    [ -s "$result" ] || die "psort produced an empty result file for $f"

    if [ "$FORMAT" = "terse" ]; then
        # terse = one header line plus one row per sequence
        rows=$(( $(wc -l < "$result") - 1 ))
        [ "$rows" -eq "$nseq" ] || die "$f: $nseq input sequences but $rows result rows"
    fi

    # copy, not mv: /tmp and /out are usually different filesystems and mv
    # would try (and fail, noisily) to preserve ownership
    cp "$result" "$OUT_DIR/$b.psortb.tsv"
    rm -f "$result"
    echo "ok: $OUT_DIR/$b.psortb.tsv ($nseq sequences, format $FORMAT)" | tee -a "$log"
done
