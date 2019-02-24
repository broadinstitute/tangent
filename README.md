# Tangent

This repository contains the code for running the Tangent copy number inference pipeline. (manuscript in submission) 
We also provide the option of Pseudo-Tangent, a modification of the Tangent pipeline that enables denoising through comparisons between tumor profiles when only a few normal samples are available.

## To run:
### 1. Clone/Download this repository to your local drive:

If you are new to GitHub, please check out these articles on how to clone a Github repository: 
* https://help.github.com/en/articles/cloning-a-repository
* https://help.github.com/en/articles/which-remote-url-should-i-use

If you choose to download this repository instead of cloning it by using the "Download ZIP" button, please note that the file ./matlab_2010b/MCRInstaller.bin will not be downloaded completely in the ZIP file. The MCRInstaller.bin file is currently hosted on Git LFS instead of GitHub because of its large file size. This seems to be a known issue with files hosted on Git LFS (https://github.com/git-lfs/git-lfs/issues/903). 

A workaround would be to download this file directly through the "Download" button on this page: https://github.com/coyin/tangent/blob/master/matlab_2010b/MCRInstaller.bin

Bottom line is, please make sure your local copy of ./matlab_2010b/MCRInstaller.bin is 221MB in file size to ensure a successful run of Tangent.



### 2. Modify line 59 of Dockerfile to designate parameters for the run:

_line 58:_
```
ENTRYPOINT ["bash", "-c", "./wrapper_overall.sh -m $MCRROOT -i $0 -o $1 -s $2 -d $3 -t $4 -p $5 -c $6 -a $7 -n $8 -e $9 -x ${10} -y ${11} -z ${12} -r ${13}"]
```
_line 59:_
```
CMD ["/opt/data/", "/opt/result/", "/opt/sampledata/mysif.txt", "/opt/sampledata/mydata.DOC_interval.avg_cvg.txt", "run1", "exome", "0.23", "0.01", "2", "150", "true", "true", "true", ""]
```

* Substitute /opt/sampledata/mysif.txt with /opt/<_path to your sif file_> 
* Substitute /opt/sampledata/mydata.DOC_interval.avg_cvg.txt with /opt/<_path to your data file_>
* Examples of SIF and DATA file formats are provided in ./sampledata
* If you would like to provide a reference plane, please supply the reference plane directory path to the last argument (argument 13); otherwise set argument 10 (-x for doGenRefPlane) to "true" (unless you wish to run Pseudo-Tangent).
* If you would like to run Pseudo-Tangent, use "true" for argument 12 (-z for doPseudoTangent)



### 3. Run:

```
docker build -t tangent
docker rm tangentcont
docker run --name tangentcont -t tangent
docker ps
mkdir ./tangent_output
docker cp tangentcont:/opt/result ./tangent_output
ls ./tangent_output
```
