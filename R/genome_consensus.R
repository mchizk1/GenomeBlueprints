
#' Sorts genomes
#' 
#' This function sorts genome versions based on similarity and returns a list of matching genomes.
#' 
#' @param genome_stats A data frame containing genome lengths returned by `ncbi_genome_stats`
#' @return A list of genome names sorted by similarity
#' @importFrom dplyr group_by
#' @importFrom dplyr summarise
#' @importFrom dplyr filter
#' @importFrom dplyr pull

sort_genomes <- function(genome_stats) {
  # Sort genomes by length and return unique names
  genome_groups <- genome_stats %>%
    group_by(genome) %>%
    summarise(chr_names = paste(unique(chromosome), collapse = "_"))
  sorted_genomes <- list()
  i <- 1
  for (group in unique(genome_groups$chr_names)) {
    group_genomes <- genome_groups %>%
      filter(chr_names == group) %>%
      pull(genome)
    sorted_genomes[[paste0("v", i)]] <- genome_stats %>%
      filter(genome %in% group_genomes)
    i <- i + 1
  }
  return(sorted_genomes)
}

#' Physical consensus genomes
#' 
#' This function generates a consensus genome based on the physical chromosome lengths of multiple genomes.
#' 
#' @param genome_sorted A list of sorted genomes, each containing chromosome names and lengths
#' @return A consensus genome with averaged chromosome lengths
#' @importFrom dplyr group_by
#' @importFrom dplyr summarise
#' @importFrom dplyr ungroup

genome_consensus <- function(genome_sorted) {
  if(length(unique(genome_sorted$genome)) == 1){
    genome_i <- genome_sorted %>%
      select(chromosome, value)
  } else {
    genome_i <- genome_sorted %>%
      group_by(chromosome) %>%
      summarise(value = mean(value, na.rm = TRUE)) %>%
      ungroup()
  }
  return(genome_i)
}
