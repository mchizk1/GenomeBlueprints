#=======================================
# Signature Comparisons
#=======================================

# These functions are isolated from the package architecture because
# they should only be safely run with very specific evironmental configurations and
# dependencies are not enforced inside the package. They 'shell out' to a wsl session 
# with a conda environment activated. Next it runs a couple custom bash scripts.

# This approach integrates a bioinformatic pipeline with post processing in R.

library(tidyverse)
library(genomebluepRints)
library(ggalluvial)

get_genome_sigs <- function(metadata, stats){
  for(i in unique(metadata$genome)) {
    chromosomes <- stats$chr_id[stats$genome == i]
    print(paste("Getting signatures for: ", i))
    command <- paste("bash 100proof.sh",
                     paste(chromosomes, collapse = " "))
    system(paste0("wsl bash -lc 'source ~/.bashrc; conda activate blueprint; ",
                  command, "; sourmash sig cat -o ", i, ".sig.gz ",
                  paste0(paste0(chromosomes, ".sig.gz"), collapse = " "), "; ",
                  paste(paste0("rm ", chromosomes, ".sig.gz"), collapse = "; "), 
                  "; exit'; wsl --shutdown"))
  }
}

compare_genome_sigs <- function(stats) {
  genomes <- str_remove(list.files(), "\\.sig\\.gz$") %>%
    sort()
  genomes <- genomes[!str_detect(genomes, "^gather_")]
  #metadata <- filter(metadata, genome %in% genomes)
  stats <- filter(stats, genome %in% genomes)
  #genome1 <- paste0(metadata$genome[1], ".sig.gz")
  genome1 <- paste0(genomes[1], ".sig.gz")
  alignments <- c()
  for(i in 2:length(genomes)) {
    genome2 <- paste0(genomes[i], ".sig.gz")
    command <- paste("bash ../../gatherall.sh",
                     paste(genome1, genome2, collapse = " "))
    print(paste("Comparing signatures for: ", genomes[i], " against ", genomes[1]))
    system(paste0("wsl bash -lc 'source ~/.bashrc; conda activate blueprint; ",
                  command, "; exit' ; wsl --shutdown"))
    # Set path to the folder containing the CSV files
    csv_folder <- paste0("gather_", genome1, "/")
    # List all .csv files in the folder
    csv_files <- list.files(path = csv_folder, pattern = "\\.csv$", full.names = TRUE)
    # Read and combine all CSV files
    all_gathers <- do.call(rbind, lapply(csv_files, read.csv, stringsAsFactors = FALSE)) %>%
      group_by(query_filename) %>%
      summarise(
        overlap = max(intersect_bp),
        p_query = max(f_orig_query)*100,
        p_match = max(f_match)*100,
        match = name[which.max(intersect_bp)]
      ) %>%
      mutate(
        query_part = str_extract(query_filename, "[12](?=\\.fasta)"),
        match_part = str_extract(match, "[12]$"),
        query = str_remove(query_filename, "\\.part_[12]\\.fasta"),
        match = str_remove(match, "\\.part_[12]")
      ) %>%
      ungroup() %>%
      mutate(genome1 = genomes[1],
             genome2 = genomes[i])
    # Check for duplicates and keep the one with the maximum overlap
    # if (length(all_gathers$match) != length(unique(all_gathers$match))) {
    #   all_gathers <- group_by(all_gathers, match) %>%
    #     filter(overlap == max(overlap))
    # }
    system(paste0("wsl rm -r ", csv_folder, "; wsl --shutdown"))
    alignments <- bind_rows(alignments, all_gathers)
  }
  alignments$match_chr_name <- stats$chromosome[match(alignments$match, stats$chr_id)]
  alignments$query_chr_name <- stats$chromosome[match(alignments$query, stats$chr_id)]
  return(alignments)
}

#====================
# Code for testing...
#====================
# get_genome_sigs(apple$metadata, apple$stats)
# matches <- compare_genome_sigs(test_grape)
# matches <- compare_genome_sigs_ortn(test_grape)
# matches2 <- na.omit(matches) %>%
#   mutate(match_chr_name = paste0(match_chr_name, "_", match_part),
#          query_chr_name = paste0(query_chr_name, "_", query_part)) %>%
#   ungroup() %>%
#   map_chromosomes_ortn() 
# 
# grape_test <- is_lodes_form(chromosome_maps, genome, chr, HOM)
# 
# is_lodes_form(distinct(chromosome_maps), genome, chr, HOM)
# to_alluvia_form(chromosome_maps, genome, chr, HOM_chr)
# is_lodes_form(chromosome_maps, genome, chr, HOM)
# plot_mapping_ortn(matches2, "Vitis")
# 
# test <- map_chromosomes(brambles)
# plot_mapping(test, "Vitis")
