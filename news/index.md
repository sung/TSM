# Changelog

## TSM 0.0.0.9000

### Bug fixes

- The outcome column is now matched exactly.
  [`TSM()`](../reference/TSM.md) and
  [`get_LPOCV()`](../reference/get_LPOCV.md) used to locate it with
  `grepl("y", colnames(x))`, so any feature whose name merely contained
  the letter “y” (`myelin`, `density`, …) was silently treated as the
  outcome and dropped from the candidate features, and a data.frame with
  no `y` column at all could pass validation.

- Every feature is now considered as a possible representative. The
  selection loop stopped one feature short, so the last survivor could
  never be picked no matter how good its AUC (on the bundled demo input,
  `F19` was never looked at). The single-remaining-feature case that the
  old guard was working around is now handled explicitly.

- Missing values no longer break the run. Correlations use
  `use = "pairwise.complete.obs"` with an explicit `NA` guard on the
  threshold test, and models are fitted (and scored) on complete cases,
  so the final `roc()` call no longer fails with “Response and predictor
  must be vectors of the same length”.

- The outcome column is validated properly: `y` containing `NA` is now
  rejected, and a `y` holding values other than `0`/`1` raises a clear
  error instead of a vector-recycling warning. Non-numeric feature
  columns and a missing `y` also get explicit messages.

- [`get_LPOCV()`](../reference/get_LPOCV.md) returns a plain unnamed
  scalar rather than a value named `"TRUE"`, and selects each
  case/control pair by row position, so non-contiguous or non-numeric
  row names no longer matter.

- A zero-variance feature no longer sends the selection loop spinning
  forever.

### Other changes

- Added a `testthat` suite covering the above.

- Declared the `stats` and `utils` imports that were previously missing,
  and fixed an `.Rbuildignore` pattern that was shipping `TSM.note.R` in
  the tarball. `R CMD check` is now clean.

- Corrected the documentation for [`TSM()`](../reference/TSM.md): `x` is
  a `data.frame` (not a path to a file) and the default `method` is
  `spearman` (not `pearson`). Documented that correlations are computed
  on the cases only, and that the reported `AUC(LPOCV)` stays optimistic
  because feature selection is not nested inside the cross-validation.

### Initial release

- An initially release with a minimum working example.
