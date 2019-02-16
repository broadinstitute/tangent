## The Broad Institute
## SOFTWARE COPYRIGHT NOTICE AGREEMENT
## This software and its documentation are copyright (2011) by the
## Broad Institute/Massachusetts Institute of Technology. All rights are
## reserved.
##
## This software is supplied without any warranty or guaranteed support
## whatsoever. Neither the Broad Institute nor MIT can be responsible for its
## use, misuse, or functionality.

## Run example: Rscript check_suspect_normals_length.R --args suspect_normals.txt disruption_scores.txt sif.txt

check_suspect_normals_length <- function(suspect_normals_filename, disruption_scores_filename, sif_filename) {
  
  #require("magrittr") || stop("magrittr required for check_suspect_normals_length")
  #require("dplyr") || stop("dplyr required for check_suspect_normals_length")
  #require("stringr") || stop("stringr required for check_suspect_normals_length")
  #require("readr") || stop("readr required for check_suspect_normals_length")
  
  if(file.info(suspect_normals_filename)$size == 0){
      cat("There are no suspect normals.\n")
      numSuspectNorms = 0
  } else{
      sn_file <- tryCatch(read.delim(suspect_normals_filename, '\t', header = T, sep='\t', stringsAsFactors = F))
      numSuspectNorms = dim(sn_file)[1]
  }
  ds_file <- read.delim(disruption_scores_filename, '\t', header = T, sep='\t', stringsAsFactors = F)  
  sif_file <- read.delim(sif_filename, '\t', header = T, sep='\t', stringsAsFactors = F)  
  
  # sn_file <- read_delim(suspect_normals_filename, '\t', col_types = "c")
  # ds_file <- read_delim(disruption_scores_filename, '\t', n_max = 1, col_names = F, col_types = 'cd')
  # sif_file <- read_delim(sif_filename, '\t', col_types = "cc")
  sif_file.normals <- subset(sif_file, TUMOR_NORMAL == 'Normal')
      
  # cat('Threshold for disruption_scores:', ds_file$X2, '\n')
  cat('Threshold for disruption_scores:', sub('^X', '', colnames(ds_file)[2]), '\n')
  cat("There are", numSuspectNorms, "suspect normals out of a total of",
      dim(sif_file.normals)[1], "normals.\n")
  
  
}

options(error=expression(q(status=1)))
args <- commandArgs(trailingOnly=TRUE)
check_suspect_normals_length(args[2], args[3], args[4])
