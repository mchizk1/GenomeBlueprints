# Phased Efficiency Overhaul

This project now supports a low-risk phased optimization path. The defaults preserve legacy behavior.

## Phase 0: Baseline and parity checks

1. Select representative taxa (small, medium, large).
2. Capture:
   - runtime,
   - number of IDs returned,
   - rows in `stats` and `metadata`,
   - output file row counts.
3. Save snapshots for before/after comparison.

## Phase 1: Resilience and observability

No behavior changes required:

- retry wrapper for transient failures,
- progress logging,
- input validation.

## Phase 2: Caching (opt-in)

Enable cache with:

```r
ncbi_genome_stats_and_metadata(
  taxonomy = "Actinidia chinensis",
  key = Sys.getenv("ENTREZ_KEY"),
  allow_n_chr = 29,
  use_cache = TRUE
)
```

Optional controls:

- `cache_dir = "path/to/cache"`
- `force_refresh = TRUE`

## Phase 3: Incremental processing

In `scripts/DoCompare.R`, repeated runs skip completed outputs by default with `skip_existing <- TRUE`.

## Phase 4: Parallel parsing (opt-in)

Enable bounded parallel parsing:

```r
ncbi_genome_stats_and_metadata(
  taxonomy = "Actinidia chinensis",
  key = Sys.getenv("ENTREZ_KEY"),
  allow_n_chr = 29,
  use_parallel = TRUE,
  workers = 2
)
```

## Phase 5: WSL batching (opt-in)

Experimental scripts can now avoid per-iteration shutdown overhead:

- `compare_genome_sigs(..., shutdown_each_compare = FALSE)`
- `get_genome_sigs(..., shutdown_each_genome = FALSE)`

Start with small runs and compare outputs before scaling up.
