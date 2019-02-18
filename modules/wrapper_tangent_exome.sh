#!/bin/bash -l


## Set default inputs
doTangent=true
doGermline=false
doCBS=true
SeqPlatform="exome" # snpArray
NormalCeiling=0.18 #0.0725 for SNP array
RefPlane="/opt/lib/std_ref_plane" ## currently a standard reference plane does not exist
OrigSifPath='none_given'
OrigDataPath='none_given'
MCRROOT="/opt/MATLAB/MATLAB_Compiler_Runtime/v714/"
Alpha=0.01
pwdPath='/opt/'

usage(){ 
	
	echo "usage: <command> -i <InputDir> -o <OutputDir> -t <Tag> -r <RefPlane> -w <doTangent> -g <doGermline> -p <SeqPlatform> -c <NormalCeiling> -s <OrigSifPath> -d <OrigDataPath> -a <Alpha>" 
	echo "	InputDir: Dir containing the data file <Tag>.D.txt and sif file <Tag>.sif.txt. (Required parameter.)"
	echo "	OutputDir: Output directory for results. An example could be /opt/result/${Tag}. (Required parameter.)"
	echo "	Tag: A tag to name this particular run. (Required parameter.)"
	echo "	RefPlane: A path of the reference plane directory. (Required parameter.)"
	echo "	doTangent: Do you want to run the actual Tangent step? (true/false; default true)"
	echo "	doGermline: Do you want to do germline CNVs? true will output woCNV and wCNV; false outputs woCNV only. (true/false; default false.)" 
	echo "	SeqPlatform: snpArray or exome. (default exome)"
	echo "	NormalCeiling: Recommend 0.18, 0.23, or 0.3 for exomes, and 0.0725 for snpArrays. (default 0.18)"
	echo "	OrigSifPath: Path to SIF file of a collection of normal and tumor samples. File consists of 2 columns - sample name and tumor_normal. (Optional, will default to ${InputDir}/${Tag}.sif.txt if not supplied.)"
	echo "	OrigDataPath: Path to DATA file (usually the output of DepthOfCoverage) for a collection of normal and tumor samples. (Optional, will default to ${InputDir}/${Tag}.D.txt if not supplied.)"
	echo "	Alpha: significance level parameter for CBS (default 0.01)"
	
	# bash wrapper_tangent_exome.sh \
	#     -i /opt/data/genRefPlane_test_run_2018/tangent_input/ \
	#     -o /opt/result/genRefPlane_test_run_2018/tangent_output/ \
	#     -t run2 \
	#     -w true \
	#     -p exome \
	#     -r /opt/result/genRefPlane_test_run_2018/genRefPlane_output_run2/ \
	#     -c 0.3 \
	#     -g false \
	#     -s /opt/data/genRefPlane_test_run_2018/run2.sif.txt \
	#     -d /opt/data/genRefPlane_test_run_2018/run2.DOC_interval.avg_cvg.txt

}

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    usage
    exit 1
fi

while getopts :i:o:w:t:p:r:c:g:s:d:a:z: option; do
    case "${option}" in
		i) InputDir=${OPTARG};;
		o) OutputDir=${OPTARG};;
		t) Tag=${OPTARG};;
		w) doTangent=${OPTARG};;
		p) SeqPlatform=${OPTARG};;
		r) RefPlane=${OPTARG};;
		c) NormalCeiling=${OPTARG};;
		g) doGermline=${OPTARG};;
		z) doCBS=${OPTARG};;
		s) OrigSifPath=${OPTARG};;
		d) OrigDataPath=${OPTARG};;
		a) Alpha=${OPTARG};;
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
if [ ! "$InputDir" ] || [ ! "$OutputDir" ] || [ ! "$Tag" ]; then
	echo "Key arguments (InputDir,OutputDir,Tag) not present"
	usage
	exit 1
fi

InputDir="${InputDir}/${Tag}/tangent_input_${Tag}"
OutputDir="${OutputDir}/${Tag}/tangent_output_${Tag}"
# InputDir="${InputDir}/${Tag}/tangent_input/"
# OutputDir="${OutputDir}/${Tag}/tangent_output/"
SifPath="${InputDir}/${Tag}.sif.txt"
DataPath="${InputDir}/${Tag}.D.txt"

if [[ ! -e ${OutputDir} ]]; then
    echo "OutputDir does not exist. Creating OutputDir ${OutputDir}..."
    mkdir -p ${OutputDir}
fi


if [[ ! -e ${InputDir} ]]; then
    echo "InputDir does not exist. Creating InputDir ${InputDir}..."
    mkdir -p ${InputDir}
fi

if [ "${OrigSifPath}" == "none_given" ]; then
	echo "No value was given for OrigSifPath, using default [InputDir]/[Tag].sif.txt"
	OrigSifPath=${InputDir}/${Tag}.sif.txt
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
	echo "No value was given for OrigDataPath, using default [InputDir]/[Tag].D.txt"
	OrigDataPath=${InputDir}/${Tag}.D.txt
else
	echo "Creating symlink for D file..."
	if [[ ! "${OrigDataPath:0:1}" == '/' ]]; then
		OrigDataPath=${pwdPath}/${OrigDataPath}
	fi
	echo "OrigDataPath: ${OrigDataPath}"
	echo "NewDataPath: ${DataPath}"
	ln -sf ${OrigDataPath} ${DataPath}
fi



LOG_FILE="${OutputDir}/stdout_stderr.log"
echo '' > ${LOG_FILE}
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

###### -------------------- No need to edit beyond here -------------------- ######

echo "Running Tangent and post-Tangent on ${Tag} sequenced on the ${SeqPlatform} platform:"
echo "	Output directory: ${OutputDir}"
echo "	Reference Plane: ${RefPlane}"
echo "	Input directory: ${InputDir}"
echo "	doTangent: ${doTangent}"
echo "	Normal Ceiling Threshold: ${NormalCeiling}"
echo "	doGermline: ${doGermline}"


if [[ "$SeqPlatform" == "snpArray" ]]; then
	InputFile="${OutputDir}/${Tag}.med1000.invset_medpolish.pip3avg.log_mdQUAD.no_outliers.txt"
	OrigInput="${InputDir}/${Tag}.med1000.invset_medpolish.pip3avg.log_mdQUAD.no_outliers.txt"
	SifFile="${OutputDir}/${Tag}.processing.sif.txt"
	OrigSif="${InputDir}/${Tag}.processing.sif.txt"
	wCNVFN="${OutputDir}/${Tag}.med1000.invset_medpolish.pip3avg.log_mdQUAD_posttangent_wCNV.txt"
	woCNVFN="${OutputDir}/${Tag}.med1000.invset_medpolish.pip3avg.log_mdQUAD_posttangent_woCNV.txt"
	wCNVFNnoGP="${OutputDir}/${Tag}.med1000.invset_medpolish.pip3avg.log_mdQUAD_posttangent_wCNV_noGP.txt"
	woCNVFNnoGP="${OutputDir}/${Tag}.med1000.invset_medpolish.pip3avg.log_mdQUAD_posttangent_woCNV_noGP.txt"
	wCNVFNnoGPrda="${OutputDir}/${Tag}.med1000.invset_medpolish.pip3avg.log_mdQUAD_posttangent_wCNV_noGP_hg19.rda"
	woCNVFNnoGPrda="${OutputDir}/${Tag}.med1000.invset_medpolish.pip3avg.log_mdQUAD_posttangent_woCNV_noGP_hg19.rda"

elif [[ "$SeqPlatform" == "exome" ]]; then
	InputFile="${OutputDir}/${Tag}.D.txt"
	OrigInput="${InputDir}/${Tag}.D.txt"
	SifFile="${OutputDir}/${Tag}.sif.txt"
	OrigSif=${SifPath}
	wCNVFN="${OutputDir}/${Tag}.doc_interval.posttangent_wCNV.txt"
	woCNVFN="${OutputDir}/${Tag}.doc_interval.posttangent_woCNV.txt"
	# wCNVFNnoGP="${OutputDir}/${Tag}.doc_interval.posttangent_wCNV_noGP.txt"
	# woCNVFNnoGP="${OutputDir}/${Tag}.doc_interval.posttangent_woCNV_noGP.txt"
	wCNVFNnoGPrda="${wCNVFN}"
	woCNVFNnoGPrda="${woCNVFN}"
	numCores=38


fi

###### -------------------- Step 1 -------------------- ######
if [ "$doTangent" = true ]; then
	echo "Step 1: Tangent..."

	#ln -sf ${OrigSif} ${OutputDir}/
	#ln -sf ${OrigInput} ${OutputDir}/

	ln -sf ${OrigSifPath} ${SifFile}
    ln -sf ${OrigDataPath} ${InputFile}

	echo "MATLAB env: ${MCRROOT}"

	numTumors=`awk '$2 == "Tumor"' ${OrigSifPath} | wc -l`
	#secho $numTumors
	if [[ ${numTumors} -eq 1 ]]; then
		echo "...there is only 1 tumor sample in this run. Tangent will break."
		echo "Exiting."
		exit 1
	else
		echo "...confirming there is more than 1 tumor sample in this run."
	fi

	# check refplane exists
	if [[ ! -e ${RefPlane} ]]; then
    	echo "Reference plane ${RefPlane} does not exist. Exiting ..."
    	exit 1
	fi


	bash ./run_tangent.sh $MCRROOT ${Tag} \
		${InputFile} \
		${SifFile} \
		${RefPlane} \
		${wCNVFN} \
		${woCNVFN} \
		/opt/lib/CNV.hg19.bypos.111213.txt \
		/opt/lib/genome.info.6.0_hg19.na31_minus_frequent_nan_probes_sorted.txt \
		/opt/lib/normal.blacklist.txt \
		${SeqPlatform} \
		${NormalCeiling}

	echo "...step 1 completed."

elif [ "$doTangent" = false ]; then
	echo "Step 1: Tangent. [completed]"
fi

###### --------- Step 1b: QC for length of suspect normals --------- ######
echo "Step 1: Checking the list of suspect normals..."
Rscript ./modules/check_suspect_normals_length.R \
	--args ${OutputDir}/${Tag}.early_gistic_prep_output._suspect_normals.txt \
			${OutputDir}/${Tag}.early_gistic_prep_output._disruption_scores.txt \
			${OutputDir}/${Tag}.sif.txt


###### -------------------- Step 2 (not run for exomes) -------------------- ######
echo "Step 2: Run stripLocation..."
if [[ "$SeqPlatform" == "snpArray" ]]; then

	if ! [[ -s ${woCNVFNnoGP} ]]; then
		Rscript ./modules/stripLocation.R \
			--args ${woCNVFN} ${woCNVFNnoGP}
	fi
	
	if [ "$doGermline" = true ]; then
		if ! [[ -s ${wCNVFNnoGP} ]]; then
			Rscript ./modules/stripLocation.R \
				--args ${wCNVFN} ${wCNVFNnoGP}
		fi
	fi

elif [[ "$SeqPlatform" == "exome" ]]; then
	echo "For exome analysis, we do not need to run stripLocation (since we do not need to run LiftOver.)"

fi

echo "...step 2 completed."


###### -------------------- Step 3 (not run for exomes) -------------------- ######
echo "Step 3: Run Liftover..."
if [[ "$SeqPlatform" == "snpArray" ]]; then
	Rscript ./modules/liftOver.R \
		--args ${woCNVFNnoGP} \
		${OutputDir} \
		hg18=./lib/genome.info.6.0_hg18.na30_minus_frequent_nan_probes_sorted.txt \
		hg19=./lib/genome.info.6.0_hg19.na31_minus_frequent_nan_probes_sorted.txt

	if [ "$doGermline" = true ]; then
		Rscript ./modules/liftOver.R \
			--args ${wCNVFNnoGP} \
			${OutputDir} \
			hg18=./lib/genome.info.6.0_hg18.na30_minus_frequent_nan_probes_sorted.txt \
			hg19=./lib/genome.info.6.0_hg19.na31_minus_frequent_nan_probes_sorted.txt
	fi


elif [[ "$SeqPlatform" == "exome" ]]; then
	echo "For exome analysis, we will not do liftover from hg18 to hg19. The data is already in hg19."
fi
echo "...step 3 completed."


###### -------------------- Step 4 -------------------- ######
if [ "$doCBS" = true ]; then
	echo "Step 4: Run CBS..."

	if [[ ! -e ${OutputDir}/CBS/ ]]; then
		mkdir ${OutputDir}/CBS/
	elif [[ ! -d ${OutputDir}/CBS/ ]]; then
		echo "${OutputDir}/CBS/ already exists but is not a directory" 1>&2
	fi

	if [ "$doGermline" = true ]; then
		if [ ! -e "${wCNVFNnoGPrda}" ]; then
	    	echo "${wCNVFNnoGPrda} does not exist. Ending now."
			exit 1
		fi 
	fi

	if [ ! -e "${woCNVFNnoGPrda}" ]; then
	    echo "${woCNVFNnoGPrda} does not exist. Ending now."
		exit 1
	fi 

	if [[ "$SeqPlatform" == "snpArray" ]]; then

		sed 1d ${SifFile} | while read -r array remainder;
		do
			echo ${array}
		    if [ "$doGermline" = true ]; then
				if ! [[ -s ${OutputDir}/CBS/${array}_wCNV_hg19.cbs ]]; then
					Rscript ./modules/run_cbs.R \
						--args ${wCNVFNnoGPrda} ${OutputDir}/CBS/${array}_wCNV_hg19.cbs ${array}
				fi
			fi

			
			if ! [[ -s ${OutputDir}/CBS/${array}_woCNV_hg19.cbs ]]; then
				Rscript ./modules/run_cbs.R \
					--args ${woCNVFNnoGPrda} ${OutputDir}/CBS/${array}_woCNV_hg19.cbs ${array}
			fi

		done 
	elif [[ "$SeqPlatform" == "exome" ]]; then
		echo "Running CBS in parallel..."

	    if [ "$doGermline" = true ]; then
			Rscript ./modules/wrapper_cbs_in_parallel.R \
				--args ${wCNVFNnoGPrda} ${SifFile} ${OutputDir}/CBS/ ./modules/run_cbs.R wCNV ${numCores} ${Alpha}
		fi
			
		Rscript ./modules/wrapper_cbs_in_parallel.R \
			--args ${woCNVFNnoGPrda} ${SifFile} ${OutputDir}/CBS/ ./modules/run_cbs.R woCNV ${numCores} ${Alpha}

	fi	
	echo "...step 4 completed."
else
	echo "Step 4: Skip running CBS. [completed]"
fi


###### -------------------- Step 5 -------------------- ######
echo "Step 5: Run tblcat to generate.seg ..."


if [[ -e ${OutputDir}/CBS ]]; then
    echo "OutputDir for CBS files: ${OutputDir}/CBS"
else
	echo "Cannot find OutputDir for CBS: ${OutputDir}/CBS . Exiting ..."
	exit 1
fi


if [ "$doGermline" = true ]; then
	./modules/tblcat ${OutputDir}/CBS/*_wCNV_hg19.cbs > ${OutputDir}/${Tag}_wCNV_hg19.catted.seg.txt
fi


./modules/tblcat ${OutputDir}/CBS/*_woCNV_hg19.cbs > ${OutputDir}/${Tag}_woCNV_hg19.catted.seg.txt

echo "...step 5 completed."

