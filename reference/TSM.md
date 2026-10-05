# The Smith Method

This function TSM (aka. The Smith Method) selects a desired number of
features (4 by default) by purposefully dropping highly correlated
features, *i.e,* picking up a set of representative features that can
best explain the binary outcomes. In a plain language, it works like the
follwoing: The first representative feature is the one that shows the
highest AUC (Area Under the ROC Curve) out of all the features. The next
representative feature is the one that shows the highest AUC out of the
remaing features after dropping highly correlated features with the
first representative feature. The third, the fourth, and so on,
represenative feature will be picked up as the same way the 2nd is
picked up.

## Usage

``` r
TSM(
  x,
  method = "spearman",
  corr = seq(0.1, 0.7, by = 0.1),
  k = 4,
  verbose = FALSE
)
```

## Arguments

- x:

  A data.frame with the features as columns plus a binary outcome column
  `y` (either `0` or `1`). All feature columns must be numeric. Missing
  values are allowed and are handled pairwise for the correlations and
  dropped row-wise when fitting a model.

- method:

  A Character either `spearman` (default) or `pearson`, which is the
  same paramter `method` for
  [`cor()`](https://rdrr.io/r/stats/cor.html).

- corr:

  A numeric vector for the thresholds of correlation coefficients.

- k:

  The number of desicred features (default:4)

- verbose:

  Boolean

## Value

a data.table (default) or a list of data.table (verbose=T)

## Details

Note that the correlations between features are calculated on the cases
(`y == 1`) only, and that the feature selection is carried out on the
whole of `x`. The reported `AUC(LPOCV)` therefore remains optimistic, as
the selection step itself is not nested inside the cross-validation.

## Examples

``` r
input=read.csv(system.file("extdata","demo_input.csv",package="TSM")) # read the example input 
TSM(x=input) # run TSM with default parameters
#> calculating AUC for each features...
#> cor0.1
#> cor0.2
#> cor0.3
#> cor0.4
#> cor0.5
#> cor0.6
#> cor0.7
#>      Cor Num features
#>    <num>        <int>
#> 1:   0.4            5
#> 2:   0.5            8
#> 3:   0.3            2
#> 4:   0.7           17
#> 5:   0.6           12
#> 6:   0.1            1
#> 7:   0.2            1
#>                                                        Features Best features
#>                                                          <char>        <char>
#> 1:                                             F1,F7,F8,F14,F20  F1,F7,F8,F14
#> 2:                                  F1,F7,F13,F8,F9,F14,F15,F20  F1,F7,F13,F8
#> 3:                                                       F1,F20        F1,F20
#> 4: F1,F4,F6,F5,F7,F13,F8,F9,F12,F11,F14,F15,F21,F17,F18,F20,F19   F1,F4,F6,F5
#> 5:                   F1,F5,F7,F13,F8,F9,F14,F15,F21,F17,F18,F20  F1,F5,F7,F13
#> 6:                                                           F1            F1
#> 7:                                                           F1            F1
#>         AIC      BIC       AUC AUC(LPOCV)
#>       <num>    <num>     <num>      <num>
#> 1: 106.9498 120.8872 0.8815629  0.8659951
#> 2: 108.8605 122.7980 0.8806471  0.8580586
#> 3: 110.6632 119.0257 0.8605006  0.8531746
#> 4: 111.8757 125.8131 0.8684371  0.8489011
#> 5: 111.5937 125.5312 0.8666056  0.8476801
#> 6: 113.1852 118.7602 0.8446276  0.8446276
#> 7: 113.1852 118.7602 0.8446276  0.8446276

TSM(x=input, corr=c(0.4, 0.5)) # two correlation coefficients only 
#> calculating AUC for each features...
#> cor0.4
#> cor0.5
#>      Cor Num features                    Features Best features      AIC
#>    <num>        <int>                      <char>        <char>    <num>
#> 1:   0.4            5            F1,F7,F8,F14,F20  F1,F7,F8,F14 106.9498
#> 2:   0.5            8 F1,F7,F13,F8,F9,F14,F15,F20  F1,F7,F13,F8 108.8605
#>         BIC       AUC AUC(LPOCV)
#>       <num>     <num>      <num>
#> 1: 120.8872 0.8815629  0.8659951
#> 2: 122.7980 0.8806471  0.8580586

TSM(x=input, method="pearson") # pearson method for cor()
#> calculating AUC for each features...
#> cor0.1
#> cor0.2
#> cor0.3
#> cor0.4
#> cor0.5
#> cor0.6
#> cor0.7
#>      Cor Num features                                               Features
#>    <num>        <int>                                                 <char>
#> 1:   0.6           10                    F1,F7,F13,F8,F9,F16,F14,F15,F17,F20
#> 2:   0.3            2                                                 F1,F20
#> 3:   0.5            5                                     F1,F13,F15,F18,F20
#> 4:   0.4            4                                         F1,F11,F14,F20
#> 5:   0.7           15 F1,F5,F7,F13,F8,F9,F12,F11,F14,F15,F21,F17,F18,F20,F19
#> 6:   0.1            1                                                     F1
#> 7:   0.2            1                                                     F1
#>     Best features      AIC      BIC       AUC AUC(LPOCV)
#>            <char>    <num>    <num>     <num>      <num>
#> 1:   F1,F7,F13,F8 108.8605 122.7980 0.8806471  0.8580586
#> 2:         F1,F20 110.6632 119.0257 0.8605006  0.8531746
#> 3: F1,F13,F15,F18 108.2224 122.1599 0.8717949  0.8522589
#> 4: F1,F11,F14,F20 109.9902 123.9276 0.8748474  0.8513431
#> 5:   F1,F5,F7,F13 111.5937 125.5312 0.8666056  0.8476801
#> 6:             F1 113.1852 118.7602 0.8446276  0.8446276
#> 7:             F1 113.1852 118.7602 0.8446276  0.8446276
```
