test_that("a column merely containing the letter 'y' is not mistaken for the outcome", {
  x <- make_input()
  names(x)[names(x) == "F3"] <- "myelin"

  # no 'y' column at all, but 'myelin' contains a "y"
  expect_error(TSM(x[, c("F1", "myelin")]), "must have a column named 'y'")
  expect_error(get_LPOCV(x[, c("F1", "myelin")]), "must have a column named 'y'")
})

test_that("a feature whose name contains 'y' is kept as a candidate feature", {
  x <- make_input()
  names(x)[names(x) == "F3"] <- "myelin"

  # corr = 0.99 drops nothing, so every feature must appear as a representative
  res <- suppressMessages(TSM(x, corr = 0.99))
  picked <- strsplit(res$Features, ",")[[1]]

  expect_true("myelin" %in% picked)
  expect_setequal(picked, feature_names(x))
})

test_that("the outcome column is validated", {
  x <- make_input()

  expect_error(TSM(x[, feature_names(x)]), "must have a column named 'y'")
  expect_error(TSM(as.matrix(x)), "must be a data.frame")

  x_na <- x; x_na$y[1] <- NA
  expect_error(TSM(x_na), "must not contain NA")
  expect_error(get_LPOCV(x_na[, c("F1", "y")]), "must not contain NA")

  x_three <- x; x_three$y[1] <- 2
  expect_error(TSM(x_three), "must contain both 0 and 1")

  x_one <- x; x_one$y <- 1
  expect_error(TSM(x_one), "must contain both 0 and 1")

  # a warning-free rejection: the old recycling comparison warned instead
  expect_silent(try(TSM(x_three), silent = TRUE))
})

test_that("non-numeric features are rejected with a clear message", {
  x <- make_input()
  x$F4 <- as.character(x$F4)
  expect_error(suppressMessages(TSM(x)), "is.numeric")
})
