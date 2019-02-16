## The Broad Institute
## SOFTWARE COPYRIGHT NOTICE AGREEMENT
## This software and its documentation are copyright (2011) by the
## Broad Institute/Massachusetts Institute of Technology. All rights are
## reserved.
##
## This software is supplied without any warranty or guaranteed support
## whatsoever. Neither the Broad Institute nor MIT can be responsible for its
## use, misuse, or functionality.

checkNSplit <- function(sifPath, nSplit=3, outputPathForNewNSplit) {
  # sifPath = path to sif file 
  # nSplit = number of groups to split into
  # nTumors = integer, total number of tumors in the sif file

  dat <- read.delim(sifPath, as.is=TRUE, check.names = F) 
  dat.tumor = subset(dat, TUMOR_NORMAL == 'Tumor')
  nTumors = dim(dat.tumor)[1]
  nSplit = as.numeric(nSplit)
  cat("There are", nTumors, 'tumors.\n')
  
  nDiv = nTumors/nSplit
  while( nDiv > 1 && nDiv < 2){
    cat("Reducing n_split...\n")
    nSplit = nSplit - 1
    nDiv = nTumors/nSplit
  }
  cat("New n_split: ", nSplit, '\n')
  write.table(nSplit, file = outputPathForNewNSplit, quote = F, row.names = F, col.names = F)      
  #return(nSplit)
}


## Rscript checkNSplit.R nTumors nSplit
args <- commandArgs(trailingOnly=TRUE)

if (!length(args) == 4) {
  stop("Malformed arguments")
}

checkNSplit(args[2], args[3], args[4])
