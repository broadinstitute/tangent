#!/bin/bash -l

## Set default parameters
SeqPlatform="exome" # snpArray
NormalCeiling=0.18 #0.0725 for SNP array
OrigSifPath='none_given'
OrigDataPath='none_given'
Tag='run1'
MCRROOT="/opt/MATLAB/MATLAB_Compiler_Runtime/v714/"
pwdPath='/opt/'

usage(){ 
	echo "usage: <command> -i <InputDir> -o <OutputDir> -s <OrigSifPath> -d <OrigDataPath> -t <Tag> -p <SeqPlatform> -c <NormalCeiling> -m <MCRROOT>" 
	echo "	InputDir: Input directory where symlinks to OrigSifPath and OrigDataPath will be created. An example could be /opt/data/${Tag}. (Required parameter.)"
	echo "	OutputDir: Output directory for results. An example could be /opt/result/${Tag}. (Required parameter.)"
	echo "	OrigSifPath: Path to SIF file of a collection of normal and tumor samples. File consists of 2 columns - sample name and tumor_normal. (Optional, will default to ${InputDir}/sif.txt if not supplied.)"
	echo "	OrigDataPath: Path to DATA file (usually the output of DepthOfCoverage) for a collection of normal and tumor samples. (Optional, will default to ${InputDir}/D.txt if not supplied.)"
	echo "	Tag: A tag to name this particular run. (Required parameter.)"
	echo "	SeqPlatform: snpArray or exome. (default exome)"
	echo "	NormalCeiling: Recommend 0.18, 0.23, or 0.3 for exomes, and 0.0725 for snpArrays. (default 0.18)"
	echo "	MCRROOT: path to MCR directory for MATLAB2010b environment. (default /opt/MATLAB/MATLAB_Compiler_Runtime/v714/)"

	# bash wrapper_genRefPlane.sh \
	#     -m /opt/MATLAB/MATLAB_Compiler_Runtime/v714/ \
	#     -i /opt/data/genRefPlane_test_run_2018/refPlanes/ \
	#     -o /opt/result/genRefPlane_test_run_2018/ \
	#     -s /opt/data/genRefPlane_test_run_2018/run2.sif.txt \
	#     -d /opt/data/genRefPlane_test_run_2018/run2.DOC_interval.avg_cvg.txt \
	#     -t run2 \
	#     -p exome \
	#     -c 0.3

}

###### -------------------- Inputs -------------------- ######
if [ $# -eq 0 ]; then
    echo "No arguments provided"
    usage
    exit 1
fi

while getopts :i:o:s:d:t:p:c:m: option; do
    case "${option}" in
		i) InputDir=${OPTARG};;
		o) OutputDir=${OPTARG};;
		s) OrigSifPath=${OPTARG};;
		d) OrigDataPath=${OPTARG};;
		t) Tag=${OPTARG};;
		p) SeqPlatform=${OPTARG};;
		c) NormalCeiling=${OPTARG};;
		m) MCRROOT=${OPTARG};;
		\?)
			echo "Unknown options:"
			usage
			exit;;
		:) 
			echo "Missing required options:"
			usage; 
			exit;;
		h|*)
			usage; 
			exit;;
	esac
done

#i, o, n are required arguments
if [ ! "$InputDir" ] || [ ! "$OutputDir" ] ; then
	echo "Key arguments (InputDir, OutputDir) not present"
	usage
	exit 1
fi

InputDir="${InputDir}/${Tag}/genRefPlane_input_${Tag}/"
OutputDir="${OutputDir}/${Tag}/genRefPlane_output_${Tag}/"

if [[ ! -e ${OutputDir} ]]; then
	echo "OutputDir does not exist. Creating OutputDir  ${OutputDir}..."
	mkdir -p ${OutputDir}
fi

LOG_FILE="${OutputDir}/stdout_stderr.log"
echo '' > ${LOG_FILE}
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

###### -------------------- Main content below -------------------- ######

echo "Running generate_reference_plane on ${Tag} sequenced on the ${SeqPlatform} platform:"
echo "	  Input directory: ${InputDir}"
echo "	  Output directory: ${OutputDir}"
echo "	  Normal Ceiling Threshold: ${NormalCeiling}"

if [[ ! -e ${InputDir} ]]; then
	echo "InputDir does not exist. Creating InputDir  ${InputDir}..."
	mkdir -p ${InputDir}
fi

SifPath="${InputDir}/sif.txt"
DataPath="${InputDir}/D.txt"

if [ "${OrigSifPath}" == "none_given" ]; then
	echo "No value was given for OrigSifPath, using default [InputDir]/sif.txt"
	OrigSifPath=${InputDir}/sif.txt
else
	echo "Creating symlink for sif file..."
	if [[ ! "${OrigSifPath:0:1}" == '/' ]]; then
		OrigSifPath=${pwdPath}/${OrigSifPath}
	fi
	echo "OrigSifPath: ${OrigSifPath}"
	echo "NewSifPath: ${SifPath}"
	ln -sf ${OrigSifPath} ${SifPath}
fi

if [ "${OrigDataPath}" == "none_given" ]; then
	echo "No value was given for OrigDataPath, using default [InputDir]/D.txt"
	OrigDataPath=${InputDir}/D.txt
else
	echo "Creating symlink for D file..."
	if [[ ! "${OrigDataPath:0:1}" == '/' ]]; then
		OrigDataPath=${pwdPath}/${OrigDataPath}
	fi
	echo "OrigDataPath: ${OrigDataPath}"
	echo "NewDataPath: ${DataPath}"
	ln -sf ${OrigDataPath} ${DataPath}
fi

if [ ! -e "${SifPath}" ]; then
    echo "Sif file does not exist. Please supply an original sif path."
    usage
	exit 1
fi 

if [ ! -e "${DataPath}" ]; then
    echo "Data file does not exist. Please supply an original data path."
    usage
	exit 1
fi 


###### -------------------- Finally, REAL CODE -------------------- ######
# ./modules/generate_reference_plane \
# 	${InputDir} \
# 	${OutputDir} \
# 	${SeqPlatform} \
# 	${NormalCeiling}

echo "MATLAB env: ${MCRROOT}"
bash ./modules/run_generate_reference_plane.sh $MCRROOT ${InputDir} ${OutputDir} ${SeqPlatform} ${NormalCeiling}

echo "...reference plane generated."

