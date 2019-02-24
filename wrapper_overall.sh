#!/bin/bash -l

## Set default parameters

# OrigSifPath=/opt/data/genRefPlane_test_run_2018/run2.sif.txt
# OrigDataPath=/opt/data/genRefPlane_test_run_2018/run2.DOC_interval.avg_cvg.txt
# Tag=run_default
# InputDir=/opt/data/${Tag}/
# OutputDir=/opt/result/${Tag}/
# RefPlanePath='none'
SeqPlatform=exome
NormalCeiling=0.18
Alpha=0.01
Nsplit=3
Evects=150
doGenRefPlane=false
doTangentSteps=false
doPseudoTangent=false
MCRROOT=/opt/MATLAB/MATLAB_Compiler_Runtime/v714/

usage(){ 
	echo "usage: wrapper_overall.sh -i <InputDir> -o <OutputDir> -s <OrigSifPath> -d <OrigDataPath> -r <RefPlanePath> -t <Tag> -p <SeqPlatform> -c <NormalCeiling> -a <Alpha> -n <Nsplit> -e <Evects> -x <doGenRefPlane> -y <doTangentSteps> -z <doPseudoTangent> -m <MCRROOT>" 
	
	echo "	InputDir: Input directory where symlinks to OrigSifPath and OrigDataPath will be created. An example could be /opt/data/${Tag}. (Required parameter.)"
	echo "	OutputDir: Output directory for results. An example could be /opt/result/${Tag}. (Required parameter.)"
	echo "	OrigSifPath: Path to SIF file of a collection of normal and tumor samples. File consists of 2 columns - sample name and tumor_normal. (Required parameter.)"
	echo "	OrigDataPath: Path to DATA file (usually the output of DepthOfCoverage) for a collection of normal and tumor samples. (Required parameter.)"
	echo "	RefPlanePath: Path to reference plane for Tangent steps run. (Optional but is required if doTangentSteps is true and doGenRefPlane is false.)"
	echo "	Tag: A tag to name this particular run. (Required parameter.)"
	echo "	NormalCeiling: Recommend 0.18, 0.23, or 0.3 for exomes, and 0.0725 for snpArrays. (default 0.18)"
	echo "	Alpha: significance level parameter for CBS. (default 0.01)"
	echo "	Nsplit: Splits tumors into n sets for pseudonormalization. (default 3)"
	echo "	Evects: Number of eigenvectors to retain in reference plane. (default 150)"
	echo "	MCRROOT: path to MCR directory for MATLAB2010b environment. (default /opt/MATLAB/MATLAB_Compiler_Runtime/v714/)"
	echo "	doGenRefPlane: Generates reference plane. (default true)"
	echo "	doTangentSteps: Runs Tangent steps. (default true)"
	echo "	doPseudoTangent: Runs PseudoTangent. (default true)"
}

## Check Arguments ##
if [ $# -eq 0 ]; then
    echo "No arguments were provided."
    usage
    exit 1
fi

while getopts :i:o:s:d:r:t:p:c:a:n:e:x:y:z:m: option; do
    case "${option}" in
		i) InputDir=${OPTARG};;
		o) OutputDir=${OPTARG};;
		s) OrigSifPath=${OPTARG};;
		d) OrigDataPath=${OPTARG};;
		r) 
			RefPlanePath=${OPTARG}
			[ -z "${RefPlanePath}" ] && {
				echo "Note: RefPlanePath is an empty string. Will remove RefPlanePath variable."
				unset RefPlanePath
			}
			[ "${RefPlanePath}" = "None" ] || [ "${RefPlanePath}" = "none" ] && {
				echo "Note: There is no RefPlanePath. Will remove RefPlanePath variable."
				unset RefPlanePath
			}
			;;

		t) Tag=${OPTARG};;
		p) SeqPlatform=${OPTARG};;
		c) NormalCeiling=${OPTARG};;
		a) Alpha=${OPTARG};;
		n) Nsplit=${OPTARG};;
		e) Evects=${OPTARG};;
		x) doGenRefPlane=${OPTARG};;
		y) doTangentSteps=${OPTARG};;
		z) doPseudoTangent=${OPTARG};;
		m) MCRROOT=${OPTARG};;

		\?)
			echo "InputDir=${InputDir}"
			echo "OutputDir=${OutputDir}"
			echo "OrigSifPath=${OrigSifPath}"
			echo "OrigDataPath=${OrigDataPath}"
			echo "RefPlanePath=${RefPlanePath}"
			echo "Tag=${Tag}"
			echo "SeqPlatform=${SeqPlatform}"
			echo "NormalCeiling=${NormalCeiling}"
			echo "Alpha=${Alpha}"
			echo "Nsplit=${Nsplit}"
			echo "Evects=${Evects}"
			echo "doGenRefPlane=${doGenRefPlane}"
			echo "doTangentSteps=${doTangentSteps}"
			echo "doPseudoTangent=${doPseudoTangent}"
			echo "MCRROOT=${MCRROOT}"
			echo "Missing required options:"
			echo "Unknown options:"
			usage
			exit;;
		:) 
			
			echo "InputDir=${InputDir}"
			echo "OutputDir=${OutputDir}"
			echo "OrigSifPath=${OrigSifPath}"
			echo "OrigDataPath=${OrigDataPath}"
			echo "RefPlanePath=${RefPlanePath}"
			echo "Tag=${Tag}"
			echo "SeqPlatform=${SeqPlatform}"
			echo "NormalCeiling=${NormalCeiling}"
			echo "Alpha=${Alpha}"
			echo "Nsplit=${Nsplit}"
			echo "Evects=${Evects}"
			echo "doGenRefPlane=${doGenRefPlane}"
			echo "doTangentSteps=${doTangentSteps}"
			echo "doPseudoTangent=${doPseudoTangent}"
			echo "MCRROOT=${MCRROOT}"
			echo "Missing required options:"
			usage; 
			exit;;
		h|*)
			usage; 
			exit;;
	esac
done

echo "InputDir=${InputDir}"
echo "OutputDir=${OutputDir}"
echo "OrigSifPath=${OrigSifPath}"
echo "OrigDataPath=${OrigDataPath}"
echo "RefPlanePath=${RefPlanePath}"
echo "Tag=${Tag}"
echo "SeqPlatform=${SeqPlatform}"
echo "NormalCeiling=${NormalCeiling}"
echo "Alpha=${Alpha}"
echo "Nsplit=${Nsplit}"
echo "Evects=${Evects}"
echo "doGenRefPlane=${doGenRefPlane}"
echo "doTangentSteps=${doTangentSteps}"
echo "doPseudoTangent=${doPseudoTangent}"
echo "MCRROOT=${MCRROOT}"


# check for required arguments
if [ ! "${InputDir}" ] || [ ! "${OutputDir}" ] || [ ! "${OrigSifPath}" ] || [ ! "${OrigDataPath}" ] || [ ! "${Tag}" ] ; then
	echo "Key arguments (InputDir, OutputDir, OrigSifPath, OrigDataPath, Tag) not present. Exiting..."
	usage
	exit 1
fi

if [[ "${doGenRefPlane}" = false && "${doTangentSteps}" = true ]]; then
	if [ ! "${RefPlanePath}" ] ; then
		echo "RefPlanePath is required if doGenRefPlane is false and doTangentSteps is true."
		usage
		exit 1
	fi
elif [[ "${doGenRefPlane}" = true  && "${doTangentSteps}" = true ]]; then
	if [ ! "${RefPlanePath}" ] ; then
		echo "RefPlanePath was not provided. We will assign the RefPlanePath as output reference plane from Step 1 (GenRefPlane):"
		RefPlanePath=${OutputDir}/${Tag}/genRefPlane_output_${Tag}/
		echo "${RefPlanePath}"
	fi
fi

echo " "
echo "====================================================="
## Step 1: Generate Reference Plane ##
if [ "${doGenRefPlane}" = true ]; then
	echo "Step 1: Generating reference plane..."
	bash ./modules/wrapper_genRefPlane.sh \
	    -m ${MCRROOT} \
	    -i ${InputDir} \
	    -o ${OutputDir} \
	    -s ${OrigSifPath} \
	    -d ${OrigDataPath} \
	    -t ${Tag} \
	    -p ${SeqPlatform} \
	    -c ${NormalCeiling}
	echo "...Step 1 completed."
else
	echo "Skipping Step 1: Will not generate reference plane."
fi
wait

echo " "
echo "====================================================="
## Step 2: Tangent ##
if [ "${doTangentSteps}" = true ]; then
	echo "Step 2: Running Tangent steps..."
	echo "RefPlanePath=${RefPlanePath}"
	bash ./modules/wrapper_tangent_exome.sh \
	    -i ${InputDir} \
	    -o ${OutputDir} \
	    -t ${Tag} \
	    -w true \
	    -z true \
	    -p ${SeqPlatform} \
	    -r ${RefPlanePath} \
	    -c ${NormalCeiling} \
	    -g false \
	    -s ${OrigSifPath} \
    	-d ${OrigDataPath}
    echo "...Step 2 completed."
else
	echo "Skipping Step 2: Will not run Tangent steps."
fi
wait

echo " "
echo "====================================================="
## Step 3: PseudoTangent ##
if [ "${doPseudoTangent}" = true ]; then
	echo "Step 3: Running PseudoTangent..."
	bash ./modules/wrapper_PseudoTangent.sh \
	    -n ${Nsplit} \
	    -a ${Alpha} \
	    -e ${Evects} \
	    -s ${OrigSifPath} \
	    -d ${OrigDataPath} \
	    -t ${Tag} \
	    -o ${OutputDir} \
	    -c ${NormalCeiling} \
	    -m ${MCRROOT}
	echo "...Step 3 completed."
else
	echo "Skipping Step 3: Will not run PseudoTangent."
fi
wait

echo "====================================================="

