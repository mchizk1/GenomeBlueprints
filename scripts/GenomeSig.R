#===============================================================
# Signature Comparisons (experimental script)
#===============================================================
#
# These helpers are intentionally outside the package API because they depend
# on a local WSL + conda + sourmash toolchain.

library(tidyverse)
library(genomebluepRints)
library(ggalluvial)

run_wsl_command <- function(command, shutdown = TRUE) {
  shutdown_cmd <- if (isTRUE(shutdown)) "; wsl --shutdown" else ""
  system(paste0("wsl bash -lc 'source ~/.bashrc; conda activate blueprint; ", command, "; exit'", shutdown_cmd))
}

get_genome_sigs <- function(metadata, stats, shutdown_each_genome = TRUE) {
  script_100proof <- normalizePath(file.path("scripts", "100proof.sh"), winslash = "/")
  for (i in unique(metadata$genome)) {
    chromosomes <- stats$chr_id[stats$genome == i]
    print(paste("Getting signatures for:", i))
    command <- paste("bash", script_100proof, paste(chromosomes, collapse = " "))
    full_cmd <- paste0(
      command,
      "; sourmash sig cat -o ", i, ".sig.gz ",
      paste0(paste0(chromosomes, ".sig.gz"), collapse = " "),
      "; ",
      paste(paste0("rm ", chromosomes, ".sig.gz"), collapse = "; ")
    )
    run_wsl_command(full_cmd, shutdown = shutdown_each_genome)
  }
}

compare_genome_sigs <- function(stats, shutdown_each_compare = TRUE) {
  script_gather <- normalizePath(file.path("scripts", "gatherall.sh"), winslash = "/")
  genomes <- str_remove(list.files(), "\\.sig\\.gz$") %>%
    sort()
  genomes <- genomes[!str_detect(genomes, "^gather_")]
  stats <- filter(stats, genome %in% genomes)
  genome1 <- paste0(genomes[1], ".sig.gz")
  alignments <- c()
  for (i in 2:length(genomes)) {
    genome2 <- paste0(genomes[i], ".sig.gz")
    command <- paste("bash", script_gather, paste(genome1, genome2, collapse = " "))
    print(paste("Comparing signatures for:", genomes[i], "against", genomes[1]))
    run_wsl_command(command, shutdown = shutdown_each_compare)
    csv_folder <- paste0("gather_", genome1, "/")
    csv_files <- list.files(path = csv_folder, pattern = "\\.csv$", full.names = TRUE)
    all_gathers <- do.call(rbind, lapply(csv_files, read.csv, stringsAsFactors = FALSE)) %>%
      group_by(query_filename) %>%
      summarise(
        overlap = max(intersect_bp),
        p_query = max(f_orig_query) * 100,
        p_match = max(f_match) * 100,
        match = name[which.max(intersect_bp)]
      ) %>%
      mutate(
        query_part = str_extract(query_filename, "[12](?=\\.fasta)"),
        match_part = str_extract(match, "[12]$"),
        query = str_remove(query_filename, "\\.part_[12]\\.fasta"),
        match = str_remove(match, "\\.part_[12]")
      ) %>%
      ungroup() %>%
      mutate(genome1 = genomes[1], genome2 = genomes[i])
    run_wsl_command(paste0("rm -r ", csv_folder), shutdown = shutdown_each_compare)
    alignments <- bind_rows(alignments, all_gathers)
  }
  alignments$match_chr_name <- stats$chromosome[match(alignments$match, stats$chr_id)]
  alignments$query_chr_name <- stats$chromosome[match(alignments$query, stats$chr_id)]
  alignments
}
