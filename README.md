# Tangent

This repository contains the code for running the Tangent copy number inference pipeline. (manuscript in submission) 

We also provide the option of Pseudo-Tangent, a modification of the Tangent pipeline that enables denoising through comparisons between tumor profiles when only a few normal samples are available.

## To run:
### System requirements:
* Docker Desktop: https://www.docker.com/products/docker-desktop (either Desktop Community or Desktop Enterprise should work well)

Since Tangent is built to run within a Docker container, the container should contain all other relevant requirements and packages.

### 1. Clone/Download this repository to your local drive:

If you are new to GitHub, please check out these articles on how to clone a Github repository: 
* https://help.github.com/en/articles/cloning-a-repository
* https://help.github.com/en/articles/which-remote-url-should-i-use

If you choose to download this repository instead of cloning it by using the "Download ZIP" button, please note that the file ./matlab_2010b/MCRInstaller.bin will not be downloaded completely in the ZIP file. The MCRInstaller.bin file is currently hosted on Git LFS instead of GitHub because of its large file size. This seems to be a known issue with files hosted on Git LFS (https://github.com/git-lfs/git-lfs/issues/903). 

A workaround would be to download this file directly through the "Download" button on this page: https://github.com/broadinstitute/tangent/blob/master/matlab_2010b/MCRInstaller.bin

Bottom line is, please make sure your local copy of ./matlab_2010b/MCRInstaller.bin is 221MB in file size (instead of 134 bytes) to ensure a successful run of Tangent.

### 2. Prepare input files:
The input files (*./sampledata/mysif.txt* and *./sampledata/mydata.DOC_interval.avg_cvg.txt*) are only provided for formatting references. __TANGENT CANNOT BE RUN ON THESE SAMPLE FILES.__ Please supply your own input SIF and coverage-data files according to these formats. If you are starting with a whole-exome .bam file, you can run the GATK DepthOfCoverage tool (available on https://software.broadinstitute.org/gatk/documentation/tooldocs/3.8-0/org_broadinstitute_gatk_tools_walkers_coverage_DepthOfCoverage.php or as available on FireCloud https://portal.firecloud.org/) to generate *.DOC_interval.avg_cvg.txt .


### 3. Modify line 59 of Dockerfile to designate parameters for the run:

_line 58:_
```
ENTRYPOINT ["bash", "-c", "./wrapper_overall.sh -m $MCRROOT -i $0 -o $1 -s $2 -d $3 -t $4 -p $5 -c $6 -a $7 -n $8 -e $9 -x ${10} -y ${11} -z ${12} -r ${13}"]
```
_line 59:_
```
CMD ["/opt/data/", "/opt/result/", "/opt/sampledata/mysif.txt", "/opt/sampledata/mydata.DOC_interval.avg_cvg.txt", "run1", "exome", "0.23", "0.01", "2", "150", "true", "true", "true", "None"]
```

* Substitute /opt/sampledata/mysif.txt with /opt/<_path to your sif file_> 
* Substitute /opt/sampledata/mydata.DOC_interval.avg_cvg.txt with /opt/<_path to your data file_>
* Examples of SIF and DATA file formats are provided in ./sampledata
* If you would like to run Pseudo-Tangent, use "true" for argument 12 (-z for doPseudoTangent)

**Note on Reference Plane:**
* If doGenRefPlane (Step 1) is set to "true", a reference plane will be generated and can be used in Tangent (Step 2). 
* You may also choose to provide your own reference plane for the Tangent run (Step 2), irrespective of whether doGenRefPlane is set to "true" or "false". If you would like to provide a reference plane, please supply your reference plane directory path to the last argument (argument ${13}) as "/opt/<_your reference plane directory_>". 
* If you are not providing your own reference plane, please make sure the -r argument has a value of "None" or "none". The argument of "" will not work. Another way will be to get rid of "-r" such that your ENTRYPOINT and CMD lines (lines 58-59) look like:
```
ENTRYPOINT ["bash", "-c", "./wrapper_overall.sh -m $MCRROOT -i $0 -o $1 -s $2 -d $3 -t $4 -p $5 -c $6 -a $7 -n $8 -e $9 -x ${10} -y ${11} -z ${12}"]

CMD ["/opt/data/", "/opt/result/", "/opt/sampledata/mysif.txt", "/opt/sampledata/mydata.DOC_interval.avg_cvg.txt", "run1", "exome", "0.23", "0.01", "2", "150", "true", "true", "true"]
```


### 4. Run:

```
docker build -t tangent .
docker rm tangentcont
docker run --name tangentcont -t tangent
docker ps
mkdir ./tangent_output
docker cp tangentcont:/opt/result ./tangent_output
ls ./tangent_output
```

## Troubleshooting
### #1. Killed job
We have found that sometimes if you are running Tangent on a sample size that is too big, you may run into memory issues with Docker. The error you get might look something like this:
```
Step 1: Preliminary preparation of single array list
...end of Step 1.
Step 2: Run all plates through early_gistic_prep.m


./modules/run_generate_reference_plane.sh: line 36:    32 Killed                  
```
Solution: You may manually override the default resource allocation from Docker and increase the CPUs or Memory that you would like Docker to use. (*Docker >> Preferences >> Advanced*) This issue and its potential solutions are also described here: https://stackoverflow.com/questions/44417159/docker-process-killed-with-cryptic-killed-message 


### #2. MCRInstaller.bin version not found
You may run into the following error if your local copy of ./matlab_2010b/MCRInstaller.bin is 134bytes instead of 221MB in file size:
```
> docker build -t tangent .
...
./matlab_2010b/MCRInstaller.bin: 1: ./matlab_2010b/MCRInstaller.bin: version: not found
./matlab_2010b/MCRInstaller.bin: 2: ./matlab_2010b/MCRInstaller.bin: oid: not found
size: '231966720': No such file             
...
```
Reason: The file ./matlab_2010b/MCRInstaller.bin was not downloaded completely with "Download ZIP" because this file is currently hosted on Git LFS instead of GitHub. 

Solution: Please re-read Step 1 of this guide or download this file directly through the "Download" button on this page: https://github.com/broadinstitute/tangent/blob/master/matlab_2010b/MCRInstaller.bin


### #3. Error: Matrix dimensions must agree.
As you run Tangent, you may run into the following MATLAB error:
```
> docker run --name tangentcont -t tangent
...
??? Error using ==> times
Matrix dimensions must agree.          
...
```
Reason: While there are many potential reasons for "Matrix dimensions must agree", the most common reason is from using our provided sample input files (*./sampledata/mysif.txt* and *./sampledata/mydata.DOC_interval.avg_cvg.txt*). These files are provided so you could reference the file formats. However, the paucity of data in these files will cause Tangent to fail. Unfortunately, we do not currently provide a true sample BAM/coverage file.

Solution: Please re-read Step 2 of this guide and supply your own SIF and coverage files. You can convert a .bam file to the coverage file using the GATK DepthOfCoverage tool (available on https://software.broadinstitute.org/gatk/documentation/tooldocs/3.8-0/org_broadinstitute_gatk_tools_walkers_coverage_DepthOfCoverage.php or as available on FireCloud https://portal.firecloud.org/).

Note: If you are already supplying your own coverage files and are still receiving this error, please contact us at the email below so we could help with troubleshooting.

## Feedback / Suggestions? 
We welcome any contributions you may have. Please direct any questions or feedback to coyinoh [at] broadinstitute [dot] org.
