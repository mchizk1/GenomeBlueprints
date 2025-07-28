genera <- list.files()
inputs <- data.frame(taxon =c("vaccinium",
                              "rubus",
                              "daucus",
                              "citrus",
                              "actinidia",
                              "vitis rotundifolia",
                              "capsicum",
                              "solanum tuberosum",
                              "solanum lycopersicum"), 
                     chr_n = c(12, 7, 9, 9, 29, 20, 12, 12, 12))
for(i in 1:length(genera)){
  setwd(genera[i])
  genome_data <- ncbi_genome_stats_and_metadata(inputs$taxon[i],
    "65616ab544c7cabd7d5937012f92119f3908", inputs$chr_n[i])
  matches <- try(compare_genome_sigs(genome_data$stats), silent = TRUE)
  if(inherits(matches, "try-error")) {
    message(paste("Error processing", genera[i], ":", matches))
    next
  }
  write.csv(matches, paste0(genera[i], "_matches.csv"), row.names = FALSE)
  rm(genome_data, matches)
  gc()
  setwd("~/../Desktop/GitHub/GenomeBlueprints/Sigs/")
}
