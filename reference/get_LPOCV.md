# Leave Pair Out Cross Validation

This function returns an optimism-adjusted c-stat. Read more by [Gordon
Am J Epi 2014](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4108045/).

## Usage

``` r
get_LPOCV(x)
```

## Arguments

- x:

  A data.frame holding the binary outcome column `y` (either `0` or `1`)
  and one or more predictor columns. Rows with any missing value are
  dropped before fitting.

## Value

a single (unnamed) numeric value of LPOCV

## Examples

``` r
input=read.csv(system.file("extdata","demo_input.csv",package="TSM")) # read the example input 
get_LPOCV(x=input[,c("F1","y")]) # get LPOCV of "F1" as a sole predictor
#> [1] 0.8446276

get_LPOCV(x=input[,c("F1","F2","y")]) # get LPOCV of "F1" and "F2" as two predictors
#> [1] 0.8501221
```
