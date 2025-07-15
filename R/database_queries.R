
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
#' @return A data.frame containing genome statistics including genome name and physical chromosome lengths
#' @examples kiwi <- ncbi_genome_stats("Actinidia chinensis")
#' @export

ncbi_genome_stats <- function(taxa, key){
  set_entrez_key(key)
  ncbi_id <- get_uid(taxa)
  search_results <- entrez_search(
    db = "assembly",
    term = paste0("txid", ncbi_id, "[Organism:exp]"),
    retmax = 1000
  )
  assembly_summaries <- entrez_summary(db = "assembly", id = search_results$ids, version = "2.0")
  if (length(search_results$ids) == 1) {
    assembly_summaries <- list(assembly_summaries)
    names(assembly_summaries) <- search_results$ids
  }
  assemblies <- names(assembly_summaries)
  stats_ftps <- sapply(assemblies, function(x) assembly_summaries[[x]]$ftppath_stats_rpt)
  id_ftps <- sapply(assemblies, function(x) assembly_summaries[[x]]$ftppath_assembly_rpt)
  chrom_stats <- c()
  for (i in seq_along(stats_ftps)) {
    print(paste0("Assembly ", i, ": ", assembly_summaries[[i]]$assemblyname))
    assembly_i <- try(read.delim(stats_ftps[i], comment.char="#", header=FALSE) %>%
        filter(V3 == "Chromosome", V4 == "all", 
               V5 %in% c("total-length")) %>%
        mutate(genome = assembly_summaries[[i]]$assemblyname) %>%
        dplyr::select(V2, V5, V6, genome) %>%
        rename(chromosome = V2)
    )
    id_i <- try(read.delim(id_ftps[i], 
                           comment.char="#", header=FALSE) %>%
                  filter(V4 == "Chromosome", V2 == "assembled-molecule") %>%
                  select(V3, V5) %>%
                  rename(chromosome = V3, genbank_chr_id = V5))
    if(inherits(assembly_i, "try-error") | inherits(id_i, "try-error")) {
      warning(paste0("Failed to read assembly statistics for ", assembly_summaries[[i]]$assemblyname, ". Skipping."))
      next
    }
    assembly_i <- left_join(assembly_i, id_i, by = "chromosome")
    chrom_stats <- bind_rows(chrom_stats, assembly_i)
  }
  colnames(chrom_stats) <- c("chromosome", "stat", "value", "genome", "chr_id")
  return(chrom_stats)
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
#' @return A list containing genome assembly metadata
#' @examples kiwi <- ncbi_genome_metadata("Actinidia chinensis")
#' @export

ncbi_genome_metadata <- function(taxa, key){
  set_entrez_key(key)
  ncbi_id <- get_uid(taxa)
  search_results <- entrez_search(
    db = "assembly",
    term = paste0("txid", ncbi_id, "[Organism:exp]"),
    retmax = 1000
  )
  assembly_summaries <- entrez_summary(db = "assembly", 
                                       id = search_results$ids, 
                                       version = "2.0")
  if (length(search_results$ids) == 1) {
    assembly_summaries <- list(assembly_summaries)
    names(assembly_summaries) <- search_results$ids
  }
  assemblies <- names(assembly_summaries)
  genome_metadata <- c()
  for (i in seq_along(assemblies)) {
    print(paste0("Assembly ", i, ": ", assembly_summaries[[i]]$assemblyname))
    metadata_i <- data.frame(
      genome = assembly_summaries[[i]]$assemblyname,
      assembly_accession = assembly_summaries[[i]]$assemblyaccession,
      submitterorganization = assembly_summaries[[i]]$submitterorganization,
      assembly_type = assembly_summaries[[i]]$assemblytype,
      date = assembly_summaries[[i]]$seqreleasedate,
      species = assembly_summaries[[i]]$speciesname,
      speciestaxid = assembly_summaries[[i]]$taxid
    )
    genome_metadata <- bind_rows(genome_metadata, metadata_i)
  }
  return(genome_metadata)
}

#' Assemble complete NCBI stats for one taxonomic group
#' 
#' This function combines genome statistics and metadata from NCBI for a specified taxonomic group into a single data frame.
#' @param taxonomy A character string indicating the taxonomic group to query
#' @param key An character string for the NCBI API key
#' @return a list containing genome statistics and metadata
#' @export

ncbi_genome_stats_and_metadata <- function(taxonomy, key) {
  list(
    stats = ncbi_genome_stats(taxonomy, key),
    metadata = ncbi_genome_metadata(taxonomy, key)
  )
}
