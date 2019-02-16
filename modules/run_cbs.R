## The Broad Institute
## SOFTWARE COPYRIGHT NOTICE AGREEMENT
## This software and its documentation are copyright (2011) by the
## Broad Institute/Massachusetts Institute of Technology. All rights are
## reserved.
##
## This software is supplied without any warranty or guaranteed support
## whatsoever. Neither the Broad Institute nor MIT can be responsible for its
## use, misuse, or functionality.

## Run example: Rscript run_cbs.R --args hg18_TEST12_nolocs.filtered.rda test.txt array.name 0.01

RunCbs <- function(in.file, out.file, sample.name, param.alpha = 0.01) {
  set.seed(0)
  suppressMessages(require("DNAcopy"))|| stop("DNAcopy required for RunCbs")

  # require("magrittr") || stop("magrittr required for RunCbs")
  # require("dplyr") || stop("dplyr required for RunCbs")
  # require("stringr") || stop("stringr required for RunCbs")
  # require("readr") || stop("readr required for RunCbs")
  
  # param.alpha default value set at 0.01

  if (is.character(in.file)){
    if(grepl('.rda$', in.file, ignore.case=T)){
      load(in.file)
      dat_input <- NULL
    } else{
      # from exome samples that did not go through liftover
      # dat_input <- read_delim(in.file, '\t', col_types = cols(.default = 'd', Marker = 'c', Chromosome = 'c', PhysicalPosition ='i')) %>%
        #dplyr::rename(Chrom = Chromosome, Location = PhysicalPosition )
      dat_input <- read.delim(in.file, '\t', header = T, stringsAsFactors = F)
      newColNames <- sub('Chromosome', 'Chrom', colnames(dat_input))
      newColNames <- sub('PhysicalPosition', 'Location', newColNames)
    }
  } #else if (is.data.frame(in.file)){
    
    # UNNECESSARY: dat_input <- in.file
  #}
  
  if(!is.null(dat_input)){
    if('Chrom' %in% colnames(dat_input)){
      dat <- as.data.frame(dat_input)
    } else{
      # dat <- dat_input %>%
      # mutate(
      #   Chrom = str_extract(Marker, "^\\d+|\\w+"),
      #   Location = str_extract(Marker, ":\\d+") %>% str_replace_all(':', '')
      # ) %>%
      # as.data.frame()
      dat <- dat_input
      dat$Chrom <- gsub(':\\d+-\\d+$', '', dat$Marker)
      dat$Location <- gsub('^\\d+|\\w+:|-\\d+$', '', dat$Marker)
    }
    
    colnames(dat) <- gsub('\\.', '-', colnames(dat))
    sample.name <- gsub('\\.', '-', sample.name)
  }
  
  dats <- as.numeric(dat[, sample.name])
  chrom <- dat[, "Chrom"]
  pos <- as.numeric(dat[, "Location"])
  marker <- dat[, "Marker"]
  
  dats <- if (is.vector(dats)) {
    apply(as.matrix(dats), c(1, 2), log2)
  } else {
    apply(dats, c(1, 2), log2)
  }
  dats <- apply(dats, c(1, 2), function(x){
    x - 1
  })
  
  cna.object <- suppressMessages(CNA(dats, chrom, pos, data.type="logratio",
                    sampleid=sample.name))
  smoothed.cna.object <- smooth.CNA(cna.object)
  segment.smoothed.cna.object <- segment(smoothed.cna.object,
                                         min.width=2, verbose=2,
                                         nperm=10000, alpha=param.alpha,
                                         undo.splits="sdundo",
                                         undo.prune=0.05, undo.SD=1)
  
  ## We need to use X/Y instead of 23/24 in terms of official output
  chroms <- segment.smoothed.cna.object[["output"]][, "chrom"]
  chroms <- gsub("23", "X", chroms)
  chroms <- gsub("24", "Y", chroms)
  segment.smoothed.cna.object[["output"]][, "chrom"] <- chroms
  
  ## Change the column names to match what submission should be
  new.col.names <- c("Sample", "Chromosome", "Start", "End", "Num_Probes",
                     "Segment_Mean")
  colnames(segment.smoothed.cna.object[["output"]]) <- new.col.names
  
  write.table(segment.smoothed.cna.object[["output"]],
              out.file, sep="\t", row.names=FALSE,
              col.names=TRUE, quote=FALSE)
  
  # return(segment.smoothed.cna.object[["output"]])
}

options(error=expression(q(status=1)))
args <- commandArgs(trailingOnly=TRUE)
RunCbs(args[2], args[3], args[4], args[5])
