#!/bin/bash

###############################
### Set Up Parameter Values ###
###############################

# set some default parameters
Nsplit=3   # partitions to split tumors into for complementary PN refplanes
Alpha=0.01  # significance parameter for CBS in accepting change-points
Evects=150    # Number of SVD components to decompose PN reference plane into
Tag=SampleSet
OutputDir=./
NormalCeiling=0.18
MCRROOT="/opt/MATLAB/MATLAB_Compiler_Runtime/v714/"
pwdPath="/opt/"
scriptDir="./modules/"

usage(){
	echo "usage: wrapper_PseudoTangent.sh -n <Nsplit> -a <Alpha> -e <Evects> -s <OrigSifPath> -d <OrigDataPath> -t <Tag> -o <OutputDir> -c <NormalCeiling> -m <MCRROOT>"
  echo "  Nsplit: Splits tumors into n sets for pseudonormalization. (default 3)"
  echo "  Alpha: significance level parameter for CBS. (default 0.01)"
  echo "  Evects: Number of eigenvectors to retain in reference plane. (default 150)"
  echo "  OrigSifPath: Path to SIF file of a collection of normal and tumor samples. File consists of 2 columns - sample name and tumor_normal. (Required parameter.)"
  echo "  OrigDataPath: Path to DATA file (usually the output of DepthOfCoverage) for a collection of normal and tumor samples. (Required parameter.)"
  echo "  Tag: A Tag to name this particular run. (Required parameter.)"
  echo "  OutputDir: Output directory for results. An example could be /opt/result/${Tag}. (Required parameter.)"
  echo "  NormalCeiling: Recommend 0.18, 0.23, or 0.3 for exomes, and 0.0725 for snpArrays. (default 0.18)"
  echo "  MCRROOT: path to MCR directory for MATLAB2010b environment. (default /opt/MATLAB/MATLAB_Compiler_Runtime/v714/)"

  # bash wrapper_PseudoTangent.sh \
  #     -n 3 \
  #     -a 0.01 \
  #     -e 150 \
  #     -s /opt/data/genRefPlane_test_run_2018/run2.sif.txt \
  #     -d /opt/data/genRefPlane_test_run_2018/run2.DOC_interval.avg_cvg.txt \
  #     -t run2 \
  #     -w ./result/ \
  #     -c 0.3 \
  #     -m /opt/MATLAB/MATLAB_Compiler_Runtime/v714/

}
while getopts :n:a:e:s:d:t:o:c:m: option; do
  case "${option}" in
		n) Nsplit=${OPTARG};;
		a) Alpha=${OPTARG};;
		e) Evects=${OPTARG};;
		s) OrigSifPath=${OPTARG};;
		d) OrigDataPath=${OPTARG};;
		t) Tag=${OPTARG};;
		o) OutputDir=${OPTARG};;
    c) NormalCeiling=${OPTARG};;
    m) MCRROOT=${OPTARG};;
		\?)
			echo "Unknown options:"
			usage
			exit;;
	esac
done

if [ ! "$OrigSifPath" ] || [ ! "$OrigDataPath" ] ; then
  echo "Key arguments (OrigSifPath, OrigDataPath) not present. Cannot proceed."
  usage
  exit 1
fi

# echo "Nsplit: ${Nsplit}"
# echo "Alpha: ${Alpha}"
# echo "Evects: ${Evects}"
# echo "OrigSifPath: ${OrigSifPath}"
# echo "OrigDataPath: ${OrigDataPath}"
# echo "Tag: ${Tag}"
# echo "OutputDir: ${OutputDir}"
# echo "NormalCeiling: ${NormalCeiling}"


## Tangent cannot run on a single tumor sample. There must be at least 2 tumor samples in one run due to MATLAB dimensions issues. Nsplit is important in that if it divides the total number of samples such that one of the groups only contains one sample, Tangent will break.
# - Read number of samples available
# - tailor nsplit with total_n%Nsplit --> Nsplit = Nsplit - 1
if [[ ! -e ${OutputDir}/${Tag} ]]; then
  echo "OutputDir does not exist. Creating directory ${OutputDir}/${Tag}..."
  mkdir -p ${OutputDir}/${Tag}
fi

Rscript ${scriptDir}/checkNSplit.R --args ${OrigSifPath} ${Nsplit} ${OutputDir}/${Tag}/pseudoTangent_newNsplit.txt
Nsplit=`cat ${OutputDir}/${Tag}/pseudoTangent_newNsplit.txt`
#echo ${Nsplit}

PseudoTangentTag=${Tag}_n${Nsplit}a${Alpha}e${Evects}
OutputDir=${OutputDir}/${Tag}/pseudoTangent_${PseudoTangentTag}

############################
### Begin Running Script ###
############################

### set up working directory
mkdir -p ${OutputDir}
echo "OutputDir: ${OutputDir}"
printf "Nsplit = "${Nsplit}"\nAlpha = "${Alpha}"\nEvects = "${Evects} > ${OutputDir}/run_parameters.txt
echo "Normal Ceiling: ${NormalCeiling}"

### define helper function
full_tangent () {
  # Generate reference plane & run tangent using this refplane. $1=OutputDir
  # $2=ref_PseudoTangentTag $3=tan_PseudoTangentTag $4=ref_sif $5=ref_data $6=tan_sif $7=tan_data $8=Alpha 
  echo " ||| Generating reference plane ||| "
  bash wrapper_genRefPlane.sh -i $1 -o $1 -s $4 -d $5 -t $2 -p exome -c ${NormalCeiling} -m ${MCRROOT}
  echo " |||---------------------------------------||| "

  echo " ||| Running Tangent using reference plane ||| "
  bash wrapper_tangent_exome.sh -i $1 -o $1 -t $3 -r $1/$2/genRefPlane_output_$2/ -s $6 -d $7 -w true -p exome -c ${NormalCeiling} -g false -a $8 -z true
}

### perform initial run of tangent using normals in refplane
echo "--> Executing Initial Pass of Tangent Using Normal RefPlane <--"
full_tangent ${OutputDir} ${PseudoTangentTag}_InitialRefPlane ${PseudoTangentTag}_InitialTangent ${OrigSifPath} ${OrigDataPath} ${OrigSifPath} ${OrigDataPath} ${Alpha}

if [[ ! -e ${OutputDir}/${PseudoTangentTag}_InitialTangent/tangent_output_${PseudoTangentTag}_InitialTangent/${PseudoTangentTag}_InitialTangent_woCNV_hg19.catted.seg.txt ]]; then
  echo "Prior Tangent step failed to generate .seg output. Please debug and rerun. Exiting..."
  exit 1
fi

### perform pseudonormalization and then partition sif and doc files into sets
echo "--> Performing pseudonormalization <--"
mkdir -p ${OutputDir}/sif_files/ ${OutputDir}/doc_files/
python3 ${scriptDir}/generatePseudonormals.py ${OrigDataPath} \
  ${OutputDir}/${PseudoTangentTag}_InitialTangent/tangent_output_${PseudoTangentTag}_InitialTangent/${PseudoTangentTag}_InitialTangent_woCNV_hg19.catted.seg.txt \
  ${OutputDir}/${PseudoTangentTag}_InitialTangent/tangent_output_${PseudoTangentTag}_InitialTangent/${PseudoTangentTag}_InitialTangent.doc_interval.posttangent_woCNV.txt \
  ${OrigSifPath} ${OutputDir} ${Nsplit} ${Evects}

### generate pseudonormals reference planes and run tangent
echo "--> Analyzing Tumor Partitions with Pseudonormals <--"
i=1
while IFS=$'\t' read -r -a pArray
do
  echo "--> Generating PN RefPlane "${i}" of "${Nsplit}" and Running Tangent <--"
  full_tangent ${OutputDir} ${PseudoTangentTag}_pnRefPlane_${i} ${PseudoTangentTag}_pnTangent_${i} \
     ${pArray[0]} ${pArray[1]} ${pArray[2]} ${pArray[3]} ${Alpha}
  let i=i+1
done < ${OutputDir}/pseudonormal_runs_parameters.txt
wait

### cat results together
echo "--> Catting Together PseudoTangent Outputs <--"
${scriptDir}/cat_tangent_outputs.sh ${OutputDir} ${PseudoTangentTag}

### clean up working directory
echo "--> Cleaning Out Dir: Removing PN Ref Planes & All Input Dirs <--"
rm -rf ${OutputDir}/*RefPlane*/ ${OutputDir}/genRefPlane_input_*/ \
  ${OutputDir}/runTangent_input_*/ ${OutputDir}/doc_files/ ${OutputDir}/sif_files/ ${OutputDir}/*pnTangent_*
