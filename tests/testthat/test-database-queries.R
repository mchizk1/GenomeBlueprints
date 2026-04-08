test_that("ncbi_genome_stats_and_metadata drops unmatched metadata genomes", {
  local_mocked_bindings(
    ncbi_genome_stats = function(taxonomy, key, allow_n_chr) {
      data.frame(
        chromosome = c("1", "2"),
        stat = c("total-length", "total-length"),
        value = c(10, 20),
        genome = c("GenomeA", "GenomeA"),
        chr_id = c("chrA1", "chrA2")
      )
    },
    ncbi_genome_metadata = function(taxonomy, key) {
      data.frame(
        genome = c("GenomeA", "GenomeB"),
        assembly_accession = c("A1", "B1"),
        submitterorganization = c("OrgA", "OrgB"),
        assembly_type = c("Chromosome", "Scaffold"),
        date = c("2024-01-01", "2024-01-02"),
        species = c("SpecA", "SpecB"),
        speciestaxid = c(1, 2)
      )
    }
  )

  expect_warning(
    out <- ncbi_genome_stats_and_metadata("Taxon", "key", allow_n_chr = 2),
    "dropped"
  )
  expect_equal(unique(out$metadata$genome), "GenomeA")
  expect_equal(unique(out$metadata$taxonomic_group), "Taxon")
})
