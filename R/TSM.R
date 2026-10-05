# the data.table columns below are non-standard evaluation, invisible to R CMD check
globalVariables(c("ID", "auc", "AUC(LPOCV)"))

#' Leave Pair Out Cross Validation
#'
#' This function returns an optimism-adjusted c-stat. Read more by [Gordon Am J Epi 2014](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4108045/).
#' @param x A data.frame holding the binary outcome column `y` (either `0` or
#'   `1`) and one or more predictor columns. Rows with any missing value are
#'   dropped before fitting.
#' @return a single (unnamed) numeric value of LPOCV
#' @examples
#' input=read.csv(system.file("extdata","demo_input.csv",package="TSM")) # read the example input 
#' get_LPOCV(x=input[,c("F1","y")]) # get LPOCV of "F1" as a sole predictor
#'
#' get_LPOCV(x=input[,c("F1","F2","y")]) # get LPOCV of "F1" and "F2" as two predictors
#' @importFrom stats complete.cases glm predict
#' @export
get_LPOCV<-function(x){
  check_input(x)
  stopifnot(ncol(x) >= 2) # should have at least one predictor

  my.data<-x[complete.cases(x), , drop=FALSE] # isa data.frame
  rownames(my.data)<-NULL # index by position, not by (possibly duplicated) rownames
  my.data$y<-factor(ifelse(my.data$y==1,'case','non_case'),levels=c("non_case","case")) # the outcome

  # case-control grid (row positions, so duplicated rownames cannot mis-select a pair)
  myGrid<-expand.grid(
      case=which(my.data$y=="case"),
      control=which(my.data$y=="non_case")
  )
  stopifnot(nrow(myGrid) > 0) # need at least one case and one non-case left

  out<-apply(myGrid, 1, function(i){
      pair<-as.integer(i)
      fit<-glm(y~. , data = my.data[-pair, , drop=FALSE], family = "binomial") # fit the model based on the remaining
      predict(fit, newdata=my.data[pair, , drop=FALSE], type="response") # predict the outcome of the pair using the model above
  })

  # the proportion of all pairwise combinations in which the predicted probability was greater for the case than for the control 
  return(sum(out[1,] > out[2,]) / ncol(out))
} # end of LPOCV


#' The Smith Method
#' 
#' This function TSM (aka. The Smith Method) selects a desired number of features (4 by default) by purposefully dropping highly correlated features, *i.e,* picking up a set of representative features that can best explain the binary outcomes. In a plain language, it works like the follwoing: The first representative feature is the one that shows the highest AUC (Area Under the ROC Curve) out of all the features. The next representative feature is the one that shows the highest AUC out of the remaing features after dropping highly correlated features with the first representative feature. The third, the fourth, and so on, represenative feature will be picked up as the same way the 2nd is picked up.
#'
#' Note that the correlations between features are calculated on the cases
#' (`y == 1`) only, and that the feature selection is carried out on the whole
#' of `x`. The reported `AUC(LPOCV)` therefore remains optimistic, as the
#' selection step itself is not nested inside the cross-validation.
#' @param x A data.frame with the features as columns plus a binary outcome column `y` (either `0` or `1`). All feature columns must be numeric. Missing values are allowed and are handled pairwise for the correlations and dropped row-wise when fitting a model.
#' @param method A Character either `spearman` (default) or `pearson`, which is the same paramter `method` for `cor()`.
#' @param corr A numeric vector for the thresholds of correlation coefficients.  
#' @param k The number of desicred features (default:4)
#' @param verbose Boolean
#' @return a data.table (default) or a list of data.table (verbose=T)
#' @examples
#' input=read.csv(system.file("extdata","demo_input.csv",package="TSM")) # read the example input 
#' TSM(x=input) # run TSM with default parameters
#'
#' TSM(x=input, corr=c(0.4, 0.5)) # two correlation coefficients only 
#'
#' TSM(x=input, method="pearson") # pearson method for cor()
#' @import data.table 
#' @import magrittr
#' @importFrom stats BIC complete.cases cor fitted glm setNames
#' @importFrom utils globalVariables
#' @export 
TSM<-function(x,method="spearman",corr=seq(0.1,0.7,by=0.1),k=4,verbose=FALSE){
  check_input(x)

  IDs=setdiff(colnames(x),"y") # exact match: a feature such as 'myelin' is *not* the outcome
  stopifnot(length(IDs) >= 1) # should have at least one feature
  stopifnot(all(vapply(x[IDs], is.numeric, logical(1)))) # cor() needs numeric features
  stopifnot(is.numeric(k), length(k)==1, k >= 1)
  cases<-x[,"y"]==1
  li.top.rank<-list()

  message("calculating AUC for each features...")
  foo<-list()
  for(my.ID in IDs){
      my.mat<-x[,c("y",my.ID)] 
      my.mat<-my.mat[complete.cases(my.mat), , drop=FALSE] # in case of NA in the input
      my.model<-glm(y ~., data=my.mat, family="binomial")

      # ROC & AUC 
      #predict(my.model,type=c("response"))  # probability
      #fitted(my.model) # same as above
      my.mat$prob<-fitted(my.model)
      my.roc <- pROC::roc(y ~ prob, data = my.mat, quiet=TRUE)
      foo[[my.ID]] <- data.table(ID=my.ID, auc=as.numeric(my.roc$auc))
  } # end of for   
  dt.auc<-rbindlist(foo)[order(-auc)]

  # for each level of correlation
  for(my.cor in corr){
    cor.index<-paste0("cor",my.cor)
    message(cor.index)

    top.rank<-character(0)  # the representative features, best AUC first
    seen<-character(0)      # features already accounted for (representative, or correlated with one)
    num.cor<-integer(0)

    # keep going until *every* feature is accounted for
    while(length(seen) < length(IDs)){
        features<-IDs[!IDs %in% seen] # drop highly correlated features (i.e. non-highly correlated features)
        this.top<-dt.auc[ID %in% features]$ID[1]
        if(length(features)==1L){
            hi.cor.feature<-features # nothing left to correlate it against; cor() needs >= 2 columns
        }else{
            mat.cor<-cor(x[cases,features,drop=FALSE],method=method,use="pairwise.complete.obs")
            mat.cor<-setNames(as.vector(mat.cor[this.top,]), colnames(mat.cor))
            hi.cor<-!is.na(mat.cor) & abs(mat.cor) > my.cor
            #mat.cor[hi.cor]
            # union() keeps the representative itself in the set even when its
            # self-correlation is NA (a constant feature), which would otherwise loop forever
            hi.cor.feature<-union(this.top, names(mat.cor)[hi.cor])
        }
        top.rank<-c(top.rank,this.top)
        seen<-c(seen,hi.cor.feature)
        num.cor<-c(num.cor,length(hi.cor.feature))
    } # end of while

    li.top.rank[[cor.index]][["top.rank"]]<-top.rank
    li.top.rank[[cor.index]][["cor"]]<-seen
    li.top.rank[[cor.index]][["num.cor"]]<-num.cor

    ##########################################
    # Performance of k features in the model #
    ##########################################
    num.features<-min(k,length(top.rank))
    my.features<-top.rank[seq_len(num.features)]
    my.data=x[,c("y",my.features)] # olink NPX of the features
    my.data=my.data[complete.cases(my.data), , drop=FALSE] # glm() drops these rows anyway
    my.fit<-glm(y~. , data = my.data, family = "binomial") # fit the model based on the selected features
    li.top.rank[[cor.index]][["fit"]]<-my.fit

    # get the model performance
    li.top.rank[["performance"]][[cor.index]]<-data.table(
                                                        Cor=my.cor,
                                                        `Num features`=length(top.rank),
                                                        Features=paste(top.rank,collapse=","),
                                                        `Best features`=paste(my.features,collapse=","),
                                                        AIC=my.fit$aic,
                                                        BIC=BIC(my.fit),
                                                        AUC=as.numeric(pROC::roc(response=my.data$y, predictor=fitted(my.fit), quiet=TRUE)$auc),
                                                        `AUC(LPOCV)`=get_LPOCV(my.data)
                                                        )
  } # end of for(my.cor)

  if(verbose){
    return(li.top.rank)
  }else{
    return(rbindlist(li.top.rank[["performance"]])[order(-`AUC(LPOCV)`)])
  }
} # end of TSM

# Shared validation of the input data.frame and its binary outcome column.
check_input<-function(x){
  arg<-deparse(substitute(x))
  if(!is.data.frame(x)) stop(arg, " must be a data.frame", call.=FALSE)
  if(!"y" %in% colnames(x)) stop(arg, " must have a column named 'y'", call.=FALSE)
  y<-x[["y"]]
  if(anyNA(y)) stop("the outcome column 'y' must not contain NA", call.=FALSE)
  if(!setequal(unique(y), c(0,1))) stop("the outcome column 'y' must contain both 0 and 1, and nothing else", call.=FALSE)
  invisible(TRUE)
}
