## The Broad Institute
## SOFTWARE COPYRIGHT NOTICE AGREEMENT
## This software and its documentation are copyright (2011) by the
## Broad Institute/Massachusetts Institute of Technology. All rights are
## reserved.
##
## This software is supplied without any warranty or guaranteed support
## whatsoever. Neither the Broad Institute nor MIT can be responsible for its
## use, misuse, or functionality.

## wrapper_cbs_in_parallel: Wrapper script for run_cbs.R 
## This script is not mandatory for running run_cbs.R, it is only a wrapper script 
## that is useful for executing run_cbs.R in parallel.  (to save time and increase speed)
## Run example: Rscript wrapper_cbs_in_parallel.R --args ${woCNVFNnoGPrda} ${SifFile] ${OutputDir}/CBS/ ${ModuleDir}/cbs/run_cbs.R woCNV 25 0.01
 

call_cbs <- function(input_filename, output_dir, mySample, cbs_path, wCNV_tag, param.alpha=0.01){
 
  mySampleDash <- gsub('\\.', '-', mySample)
  
  if(wCNV_tag == 'wCNV'){
  	outfile <- paste0(output_dir, mySampleDash, '_wCNV_hg19.cbs')
  } else if (wCNV_tag == 'woCNV'){
  	outfile <- paste0(output_dir, mySampleDash, '_woCNV_hg19.cbs')
  } else {
  	outfile <- paste0(output_dir, mySampleDash, '.cbs')
  }
  

  #if(!file.exists(outfile)){
  system(paste('Rscript', cbs_path, '--args', input_filename, outfile, mySample, param.alpha))
  #}
  
}

ParallelCbs <- function(input_filename, sif_filename, output_dir, cbs_path, wCNV_tag, core_num, param.alpha=0.01){
# 	require("magrittr") || stop("magrittr required for wrapper_cbs_in_parallel")
#   	require("dplyr") || stop("dplyr required for wrapper_cbs_in_parallel")
#   	require("stringr") || stop("stringr required for wrapper_cbs_in_parallel")
#   	require("readr") || stop("readr required for wrapper_cbs_in_parallel")
  	require("doParallel") || stop("doParallel required for wrapper_cbs_in_parallel")
	
	if(!file.exists(output_dir)){
		dir.create(output_dir, recursive = T)
	}

	sif_file <- read.delim(sif_filename, '\t', stringsAsFactors = F, header = T)

	list_of_samples <- sif_file$Array

	res <- mclapply(list_of_samples, function(x) call_cbs(input_filename, output_dir, x, cbs_path, wCNV_tag, param.alpha), mc.cores = core_num)
}

options(error=expression(q(status=1)))
args <- commandArgs(trailingOnly=TRUE)
ParallelCbs(args[2], args[3], args[4], args[5], args[6], args[7], args[8])