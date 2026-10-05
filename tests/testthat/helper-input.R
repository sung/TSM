# A small, deterministic input: F2 is a near-duplicate of F1, F4 is pure noise.
# Kept small on purpose -- get_LPOCV() fits one glm per case/control pair -- and
# deliberately noisy so the logistic fits converge without separation warnings.
make_input <- function(n_case = 12, n_ctrl = 24, seed = 1) {
  set.seed(seed)
  n <- n_case + n_ctrl
  y <- c(rep(1, n_case), rep(0, n_ctrl))
  F1 <- y + stats::rnorm(n, 0, 1.3)   # informative
  F2 <- F1 + stats::rnorm(n, 0, 0.35) # highly correlated with F1
  F3 <- y + stats::rnorm(n, 0, 2.2)   # weakly informative
  F4 <- stats::rnorm(n)               # noise
  data.frame(F1 = F1, F2 = F2, F3 = F3, F4 = F4, y = y)
}

feature_names <- function(x) setdiff(colnames(x), "y")
