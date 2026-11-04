# cdm_psortb

CTS (CDM Task Service) job wrapper for [PSORTb](https://github.com/brinkmanlab/psortb_commandline_docker), bacterial protein subcellular localization prediction.

## Container

Wraps the canonical [`brinkmanlab/psortb_commandline:1.0.2`](https://hub.docker.com/r/brinkmanlab/psortb_commandline) image (released by the Brinkman lab, the developers of PSORTb).

Published to `ghcr.io/kbaseincubator/cdm_psortb`.

**Entrypoint:** `/usr/local/bin/run-psort`, a wrapper around the PSORTb CLI (`/usr/local/psortb/bin/psort`). psort only accepts input via `-i` and always writes to `/tmp/results/<timestamp>_psortb_<organism>.txt`, so the wrapper runs psort once per input file and moves each result to `/out/<input-basename>.psortb.tsv`.

**Reference data:** Not required. PSORTb's models and SCL databases are bundled inside the container.

## Usage via CTS

Required organism flag (one of). Group genomes by type and submit one job per group:
- `--negative` (`-n`) for Gram-negative bacteria
- `--positive` (`-p`) for Gram-positive bacteria
- `--archaea` (`-a`) for archaea

Output format: `--output terse` (`-o terse`) is recommended. Do **not** pass `-i`, `-r`, or `-x`; the wrapper handles input and output paths.

### Example

```python
job = tscli.submit_job(
    "ghcr.io/kbaseincubator/cdm_psortb:0.1.3@sha256:<digest from the CTS image registry>",
    input_files,                         # protein FASTA files (.faa, .fa, .fasta; .gz ok)
    "cts/io/<your_username>/output/psortb/run1",
    cluster="kbase",
    declobber=True,
    output_mount_point="/out",
    args=[
        "--negative",                    # or --positive / --archaea
        "--output", "terse",             # terse | normal | long
        tscli.insert_files(),            # input files, passed after the flags
    ],
    num_containers=len(input_files),     # one file per container runs them in parallel
    cpus=2,
    memory="4GB",
    runtime="PT1H",
)
```

One container may receive several input files (e.g. `num_containers=1`); the wrapper then runs psort on each in turn and writes one result per file.

## Output

Per input file `<basename>.faa`:
- `<basename>.psortb.tsv`: predicted subcellular localization per protein. With `--output terse`: a header line plus three tab-separated columns, `SeqID`, `Localization`, `Score`, one row per input protein.
- `<basename>.psortb.log`: the psort command and its output. CTS does not keep container logs for successful jobs, so this is the only log.

Note: `SeqID` is the full FASTA header line. Prodigal-style headers (`>CP002161.1_1 # 1 # 135 # 1 # ...`) keep everything after the ID, so split on the first whitespace before joining with other tools' outputs.

## Failure checks (0.1.3+)

The job fails (non-zero exit) instead of reporting success when:
- an input file has no sequences, or no input FASTA is given
- psort produces no result file, or an empty one
- with `--output terse`, the number of result rows differs from the number of input sequences
- two input files share a basename (their outputs would collide)

Version 0.1.2 and earlier did not check these: an empty input produced an empty result with exit 0, and several inputs in one container produced a single result, named after the last file but containing the first file's proteins.
