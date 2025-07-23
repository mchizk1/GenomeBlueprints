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
                  "; exit'"))
  }
}

compare_genome_sigs <- function(stats) {
  genomes <- str_remove(list.files(), "\\.sig\\.gz$") %>%
    sort()
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
                  command, "; exit'"))
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
      group_by(query, match)  %>%
      summarise(
        overlap = sum(overlap),
        p_query = mean(p_query),
        p_match = mean(p_match),
        orientation = ifelse(sum(query_part == match_part) == 2, "▲", "▼"),
      ) %>%
      ungroup() %>%
      mutate(genome1 = genomes[1],
             genome2 = genomes[i])
    # Check for duplicates and keep the one with the maximum overlap
    if (length(all_gathers$match) != length(unique(all_gathers$match))) {
      all_gathers <- group_by(all_gathers, match) %>%
        filter(overlap == max(overlap))
    }
    system(paste0("wsl rm -r ", csv_folder))
    alignments <- bind_rows(alignments, all_gathers)
  }
  alignments$match_chr_name <- stats$chromosome[match(alignments$match, stats$chr_id)]
  alignments$query_chr_name <- stats$chromosome[match(alignments$query, stats$chr_id)]
  return(alignments)
}

get_genome_sigs(capsicum$stats)
matches <- compare_genome_sigs(vaccinium$metadata, vaccinium$stats)

expand_chr_names <- function(matches){
  genomes <- unique(c(matches$genome1, matches$genome2))
  genomes_split <- split(matches, matches$genome2)
  test <- sapply(genomes_split, function(x){
    as.character(x$match_chr_name)
  })
  expanded <- cbind(unlist(genomes_split[[1]][,10]), test)
  colnames(expanded) <- c(genomes[1], colnames(test))
  rownames(expanded) <- NULL
  expanded <- as.data.frame(expanded) %>%
    mutate(HOM = as.character(row_number())) %>%
    relocate(HOM)
  long_matches <- expanded %>%
    pivot_longer(names_to = "genome",
                 values_to = "chromosome",
                 cols = colnames(expanded)[-1]) %>%
    mutate(chromosome = factor(chromosome, 
                               levels = str_sort(unique(chromosome), numeric = TRUE)))
  return(long_matches)
}

expand_orientation <- function(matches){
  genomes <- unique(c(matches$genome1, matches$genome2))
  genomes_split <- split(matches, matches$genome2)
  test <- sapply(genomes_split, function(x){
    x$orientation
  })
  expanded <- cbind(unlist(genomes_split[[1]][,6]), test)
  rownames(expanded) <- NULL
  colnames(expanded) <- c(genomes[1], colnames(test))
  expanded <- as.data.frame(expanded) %>%
    mutate(HOM = as.character(row_number())) %>%
    relocate(HOM)
  long_matches <- expanded %>%
    pivot_longer(names_to = "genome",
                 values_to = "orientation",
                 cols = colnames(expanded)[-1])
  return(long_matches)
}

map_chromosomes <- function(matches){
  expanded <- expand_chr_names(matches) 
  orientation <- expand_orientation(matches)
  full <- full_join(expanded, orientation, by=c("HOM", "genome"))
  return(full)
}

plot_mapping <- function(chromosome_maps){
  ggplot(full,
         aes(x = genome, stratum = chromosome, alluvium = HOM,
             fill = HOM, label = paste0(chromosome, " ", orientation))) +
    geom_flow(stat = "alluvium", lode.guidance = "frontback", alpha = 0.7) +
    geom_stratum() +
    geom_text(stat = "stratum", size = 3) +
    theme_minimal() +
    ggtitle("Blueberry Chromosome Mapping Across Reference Assemblies") +
    theme(legend.position = "none",
          axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(hjust = 0.5))
}

test <- map_chromosomes(matches)
plot_mapping(test)
