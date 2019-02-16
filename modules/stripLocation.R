## The Broad Institute
## SOFTWARE COPYRIGHT NOTICE AGREEMENT
## This software and its documentation are copyright (2011) by the
## Broad Institute/Massachusetts Institute of Technology. All rights are
## reserved.
##
## This software is supplied without any warranty or guaranteed support
## whatsoever. Neither the Broad Institute nor MIT can be responsible for its
## use, misuse, or functionality.

StripLocation <- function(dat.file, out.file) {
  ## Assumes a file with the first column being markers, second columns being chromosome
  ## and the third being location. Columns four+ are data
  #require("dplyr") || stop("dplyr required for stripLocation")
  #require("magrittr") || stop("magrittr required for stripLocation")
  #require("readr") || stop("readr required for stripLocation")
  
  dat <- read.delim(dat.file, as.is=TRUE, check.names = F) 
  wantedCols <- colnames(dat)[c(1, 4:length(colnames(dat)))]
  dat_stripped <- dat[,wantedCols]
  
  #dat <- read_delim(dat.file, '\t', col_types = cols(.default = 'd', Marker = 'c', Chromosome = 'c', PhysicalPosition = 'i')) %>%
  		 #dplyr::select(-Chromosome, -PhysicalPosition)
  write.table(dat_stripped, file=out.file, quote=FALSE, sep="\t", row.names=FALSE)
}

## Rscript stripLocation.R infile.txt outfile.txt
args <- commandArgs(trailingOnly=TRUE)

if (!length(args) == 3) {
  stop("Malformed arguments")
}

StripLocation(args[2], args[3])
