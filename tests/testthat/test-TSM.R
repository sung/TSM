test_that("TSM returns one row per correlation threshold with the documented columns", {
  x <- make_input()
  res <- suppressMessages(TSM(x, corr = c(0.4, 0.6)))

  expect_s3_class(res, "data.table")
  expect_named(res, c("Cor", "Num features", "Features", "Best features",
                      "AIC", "BIC", "AUC", "AUC(LPOCV)"))
  expect_equal(nrow(res), 2L)
  expect_setequal(res$Cor, c(0.4, 0.6))
  expect_false(anyNA(res$`AUC(LPOCV)`))
  expect_true(is.numeric(res$`AUC(LPOCV)`))
})

test_that("every feature is considered -- none is silently skipped", {
  x <- make_input()

  # nothing correlates above 0.99, so all features must become representatives
  res <- suppressMessages(TSM(x, corr = 0.99))
  expect_equal(res$`Num features`, length(feature_names(x)))
  expect_setequal(strsplit(res$Features, ",")[[1]], feature_names(x))

  # across any threshold, representatives plus pruned features cover everything
  det <- suppressMessages(TSM(x, corr = c(0.3, 0.7), verbose = TRUE))
  for (nm in c("cor0.3", "cor0.7")) {
    expect_setequal(det[[nm]][["cor"]], feature_names(x))
    expect_true(all(det[[nm]][["top.rank"]] %in% feature_names(x)))
    expect_false(anyDuplicated(det[[nm]][["top.rank"]]) > 0)
  }
})

test_that("a highly correlated feature is pruned in favour of its representative", {
  x <- make_input()
  res <- suppressMessages(TSM(x, corr = 0.5, verbose = TRUE))
  reps <- res$cor0.5$top.rank

  # F1 and F2 are near-duplicates, so only one of them may represent the pair
  expect_equal(sum(c("F1", "F2") %in% reps), 1L)
})

test_that("missing values in the features do not break the run", {
  x <- make_input()
  x$F1[1] <- NA
  x$F3[c(4, 5)] <- NA

  expect_error(suppressMessages(TSM(x, corr = 0.5)), NA)
  res <- suppressMessages(TSM(x, corr = 0.5))
  expect_equal(nrow(res), 1L)
  expect_false(is.na(res$AUC))
  expect_false(is.na(res$`AUC(LPOCV)`))
})

test_that("k caps the number of features entering the final model", {
  x <- make_input()

  for (k in c(1, 2, 4)) {
    res <- suppressMessages(TSM(x, corr = 0.99, k = k))
    expect_length(strsplit(res$`Best features`, ",")[[1]], k)
  }

  # k larger than the number of available features falls back to what there is
  res <- suppressMessages(TSM(x, corr = 0.99, k = 99))
  expect_length(strsplit(res$`Best features`, ",")[[1]], length(feature_names(x)))
})

test_that("verbose returns the per-threshold detail plus the performance table", {
  x <- make_input()
  res <- suppressMessages(TSM(x, corr = c(0.4, 0.6), verbose = TRUE))

  expect_type(res, "list")
  expect_setequal(names(res), c("cor0.4", "cor0.6", "performance"))
  expect_named(res$cor0.4, c("top.rank", "cor", "num.cor", "fit"))
  expect_s3_class(res$cor0.4$fit, "glm")
})

test_that("both correlation methods are accepted", {
  x <- make_input()
  expect_error(suppressMessages(TSM(x, corr = 0.5, method = "pearson")), NA)
  expect_error(suppressMessages(TSM(x, corr = 0.5, method = "spearman")), NA)
})

test_that("a constant feature does not send the selection loop spinning", {
  x <- make_input()
  x$F4 <- 1 # zero variance -> cor() is NA for every pair involving it

  res <- suppressMessages(suppressWarnings(TSM(x, corr = 0.5, verbose = TRUE)))
  expect_setequal(res$cor0.5$cor, feature_names(x))
  expect_true("F4" %in% res$cor0.5$top.rank)
})
