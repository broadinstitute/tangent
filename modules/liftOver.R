## The Broad Institute
## SOFTWARE COPYRIGHT NOTICE AGREEMENT
## This software and its documentation are copyright (2011) by the
## Broad Institute/Massachusetts Institute of Technology. All rights are
## reserved.
##
## This software is supplied without any warranty or guaranteed support
## whatsoever. Neither the Broad Institute nor MIT can be responsible for its
## use, misuse, or functionality.

## File I/O - currently has txt & rda, can use R.matlab
## for .mat files (sort of)

ReadPipelineFile <- function(file.name, parser=TextPipelineFileReader, ...) {
  if (!file.exists(file.name)) {
    stop("No such file: ", file.name)
  }
  return(read.delim(file.name, as.is=TRUE, ...))
}

ReadLocsFile <- function(file.name) {
  ## Allow for different parsing on locations file
  locs <- ReadPipelineFile(file.name, header=FALSE)
  colnames(locs) <- c("Marker", "Chrom", "Location")
  return(locs)
}

## Data manipulation
XYToNumeric <- function(chrom) {
  chrom <- gsub("X", 23, chrom)
  chrom <- gsub("Y", 24, chrom)
  return(as.numeric(chrom))
}

CheckMarkers <- function(dat, locs) {
  if (any(duplicated(locs[, "Marker"]))) {
    stop("Markers in the location file must be unique")
  }
  if (!all(dat[, "Marker"] %in% locs[, "Marker"])) {
    stop("Markers do not match between input and genomic data")
  } 
  return(TRUE)
}

GenomicLiftover <- function(dat.file.name, out.dir,
                            loc.file.names,
                            warn.on.mismatch=TRUE) {
  ## dat.file.name: file name of the input data
  ## loc.file.names: a *NAMED* vector of location file names,
  ##      with the names representing a tag to apply to that
  ##      location's merged output file (e.g. 'hg18' = 'hg18_locs.rda')
  if (length(names(loc.file.names)) != length(loc.file.names)) {
    stop("loc.file.names must be named")
  }
  
  orig.dat <- ReadPipelineFile(dat.file.name)
  
  for (loc.name in names(loc.file.names)) {
    dat <- orig.dat
    locs <- ReadLocsFile(loc.file.names[[loc.name]])
    CheckMarkers(dat, locs)

    locs[, "Chrom"] <- XYToNumeric(locs[, "Chrom"])
    locs <- locs[with(locs, order(Chrom, Location)), ]

    if (!setequal(locs[, "Marker"], dat[, "Marker"])) {
      if (warn.on.mismatch) {
        warning("Markers do not match between data and locations file, ",
                "taking the intersection")
      }
      markers <- intersect(locs[, "Marker"], dat[, "Marker"])
    } else {
      markers <- locs[, "Marker"]
    }
    locs <- locs[match(markers, locs[, "Marker"]), ]
    dat <- dat[match(markers, dat[, "Marker"]), ]
    dat <- cbind(locs, dat[match(locs[["Marker"]],
                                     dat[["Marker"]]), -1])
    
    split <- strsplit(basename(dat.file.name), "\\.")[[1]]
    name <- paste(split[1:(length(split)-1)], collapse=".")
    fn <- file.path(out.dir, paste(name, "_", loc.name, ".rda",
                                   sep=""))
    save(dat, file=fn)
  }

  return(TRUE)
}

## NOTE: Needs to call stripLocation.R first
## Rscript liftOver.R --args infile.txt outdir hg18=hg18File hg19=hg19FIle
args <- commandArgs(trailingOnly=TRUE)

if (!length(args) > 3) {
  stop("No genomic locations specified")
}

locs <- character()
splitLocStrs <- strsplit(args[4:length(args)], "=")
for (i in seq_along(splitLocStrs)) {
  splitLocStr <- splitLocStrs[[i]]
  if (length(splitLocStr) != 2) {
    stop("Malformed genomic location specified: ", args[2+i])
  }
  locs <- c(locs, splitLocStr[2])
  names(locs)[length(locs)] <- splitLocStr[1]
}

GenomicLiftover(args[2], args[3], locs)
