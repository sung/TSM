# https://tinyheero.github.io/jekyll/update/2015/07/26/making-your-first-R-package.html
#https://kbroman.org/pkg_primer/pages/depends.html

library(devtools)

name<-"TSM"
path<-file.path("~/Devel/Rpkg",name)

use_devtools()

devtools::create(path)
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
#use_package("data.table") # does not work with imports 
use_package("data.table")
use_package("pROC")
use_tidy_description()

# moved to TSM/ and work on R/TSM.R
devtools::document()

devtools::load_all()
devtools::install()

devtools::check()

#
use_readme_rmd()
#use_readme_md()
devtools::build_readme()

use_news_md()

# pkgdown
use_pkgdown()
build_site()
