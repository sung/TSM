test_that("get_LPOCV returns a bare numeric scalar in [0, 1]", {
  x <- make_input()
  res <- get_LPOCV(x[, c("F1", "y")])

  expect_type(res, "double")
  expect_length(res, 1L)
  expect_null(names(res)) # used to come back named "TRUE" from table()
  expect_gte(res, 0)
  expect_lte(res, 1)
})

test_that("a perfectly separating predictor gives a c-stat of 1", {
  x <- make_input()
  x$F1 <- x$y * 10 + seq_len(nrow(x)) / 1000 # cases always rank above controls
  expect_equal(get_LPOCV(x[, c("F1", "y")]), 1)
})

test_that("an informative predictor beats a noise predictor", {
  x <- make_input()
  expect_gt(get_LPOCV(x[, c("F1", "y")]), get_LPOCV(x[, c("F4", "y")]))
})

test_that("rows with missing values are dropped rather than breaking the fit", {
  x <- make_input()
  x$F1[c(1, 2, 25)] <- NA

  expect_silent(res <- get_LPOCV(x[, c("F1", "y")]))
  expect_length(res, 1L)
  expect_false(is.na(res))
  # equivalent to having removed those rows up front
  expect_equal(res, get_LPOCV(x[-c(1, 2, 25), c("F1", "y")]))
})

test_that("pairs are selected by position, not by row name", {
  x <- make_input()
  ref <- get_LPOCV(x[, c("F1", "y")])

  # non-contiguous row names, as left behind by any upstream subsetting
  x_gappy <- x
  rownames(x_gappy) <- as.character(seq(1, by = 7, length.out = nrow(x)))
  expect_equal(get_LPOCV(x_gappy[, c("F1", "y")]), ref)

  # non-numeric row names
  x_named <- x
  rownames(x_named) <- paste0("sample_", seq_len(nrow(x)))
  expect_equal(get_LPOCV(x_named[, c("F1", "y")]), ref)
})

test_that("multiple predictors are accepted", {
  x <- make_input()
  res <- get_LPOCV(x[, c("F1", "F3", "y")])
  expect_length(res, 1L)
  expect_false(is.na(res))
})

test_that("at least one predictor is required", {
  x <- make_input()
  expect_error(get_LPOCV(x[, "y", drop = FALSE]))
})
