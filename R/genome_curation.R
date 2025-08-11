
# soybean <- ncbi_genome_stats("glycine max")
# maize <- ncbi_genome_stats("zea mays")
# wheat <- ncbi_genome_stats("triticum aestivum")
# potato <- ncbi_genome_stats("solanum tuberosum")
# cotton <- ncbi_genome_stats("gossypium hirsutum")
# canola <- ncbi_genome_stats("brassica napus")
# rice <- ncbi_genome_stats("oryza sativa")
# rubus <- ncbi_genome_stats("rubus")
# vaccinium <- ncbi_genome_stats("vaccinium") This one breaks for some reason
# sweet_cherry <- ncbi_genome_stats("prunus avium")
# sour_cherry <- ncbi_genome_stats("prunus cerasus") probably no hits
# apple <- ncbi_genome_stats("malus domestica")
# gold_kiwi <- ncbi_genome_stats("actinidia chinensis")
# green_kiwi <- ncbi_genome_stats("actinidia deliciosa")
# radiata_pine <- ncbi_genome_stats("pinus radiata")
# radiata_meta <- ncbi_genome_metadata("pinus radiata")
# muscadine_grape <- ncbi_genome_stats("vitis rotundifolia")
# european_grape <- ncbi_genome_stats("vitis vinifera")

#' Expand chromosome names in matches
#' 
#' This function transforms genome signature comparison output to a long format
#' 
#' @param matches A data frame containing genome matches from `compare_genome_sigs`
#' @import dplyr
#' @import tidyr
#' @importFrom stringr str_sort
#' @export

expand_chr_names <- function(matches){
  genomes <- unique(c(matches$genome1, matches$genome2))
  genomes_split <- split(matches, matches$genome2)
  test <- sapply(genomes_split, function(x){
    as.character(x$match_chr_name)
  })
  expanded <- cbind(unlist(genomes_split[[1]][,12]), test)
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

#' Map chromosomes in genome matches for homology visualization
#' 
#' This function prepares genome comparison data for visualization by mapping chromosomes and their order patterns.
#' 
#' @param matches A data frame containing genome matches from `compare_genome_sigs`
#' @import dplyr
#' @import tidyr
#' @importFrom stringr str_remove str_sort

map_chromosomes <- function(matches){
  expanded <- expand_chr_names(matches) 
  genome_order_patterns <- expanded %>%
    arrange(genome, HOM) %>%
    group_by(genome) %>%
    summarise(order_pattern = paste(chromosome, collapse = "-")) %>%
    ungroup()
  query_accessions <- select(matches, query, genome1, query_chr_name) %>%
    distinct() %>%
    setNames(c("accession", "genome", "chromosome"))
  match_accessions <- select(matches, match, genome2, match_chr_name) %>%
    setNames(c("accession", "genome", "chromosome"))
  accessions <- rbind(query_accessions, match_accessions) %>%
    mutate(chromosome = factor(chromosome))
  full <- left_join(expanded, genome_order_patterns, by = c("genome")) %>%
    left_join(accessions, by = c("genome", "chromosome")) %>%
    mutate(genome = factor(genome, levels = unique(genome[order(order_pattern)])),
           HOM_chr = case_when(
             as.numeric(HOM) %% 2 == 0 ~ as.character(as.numeric(HOM)/2),
             as.numeric(HOM) %% 2 == 1 ~ as.character((as.numeric(HOM)+1)/2)
           ),
           chr = str_remove(chromosome, "_(.*)"),
           chr = factor(chr, levels = str_sort(unique(chr), numeric = T)))
  return(full)
}
