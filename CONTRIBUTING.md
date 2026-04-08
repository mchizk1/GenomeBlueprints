# Contributing

## Code boundaries

- `R/` contains package API and reusable functionality.
- `scripts/` contains environment-specific experimental workflows.
- Keep package code independent of local WSL/conda assumptions.

## Development workflow

1. Update roxygen comments for changed package functions.
2. Run `devtools::document()`.
3. Run tests with `devtools::test()`.
4. Run package checks with `devtools::check()`.

## Secrets and credentials

- Never commit API keys, tokens, or credentials.
- Use environment variables (for example `ENTREZ_KEY`) and `.Renviron`.

## Testing expectations

- Add or update tests for behavior changes in `R/`.
- Prefer deterministic tests; mock network responses where possible.
