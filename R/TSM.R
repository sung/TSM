#' Leave Pair Out Cross Validation
#'
#' This function returns an optimism-adjusted c-stat. Read more by [Gordon Am J Epi 2014](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4108045/).
#' @param x data.frame
#' @return a numeric value of LPOCV 
#' @examples
#' input=read.csv(system.file("extdata","demo_input.csv",package="TSM")) # read the example input 
#' get_LPOCV(x=input[,c("F1","y")]) # get LPOCV of "F1" as a sole predictor
#'
#' get_LPOCV(x=input[,c("F1","F2","y")]) # get LPOCV of "F1" and "F2" as two predictors
#' @export
get_LPOCV<-function(x){
  stopifnot(is.data.frame(x))
  stopifnot(any(grepl("y",colnames(x)))) # should have the column 'y'
  stopifnot(all(sort(unique(x[,"y"]))==c(0,1))) # should be '0' and '1'
  my.data=x  # isa data.frame
  my.data$y<-factor(ifelse(my.data$y==1,'case','non_case'),levels=c("non_case","case")) # the outcome

  # case-control grid
  myGrid<-expand.grid(
      rownames(my.data[my.data$y=="case",]),
      rownames(my.data[my.data$y=="non_case",])
  )

  out<-apply(myGrid, 1, function(i){
      my.data1<-my.data[as.vector(t(i)),] # a pair of case-control
      my.data2<-my.data[!rownames(my.data) %in% as.vector(t(i)),] # the remaining (excluding the pair)

      fit<-glm(y~. , data = my.data2, family = "binomial") # fit the model based on the remaining
      predict.glm(fit, newdata=my.data1, type="response") # predict the outcome of the pair using the model above
      #roc(response=my.data2$y, predictor=fitted(fit))$auc
  })

  # the proportion of all pairwise combinations in which the predicted probability was greater for the case than for the control 
  c.stat<-table(apply(out,2, function(i) i[1] > i[2]))
  return(c.stat["TRUE"] / sum(c.stat))
} # end of LPOCV


#' The Smith Method
#' 
#' This function TSM (aka. The Smith Method) selects a desired number of features (4 by default) by purposefully dropping highly correlated features, *i.e,* picking up a set of representative features that can best explain the binary outcomes. In a plain language, it works like the follwoing: The first representative feature is the one that shows the highest AUC (Area Under the ROC Curve) out of all the features. The next representative feature is the one that shows the highest AUC out of the remaing features after dropping highly correlated features with the first representative feature. The third, the fourth, and so on, represenative feature will be picked up as the same way the 2nd is picked up.
#' @param x Path to the input file 
#' @param method A Character either `pearson` (default) or `spearman`, which is the same paramter `method` for `cor()`.
#' @param corr A numeric vector for the thresholds of correlation coefficients.  
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
#' @export 
TSM<-function(x,method="spearman",corr=seq(0.1,0.7,by=0.1),k=4,verbose=F){
  stopifnot(is.data.frame(x))
  stopifnot(any(grepl("y",colnames(x)))) # should have the column 'y'
  stopifnot(all(sort(unique(x[,"y"]))==c(0,1))) # should be '0' and '1'

  IDs=colnames(x)[!grepl("y",colnames(x))]
  cases<-x[,"y"]==1
  li.top.rank<-list()

  message("calculating AUC for each features...")
  foo<-list()
  for(my.ID in IDs){
      my.mat<-x[,c("y",my.ID)] 
      my.model<-glm(y ~., data=my.mat, family="binomial")

      # ROC & AUC 
      #predict(my.model,type=c("response"))  # probability
      #fitted(my.model) # same as above
      my.prob<-fitted(my.model)
      # in case of NA in the input
      if(nrow(my.mat)!=length(my.prob)){
          dt.prob<-rbind(
          data.table(`index`=as.numeric(names(my.prob)),`prob`=my.prob),
          data.table(`index`=as.numeric(my.mat[,my.ID] %>% is.na %>% which), `prob`=NA)
          )[order(index)]
          my.prob<-dt.prob$prob
      }
      my.mat$prob<-my.prob
      my.roc <- pROC::roc(y ~ prob, data = my.mat, quiet=T)
      foo[[my.ID]] <- data.table(ID=my.ID, auc=my.roc$auc)
  } # end of for   
  dt.auc<-rbindlist(foo)[order(-auc)]

  # for each level of correlation
  for(my.cor in corr){
    cor.index<-paste0("cor",my.cor)
    message(cor.index)

    # round 1
    top.rank<-dt.auc[1]$ID
    mat.cor<-cor(x[cases,IDs],method=method)[top.rank,]
    hi.cor<-abs(mat.cor) > my.cor
    #mat.cor[hi.cor]
    hi.cor.feature<-names(mat.cor[hi.cor])
    li.top.rank[[cor.index]][["top.rank"]]<-top.rank
    li.top.rank[[cor.index]][["cor"]]<-hi.cor.feature
    li.top.rank[[cor.index]][["num.cor"]]<-length(hi.cor.feature)

    # round >=2
    while(length(li.top.rank[[cor.index]][["cor"]]) < length(IDs) -1){
        #print(paste0("round:",round))
        features<-IDs[!IDs %in% li.top.rank[[cor.index]][["cor"]]] # drop highly correlated features (i.e. non-highly correlated features)
        top.rank<-dt.auc[ID %in% features]$ID[1]
        mat.cor<-cor(x[cases,features],method=method)[top.rank,]
        hi.cor<-abs(mat.cor) > my.cor
        #mat.cor[hi.cor]
        hi.cor.feature<-names(mat.cor[hi.cor])
        li.top.rank[[cor.index]][["top.rank"]]<-c(li.top.rank[[cor.index]][["top.rank"]],top.rank)
        li.top.rank[[cor.index]][["cor"]]<-c(li.top.rank[[cor.index]][["cor"]],hi.cor.feature)
        li.top.rank[[cor.index]][["num.cor"]]<-c(li.top.rank[[cor.index]][["num.cor"]],length(hi.cor.feature))
    } # end of while

    ##########################################
    # Performance of k features in the model #
    ##########################################
    num.features<-ifelse(length(li.top.rank[[cor.index]][["top.rank"]])>=k,k,length(li.top.rank[[cor.index]][["top.rank"]]))
    my.features<-li.top.rank[[cor.index]][["top.rank"]][1:num.features]
    my.data=x[,c("y",my.features)] # olink NPX of the features
    my.fit<-glm(y~. , data = my.data, family = "binomial") # fit the model based on the selected features
    li.top.rank[[cor.index]][["fit"]]<-my.fit

    # get the model performance
    li.top.rank[["performance"]][[cor.index]]<-data.table(
                                                        Cor=my.cor,
                                                        `Num features`=length(li.top.rank[[cor.index]][["top.rank"]]),
                                                        Features=paste(li.top.rank[[cor.index]][["top.rank"]],collapse=","),
                                                        `Best features`=paste(my.features,collapse=","),
                                                        AIC=my.fit$aic,
                                                        BIC=BIC(my.fit),
                                                        AUC=pROC::roc(response=x$y, predictor=fitted(my.fit), quiet=T)$auc,
                                                        `AUC(LPOCV)`=get_LPOCV(my.data)
                                                        )
  } # end of for(my.cor)

  if(verbose){
    return(li.top.rank)
  }else{
    return(rbindlist(li.top.rank[["performance"]])[order(-`AUC(LPOCV)`)])
  }
} # end of TSM

