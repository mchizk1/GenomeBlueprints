
gb_log <- function(verbose, ...) {
  if (isTRUE(verbose)) {
    message(...)
  }
}

gb_retry <- function(expr_fn, retries = 3, base_wait = 0.8, verbose = TRUE, context = "request") {
  for (attempt in seq_len(retries + 1)) {
    out <- try(expr_fn(), silent = TRUE)
    if (!inherits(out, "try-error")) {
      return(out)
    }
    if (attempt <= retries) {
      wait <- base_wait * (2 ^ (attempt - 1))
      gb_log(verbose, sprintf("[%s] attempt %d failed; retrying in %.1fs", context, attempt, wait))
      Sys.sleep(wait)
    }
  }
  stop(sprintf("Failed %s after %d attempts.", context, retries + 1))
}

gb_cache_dir <- function(cache_dir = NULL) {
  if (!is.null(cache_dir) && nzchar(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
    return(cache_dir)
  }
  base <- file.path(tempdir(), "genomeblueprints_cache")
  dir.create(base, recursive = TRUE, showWarnings = FALSE)
  base
}

gb_cache_path <- function(prefix, key, cache_dir = NULL) {
  file.path(gb_cache_dir(cache_dir), paste0(prefix, "_", gsub("[^A-Za-z0-9_\\-]", "_", key), ".rds"))
}

gb_read_with_cache <- function(path, use_cache = FALSE, force_refresh = FALSE, fetch_fn = NULL) {
  if (isTRUE(use_cache) && file.exists(path) && !isTRUE(force_refresh)) {
    return(readRDS(path))
  }
  val <- fetch_fn()
  if (isTRUE(use_cache)) {
    saveRDS(val, path)
  }
  val
}

gb_parallel_lapply <- function(X, FUN, use_parallel = FALSE, workers = 2) {
  if (!isTRUE(use_parallel) || length(X) <= 1) {
    return(lapply(X, FUN))
  }
  workers <- max(1, min(as.integer(workers), length(X)))
  cl <- parallel::makeCluster(workers)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  parallel::parLapply(cl, X, FUN)
}

gb_fetch_assembly_summaries <- function(ids, chunk_size = 200, retries = 3, verbose = TRUE) {
  if (length(ids) == 0) {
    return(list())
  }
  chunks <- split(ids, ceiling(seq_along(ids) / max(1, as.integer(chunk_size))))
  out <- list()
  for (i in seq_along(chunks)) {
    chunk_ids <- chunks[[i]]
    gb_log(verbose, sprintf("Fetching assembly summaries chunk %d/%d (%d IDs)", i, length(chunks), length(chunk_ids)))
    summaries <- gb_retry(
      expr_fn = function() rentrez::entrez_summary(db = "assembly", id = chunk_ids, version = "2.0"),
      retries = retries,
      verbose = verbose,
      context = "entrez_summary"
    )
    if (length(chunk_ids) == 1) {
      summaries <- list(summaries)
      names(summaries) <- chunk_ids
    }
    out <- c(out, summaries)
  }
  out
}

gb_parse_assembly_stats <- function(idx, assembly_summaries, stats_ftp, id_ftp, retries = 3, verbose = TRUE) {
  gb_log(verbose, paste0("Assembly ", idx, ": ", assembly_summaries[[idx]]$assemblyname))
  assembly_i <- try(
    gb_retry(
      expr_fn = function() {
        read.delim(stats_ftp, comment.char = "#", header = FALSE) |>
          dplyr::filter(V3 == "Chromosome", V4 == "all", V5 %in% c("total-length")) |>
          dplyr::mutate(
            genome = assembly_summaries[[idx]]$assemblyname,
            V2 = sub("^0+", "", as.character(V2))
          ) |>
          dplyr::select(V2, V5, V6, genome) |>
          dplyr::rename(chromosome = V2)
      },
      retries = retries,
      verbose = verbose,
      context = "read stats report"
    ),
    silent = TRUE
  )
  id_i <- try(
    gb_retry(
      expr_fn = function() {
        read.delim(id_ftp, comment.char = "#", header = FALSE) |>
          dplyr::filter(V4 == "Chromosome", V2 == "assembled-molecule") |>
          dplyr::select(V3, V5) |>
          dplyr::rename(chromosome = V3, genbank_chr_id = V5) |>
          dplyr::mutate(chromosome = sub("^0+", "", as.character(chromosome)))
      },
      retries = retries,
      verbose = verbose,
      context = "read assembly report"
    ),
    silent = TRUE
  )
  if (inherits(assembly_i, "try-error") || inherits(id_i, "try-error")) {
    return(NULL)
  }
  dplyr::left_join(assembly_i, id_i, by = "chromosome")
}

#' Get NCBI genome statistics for a given taxonomic group
#'
#' This function retrieves genome statistics from NCBI for a specified taxonomic group including genome name, total length, and other relevant information.
#'
#' @importFrom taxize get_uid
#' @importFrom rentrez entrez_search
#' @importFrom rentrez entrez_summary
#' @importFrom rentrez set_entrez_key
#' @importFrom dplyr filter
#' @importFrom dplyr mutate
#' @importFrom dplyr select
#' @importFrom dplyr bind_rows
#'
#' @param taxa A character string indicating the taxanomic group to query
#' @param key An character string for the NCBI API key
#' @param allow_n_chr A numeric vector indicating the range of chromosome counts expected
#' @param use_cache Logical. Cache API responses and parsed data locally.
#' @param cache_dir Character path for cache files.
#' @param force_refresh Logical. Ignore cache and re-fetch.
#' @param chunk_size Integer. Number of IDs per summary request.
#' @param retries Integer. Retry count for network/file reads.
#' @param verbose Logical. Print progress messages.
#' @param use_parallel Logical. Parse assembly reports in parallel.
#' @param workers Integer. Max workers when parallel mode is enabled.
#' @return A data.frame containing genome statistics including genome name and physical chromosome lengths
#' @examples kiwi <- ncbi_genome_stats("Actinidia chinensis")
#' @export
ncbi_genome_stats <- function(
  taxa,
  key,
  allow_n_chr,
  use_cache = FALSE,
  cache_dir = NULL,
  force_refresh = FALSE,
  chunk_size = 200,
  retries = 3,
  verbose = TRUE,
  use_parallel = FALSE,
  workers = 2
) {
  stopifnot(is.character(taxa), length(taxa) == 1, nzchar(taxa))
  stopifnot(is.character(key), length(key) == 1, nzchar(key))
  stopifnot(length(allow_n_chr) >= 1)

  set_entrez_key(key)
  ncbi_id <- get_uid(taxa)
  query <- paste(paste0("txid", ncbi_id, "[Organism:exp]"), collapse = " OR ")
  cache_key <- paste0("stats_", taxa, "_", paste(sort(unique(allow_n_chr)), collapse = "-"))
  cache_path <- gb_cache_path("ncbi_genome_stats", cache_key, cache_dir)

  gb_read_with_cache(
    path = cache_path,
    use_cache = use_cache,
    force_refresh = force_refresh,
    fetch_fn = function() {
      search_results <- gb_retry(
        expr_fn = function() rentrez::entrez_search(db = "assembly", term = query, retmax = 1000),
        retries = retries,
        verbose = verbose,
        context = "entrez_search"
      )
      if (length(search_results$ids) == 0) {
        gb_log(verbose, "No assembly IDs returned from NCBI.")
        return(data.frame(chromosome = character(), stat = character(), value = numeric(), genome = character(), chr_id = character()))
      }

      assembly_summaries <- gb_fetch_assembly_summaries(
        ids = search_results$ids,
        chunk_size = chunk_size,
        retries = retries,
        verbose = verbose
      )
      assemblies <- names(assembly_summaries)
      stats_ftps <- vapply(assemblies, function(x) assembly_summaries[[x]]$ftppath_stats_rpt, character(1))
      id_ftps <- vapply(assemblies, function(x) assembly_summaries[[x]]$ftppath_assembly_rpt, character(1))

      valid_idx <- which(nzchar(stats_ftps) & nzchar(id_ftps))
      if (length(valid_idx) == 0) {
        return(data.frame(chromosome = character(), stat = character(), value = numeric(), genome = character(), chr_id = character()))
      }

      parse_one <- function(i) {
        parsed <- gb_parse_assembly_stats(
          idx = i,
          assembly_summaries = assembly_summaries,
          stats_ftp = stats_ftps[i],
          id_ftp = id_ftps[i],
          retries = retries,
          verbose = verbose
        )
        if (is.null(parsed) || nrow(parsed) == 0) {
          warning(paste0("Failed to read assembly statistics for ", assembly_summaries[[i]]$assemblyname, ". Skipping."))
          return(NULL)
        }
        if (nrow(parsed) %in% allow_n_chr) {
          return(parsed)
        }
        warning(paste0(
          "Assembly ", assembly_summaries[[i]]$assemblyname, " has ", nrow(parsed),
          " chromosomes, which is not in the allowed range. Skipping."
        ))
        NULL
      }

      parsed_list <- gb_parallel_lapply(valid_idx, parse_one, use_parallel = use_parallel, workers = workers)
      parsed_list <- Filter(Negate(is.null), parsed_list)
      if (length(parsed_list) == 0) {
        return(data.frame(chromosome = character(), stat = character(), value = numeric(), genome = character(), chr_id = character()))
      }
      out <- dplyr::bind_rows(parsed_list)
      colnames(out) <- c("chromosome", "stat", "value", "genome", "chr_id")
      out
    }
  )
}

#' Get NCBI genome metadata for a given taxonomic group
#'
#' This function retrieves genome assembly metadata from NCBI for a specified taxonomic group including genome name, assembly accession, submitter organization, assembly type, and release date.
#'
#' @importFrom taxize get_uid
#' @importFrom rentrez entrez_search
#' @importFrom rentrez entrez_summary
#' @importFrom rentrez set_entrez_key
#' @importFrom dplyr filter
#' @importFrom dplyr mutate
#' @importFrom dplyr select
#' @importFrom dplyr bind_rows
#'
#' @param taxa A character string indicating the taxanomic group to query
#' @param key An character string for the NCBI API key
#' @param use_cache Logical. Cache metadata responses locally.
#' @param cache_dir Character path for cache files.
#' @param force_refresh Logical. Ignore cache and re-fetch.
#' @param chunk_size Integer. Number of IDs per summary request.
#' @param retries Integer. Retry count for network calls.
#' @param verbose Logical. Print progress messages.
#' @return A list containing genome assembly metadata
#' @examples kiwi <- ncbi_genome_metadata("Actinidia chinensis")
#' @export
ncbi_genome_metadata <- function(
  taxa,
  key,
  use_cache = FALSE,
  cache_dir = NULL,
  force_refresh = FALSE,
  chunk_size = 200,
  retries = 3,
  verbose = TRUE
) {
  stopifnot(is.character(taxa), length(taxa) == 1, nzchar(taxa))
  stopifnot(is.character(key), length(key) == 1, nzchar(key))

  set_entrez_key(key)
  ncbi_id <- get_uid(taxa)
  query <- paste0("txid", ncbi_id, "[Organism:exp]")
  cache_path <- gb_cache_path("ncbi_genome_metadata", paste0("metadata_", taxa), cache_dir)

  gb_read_with_cache(
    path = cache_path,
    use_cache = use_cache,
    force_refresh = force_refresh,
    fetch_fn = function() {
      search_results <- gb_retry(
        expr_fn = function() rentrez::entrez_search(db = "assembly", term = query, retmax = 1000),
        retries = retries,
        verbose = verbose,
        context = "entrez_search metadata"
      )
      if (length(search_results$ids) == 0) {
        return(data.frame(
          genome = character(),
          assembly_accession = character(),
          submitterorganization = character(),
          assembly_type = character(),
          date = character(),
          species = character(),
          speciestaxid = character()
        ))
      }

      assembly_summaries <- gb_fetch_assembly_summaries(
        ids = search_results$ids,
        chunk_size = chunk_size,
        retries = retries,
        verbose = verbose
      )
      assemblies <- names(assembly_summaries)
      genome_metadata <- vector("list", length(assemblies))
      for (i in seq_along(assemblies)) {
        gb_log(verbose, paste0("Assembly ", i, ": ", assembly_summaries[[i]]$assemblyname))
        genome_metadata[[i]] <- data.frame(
          genome = assembly_summaries[[i]]$assemblyname,
          assembly_accession = assembly_summaries[[i]]$assemblyaccession,
          submitterorganization = assembly_summaries[[i]]$submitterorganization,
          assembly_type = assembly_summaries[[i]]$assemblytype,
          date = assembly_summaries[[i]]$seqreleasedate,
          species = assembly_summaries[[i]]$speciesname,
          speciestaxid = assembly_summaries[[i]]$taxid
        )
      }
      dplyr::bind_rows(genome_metadata)
    }
  )
}

#' Assemble complete NCBI stats for one taxonomic group
#'
#' This function combines genome statistics and metadata from NCBI for a specified taxonomic group into a single data frame.
#' @param taxonomy A character string indicating the taxonomic group to query
#' @param key An character string for the NCBI API key
#' @param allow_n_chr A numeric vector indicating the range of chromosome counts expected
#' @param use_cache Logical. Cache API responses and parsed data.
#' @param cache_dir Character path for cache files.
#' @param force_refresh Logical. Ignore cache and re-fetch.
#' @param chunk_size Integer. Number of IDs per summary request.
#' @param retries Integer. Retry count for network/file reads.
#' @param verbose Logical. Print progress messages.
#' @param use_parallel Logical. Parse assembly reports in parallel.
#' @param workers Integer. Max workers when parallel mode is enabled.
#' @return a list containing genome statistics and metadata
#' @export
ncbi_genome_stats_and_metadata <- function(
  taxonomy,
  key,
  allow_n_chr,
  use_cache = FALSE,
  cache_dir = NULL,
  force_refresh = FALSE,
  chunk_size = 200,
  retries = 3,
  verbose = TRUE,
  use_parallel = FALSE,
  workers = 2
) {
  stats <- ncbi_genome_stats(
    taxa = taxonomy,
    key = key,
    allow_n_chr = allow_n_chr,
    use_cache = use_cache,
    cache_dir = cache_dir,
    force_refresh = force_refresh,
    chunk_size = chunk_size,
    retries = retries,
    verbose = verbose,
    use_parallel = use_parallel,
    workers = workers
  )
  metadata <- ncbi_genome_metadata(
    taxa = taxonomy,
    key = key,
    use_cache = use_cache,
    cache_dir = cache_dir,
    force_refresh = force_refresh,
    chunk_size = chunk_size,
    retries = retries,
    verbose = verbose
  )
  if (length(unique(metadata$genome)) > length(unique(stats$genome))) {
    dropped <- setdiff(unique(metadata$genome), unique(stats$genome))
    warning(paste0("The following non chromosome-level assemblies were dropped: ", paste(dropped, collapse = ", ")))
  }
  metadata <- dplyr::mutate(metadata, taxonomic_group = taxonomy) %>%
    dplyr::filter(genome %in% stats$genome)
  list(stats = stats, metadata = metadata)
}
