
<!-- README.md is generated from README.Rmd. Please edit that file -->

# TSM

<!-- badges: start -->

[![R-CMD-check](https://github.com/sung/TSM/workflows/R-CMD-check/badge.svg)](https://github.com/sung/TSM/actions)
<!-- badges: end -->

This package, TSM (aka. The
[Smith](https://www.obgyn.cam.ac.uk/staff/senior-staff/professor-gordon-smith/)
Method), is to select a desired number of features (4 by default) by
purposefully dropping highly correlated ones, *i.e,* picking up highly
representative features that can best explain the binary outcomes. In
plain English, it works like the follwoing: The first representative
feature is the one that shows the highest AUC (Area Under the ROC Curve)
out of all the features. The next representative feature is the one that
shows the highest AUC out of the remaing features after dropping highly
correlated features with the first representative feature. The third,
the fourth, and so on, represenative feature will be picked up as the
same way the 2nd is picked up.

By default, `spearman` correlation coefficient is used to check the
correlation among the possible features and they will be dropped if they
are above a certain threshold (e.g. 0.5) by leaving a represenative one
having the best AUC. It recursively checks their correlations and drops
the feature until nothing left to check. By default, the thresholds for
the correlation coefficients are set from 0.1 (i.e. highly stringent by
leaving less features) to 0.7 (i.e. less stringent by leaving more
features) by increasing 0.1 at each step.

## Installation

You can install the development version of TSM like so:

``` r
devtools::install_github("sung/TSM")
```

## Example

The input file should have features as columns, including the outcome
column (`y` by default) which contains a binary outcome, either `0` or
`1`. For example:

``` r
library(TSM)
input=read.csv(system.file("extdata","demo_input.csv",package="TSM")) # read the example input from TSM 
input[1:5,]
#>       F1     F2     F3     F4     F5     F6     F7     F8     F9    F10    F11
#> 1 3.0978 5.3539 3.4697 3.3862 6.5225 1.3523 1.4245 2.2792 0.5276 2.6810 2.4484
#> 2 3.1000 5.6593 3.7335 3.2010 6.9357 1.2460 1.6861 2.3034 0.7733 2.6492 2.4600
#> 3 3.6803 5.4233 3.8745 3.3044 5.7258 1.1525 1.3389 2.2688 0.4059 2.6794 1.6202
#> 4 3.0374 5.7566 3.4998 3.2889 6.0595 1.4913 1.5907 2.1947 0.3826 1.4088 1.3074
#> 5 3.3356 5.0057 3.1617 3.0673 5.0654 0.7485 1.1178 1.6380 0.3623 1.7394 1.2593
#>      F12    F13    F14     F15    F16    F17    F18    F19    F20    F21 y
#> 1 1.7607 1.6585 2.5810 -2.5896 8.4015 3.5893 3.2906 2.0396 1.0402 7.9531 1
#> 2 1.7252 1.3809 2.6356 -1.0027 8.3084 3.7016 3.9182 2.4075 0.7266 8.2472 1
#> 3 1.1248 1.0232 1.8736 -2.8647 8.3134 2.6569 3.7619 2.0328 0.8711 7.9282 0
#> 4 1.7147 1.2212 2.2696 -1.1208 8.0433 3.6225 3.6321 2.2341 0.9412 7.8447 1
#> 5 1.6505 0.8490 1.7405 -2.0821 7.4438 2.6039 2.0825 0.4843 0.5597 7.6459 1
```

``` r
TSM(x=input) # run TSM with default parameters
#> calculating AUC for each features...
#> cor0.1
#> cor0.2
#> cor0.3
#> cor0.4
#> cor0.5
#> cor0.6
#> cor0.7
#>    Cor Num features                                                 Features
#> 1: 0.4            4                                             F1,F7,F8,F14
#> 2: 0.5            7                                  F1,F7,F13,F8,F9,F14,F15
#> 3: 0.7           16 F1,F4,F6,F5,F7,F13,F8,F9,F12,F11,F14,F15,F21,F17,F18,F20
#> 4: 0.6           11                   F1,F5,F7,F13,F8,F9,F14,F15,F21,F17,F18
#> 5: 0.1            1                                                       F1
#> 6: 0.2            1                                                       F1
#> 7: 0.3            1                                                       F1
#>    Best features      AIC      BIC       AUC AUC(LPOCV)
#> 1:  F1,F7,F8,F14 106.9498 120.8872 0.8815629  0.8659951
#> 2:  F1,F7,F13,F8 108.8605 122.7980 0.8806471  0.8580586
#> 3:   F1,F4,F6,F5 111.8757 125.8131 0.8684371  0.8489011
#> 4:  F1,F5,F7,F13 111.5937 125.5312 0.8666056  0.8476801
#> 5:            F1 113.1852 118.7602 0.8446276  0.8446276
#> 6:            F1 113.1852 118.7602 0.8446276  0.8446276
#> 7:            F1 113.1852 118.7602 0.8446276  0.8446276

TSM(x=input, corr=c(0.4, 0.5)) # two correlation coefficients only 
#> calculating AUC for each features...
#> cor0.4
#> cor0.5
#>    Cor Num features                Features Best features      AIC      BIC
#> 1: 0.4            4            F1,F7,F8,F14  F1,F7,F8,F14 106.9498 120.8872
#> 2: 0.5            7 F1,F7,F13,F8,F9,F14,F15  F1,F7,F13,F8 108.8605 122.7980
#>          AUC AUC(LPOCV)
#> 1: 0.8815629  0.8659951
#> 2: 0.8806471  0.8580586

TSM(x=input, corr=c(0.4, 0.5),k=3) # two correlation coefficients and three features only 
#> calculating AUC for each features...
#> cor0.4
#> cor0.5
#>    Cor Num features                Features Best features      AIC      BIC
#> 1: 0.4            4            F1,F7,F8,F14      F1,F7,F8 107.8816 119.0316
#> 2: 0.5            7 F1,F7,F13,F8,F9,F14,F15     F1,F7,F13 109.9227 121.0727
#>          AUC AUC(LPOCV)
#> 1: 0.8751526  0.8635531
#> 2: 0.8659951  0.8528694

TSM(x=input, corr=c(0.4, 0.5),k=3,method="pearson") # pearson method  
#> calculating AUC for each features...
#> cor0.4
#> cor0.5
#>    Cor Num features       Features Best features      AIC      BIC       AUC
#> 1: 0.5            4 F1,F13,F15,F18    F1,F13,F15 107.7559 118.9058 0.8736264
#> 2: 0.4            3     F1,F11,F14    F1,F11,F14 109.9812 121.1312 0.8672161
#>    AUC(LPOCV)
#> 1:  0.8574481
#> 2:  0.8489011
```

As shown above, `TSM` returns a table (`data.table`) by descending order
of Leave-Pair-Out-Cross-Validation (LPOCV) [Gordon Am J Epi
2014](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4108045/) at each
threshold of correlation coefficients.

In case you’d like more verbose version of outcomes:

``` r
foo<-TSM(x=input,corr=c(0.4,0.5),k=3,verbose=T)
#> calculating AUC for each features...
#> cor0.4
#> cor0.5

foo[["cor0.4"]]
#> $top.rank
#> [1] "F1"  "F7"  "F8"  "F14"
#> 
#> $cor
#>  [1] "F1"  "F2"  "F3"  "F4"  "F5"  "F6"  "F9"  "F10" "F11" "F12" "F13" "F15"
#> [13] "F16" "F17" "F18" "F19" "F21" "F7"  "F8"  "F14"
#> 
#> $num.cor
#> [1] 17  1  1  1
#> 
#> $fit
#> 
#> Call:  glm(formula = y ~ ., family = "binomial", data = my.data)
#> 
#> Coefficients:
#> (Intercept)           F1           F7           F8  
#>      15.134       -2.530       -2.577       -1.531  
#> 
#> Degrees of Freedom: 119 Total (i.e. Null);  116 Residual
#> Null Deviance:       155.4 
#> Residual Deviance: 99.88     AIC: 107.9
foo[["cor0.5"]]
#> $top.rank
#> [1] "F1"  "F7"  "F13" "F8"  "F9"  "F14" "F15"
#> 
#> $cor
#>  [1] "F1"  "F2"  "F3"  "F4"  "F5"  "F6"  "F10" "F12" "F16" "F17" "F19" "F7" 
#> [13] "F18" "F11" "F13" "F8"  "F9"  "F21" "F14" "F15"
#> 
#> $num.cor
#> [1] 11  2  2  1  2  1  1
#> 
#> $fit
#> 
#> Call:  glm(formula = y ~ ., family = "binomial", data = my.data)
#> 
#> Coefficients:
#> (Intercept)           F1           F7          F13  
#>      14.162       -2.756       -2.368       -1.268  
#> 
#> Degrees of Freedom: 119 Total (i.e. Null);  116 Residual
#> Null Deviance:       155.4 
#> Residual Deviance: 101.9     AIC: 109.9

data.table::rbindlist(foo[["performance"]])[order(-`AUC(LPOCV)`)]
#>    Cor Num features                Features Best features      AIC      BIC
#> 1: 0.4            4            F1,F7,F8,F14      F1,F7,F8 107.8816 119.0316
#> 2: 0.5            7 F1,F7,F13,F8,F9,F14,F15     F1,F7,F13 109.9227 121.0727
#>          AUC AUC(LPOCV)
#> 1: 0.8751526  0.8635531
#> 2: 0.8659951  0.8528694
```
