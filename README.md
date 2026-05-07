# cdm_psortb

CTS (CDM Task Service) job wrapper for [PSORTb](https://github.com/brinkmanlab/psortb_commandline_docker), bacterial protein subcellular localization prediction.

## Container

Wraps the canonical [`brinkmanlab/psortb_commandline:1.0.2`](https://hub.docker.com/r/brinkmanlab/psortb_commandline) image (released by the Brinkman lab, the developers of PSORTb).

Published to `ghcr.io/kbaseincubator/cdm_psortb`.

**Entrypoint:** `/usr/local/psortb/bin/psort` (the PSORTb CLI binary). Append PSORTb flags as arguments.

**Reference data:** Not required. PSORTb's models and SCL databases are bundled inside the container.

## Usage via CTS

Required organism flag (one of):
- `--positive` for Gram-positive bacteria
- `--negative` for Gram-negative bacteria
- `--archaea` for archaea

### Example

```python
job = tscli.submit_job(
    "ghcr.io/kbaseincubator/cdm_psortb:0.1.0@sha256:<digest>",
    input_files,                         # protein FASTA files
    "cts/io/{your_username}/output/psortb/test/v1",
    cluster="kbase",
    declobber=True,
    output_mount_point="/out",
    args=[
        "--negative",                    # or --positive / --archaea
        "--output", "terse",             # terse | normal | long
        "--seqformat", "FASTA",
        "-o", "/out/psortb_results.txt",
        tscli.insert_files(),
    ],
    num_containers=4,
    cpus=4,
    memory="16GB",
    runtime="PT2H"
)
```

## Output

PSORTb produces a single results file with predicted subcellular localization per protein. With `--output terse` (recommended for downstream parsing): three tab-separated columns: SeqID, Localization, Score.
