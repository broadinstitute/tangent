# Tangent

This repository contains the code for running the Tangent copy number inference pipeline. (manuscript in submission) 
We also provide the option of Pseudo-Tangent, a modification of the Tangent pipeline that enables denoising through comparisons between tumor profiles when only a few normal samples are available.

## To run:
**1. Modify line 59 of Dockerfile to designate parameters for the run:**

_line 58:_
```
ENTRYPOINT ["bash", "-c", "./wrapper_overall.sh -m $MCRROOT -i $0 -o $1 -s $2 -d $3 -t $4 -p $5 -c $6 -a $7 -n $8 -e $9 -x ${10} -y ${11} -z ${12} -r ${13}"]
```
_line 59:_
```
CMD ["/opt/data/", "/opt/result/", "**/opt/sampledata/mysif.txt**", "**/opt/sampledata/mydata.DOC_interval.avg_cvg.txt**", "run1", "exome", "0.23", "0.01", "2", "150", "**true**", "**true**", "**true**", ""]
```

* Substitute /opt/sampledata/mysif.txt with /opt/_<where your sif file sits>_ 
* Substitute /opt/sampledata/mydata.DOC_interval.avg_cvg.txt with /opt/_<where your data file sits>_
* If you would like to provide a reference plane, please supply the reference plane directory path to the last argument (argument 13); Otherwise please make sure argument 10 (-x for doGenRefPlane) is "true".
* If you would like to run PseudoTangent, use "true" for argument 12 (-z for doPseudoTangent)


**2. Run:**

```
docker build -t tangent
docker rm tangentcont
docker run --name tangentcont -t tangent
docker ps
mkdir ./tangent_output
docker cp tangentcont:/opt/result ./tangent_output
ls ./tangent_output
```
