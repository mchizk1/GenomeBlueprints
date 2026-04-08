test_that("expand_chr_names returns long-format chromosome mappings", {
  matches <- data.frame(
    query = c("q1", "q2"),
    genome1 = c("G1", "G1"),
    query_chr_name = c("Chr1", "Chr2"),
    match = c("m1", "m2"),
    genome2 = c("G2", "G2"),
    match_chr_name = c("Chr1", "Chr2"),
    c7 = 1,
    c8 = 1,
    c9 = 1,
    c10 = 1,
    c11 = 1,
    c12 = c("Chr1", "Chr2")
  )

  long <- expand_chr_names(matches)

  expect_true(all(c("HOM", "genome", "chromosome") %in% names(long)))
  expect_equal(nrow(long), 4)
  expect_equal(length(unique(long$HOM)), 2)
})
