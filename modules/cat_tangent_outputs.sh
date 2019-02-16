# This script cats tangent output from each pseudonormal run together
workDir=$1
tag=$2

row_cat () {
  head -1 $1
  for f in ${@}; do tail -n +2 $f; done
}
col_cat () {
  cut -f1-3 $2 > $1
  for f in ${@:1}
  do
    ( join -t $'\t' $1 <(cut -f1-1,4- $f) ) > temp.txt
    cat temp.txt > $1
  done; rm temp.txt
}

mkdir -p ${workDir}/${tag}_catOut/

# Cat seg files together
row_cat ${workDir}/${tag}_pnTangent_*/tangent_output_${tag}_pnTangent_*/*_woCNV_hg19.catted.seg.txt > \
  ${workDir}/${tag}_catOut/${tag}_woCNV_hg19.catted.seg.txt
#row_cat ${workDir}/${tag}_pnTangent_*/*_wCNV_hg19.catted.seg.txt > \
#  ${workDir}/${tag}_catOut/${tag}_wCNV_hg19.catted.seg.txt

# Cat Post-Tangent DOC (coverage) files together
col_cat ${workDir}/${tag}_catOut/${tag}.doc_interval.posttangent_woCNV.txt \
  ${workDir}/${tag}_pnTangent_*/tangent_output_${tag}_pnTangent_*/*.doc_interval.posttangent_woCNV.txt
#col_cat ${workDir}/${tag}_catOut/${tag}.doc_interval.posttangent_wCNV.txt \
 # ${workDir}/${tag}_pnTangent_*/*.doc_interval.posttangent_wCNV.txt
