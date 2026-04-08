test_that("sort_genomes groups by chromosome naming pattern", {
  genome_stats <- data.frame(
    genome = c("A", "A", "B", "B", "C", "C"),
    chromosome = c("1", "2", "1", "2", "1", "3"),
    value = c(10, 20, 11, 21, 5, 15)
  )

  grouped <- sort_genomes(genome_stats)
  sizes <- sort(vapply(grouped, nrow, integer(1)))

  expect_equal(length(grouped), 2)
  expect_equal(sizes, c(2, 4))
})

test_that("genome_consensus averages chromosome values across genomes", {
  grouped <- data.frame(
    genome = c("A", "B", "A", "B"),
    chromosome = c("1", "1", "2", "2"),
    value = c(10, 20, 30, 40)
  )

  consensus <- genome_consensus(grouped)

  expect_equal(consensus$chromosome, c("1", "2"))
  expect_equal(consensus$value, c(15, 35))
})
