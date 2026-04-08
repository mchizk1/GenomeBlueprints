#===============================================================
# Bulk comparison runner (experimental script)
#===============================================================

source(file.path("scripts", "GenomeSig.R"))

api_key <- Sys.getenv("ENTREZ_KEY", unset = "")
if (identical(api_key, "")) {
  stop("Missing ENTREZ_KEY. Set it in your environment before running this script.")
}

use_cache <- TRUE
cache_dir <- file.path(getwd(), ".cache")
use_parallel <- FALSE
workers <- 2
skip_existing <- TRUE

genera <- list.files()
inputs <- data.frame(
  taxon = c(
    "vaccinium",
    "rubus",
    "daucus",
    "citrus",
    "actinidia",
    "vitis rotundifolia",
    "capsicum",
    "solanum tuberosum",
    "solanum lycopersicum"
  ),
  chr_n = c(12, 7, 9, 9, 29, 20, 12, 12, 12)
)

for (i in seq_along(genera)) {
  setwd(genera[i])
  out_file <- paste0(genera[i], "_matches.csv")
  if (isTRUE(skip_existing) && file.exists(out_file)) {
    message(paste("Skipping existing output for", genera[i]))
    next
  }
  genome_data <- ncbi_genome_stats_and_metadata(
    taxonomy = inputs$taxon[i],
    key = api_key,
    allow_n_chr = inputs$chr_n[i],
    use_cache = use_cache,
    cache_dir = cache_dir,
    use_parallel = use_parallel,
    workers = workers
  )
  matches <- try(compare_genome_sigs(genome_data$stats, shutdown_each_compare = TRUE), silent = TRUE)
  if (inherits(matches, "try-error")) {
    message(paste("Error processing", genera[i], ":", matches))
    next
  }
  write.csv(matches, out_file, row.names = FALSE)
  rm(genome_data, matches)
  gc()
}
