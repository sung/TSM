# https://tinyheero.github.io/jekyll/update/2015/07/26/making-your-first-R-package.html
#https://kbroman.org/pkg_primer
#https://rpubs.com/stephenknapp/how-to-create-an-r-package

library(devtools)

name<-"TSM"
path<-file.path("~/Devel/Rpkg",name)

use_devtools()

#devtools::create(path)
create_package(path)
project_activate(path)

###########
# License #
###########
use_mit_license()

#############
## Authors ##
#############
use_author("foo","bar") # does not seem to work

#############
## Imports ##
#############
use_pipe()
use_package("data.table",min_version=T)
use_package("pROC",min_version=T)
use_package("magrittr",min_version=T)
use_tidy_description() 

############
# R source #
############
use_r("TSM")

#########
# Build #
#########
# work on R/TSM.R
devtools::document()

devtools::load_all()
devtools::check()
devtools::install()

##########
# README #
##########
use_readme_rmd()
#use_readme_md()
build_readme()

use_news_md()

###########
# pkgdown #
###########
use_pkgdown()
build_site()

####### 
# GIT #
####### 
use_pkgdown_github_pages() # internally calls the below
#use_github_pages()
#use_github_action()
use_github_action("pkgdown")

# 
use_github_links(overwrite=T)
