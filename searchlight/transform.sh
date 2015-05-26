#!/bin/bash
# Transform 'compiled' from subject space to standard space

subj=$1
analysis=$2
radius=$3
penalty=$4
zscore=$5
mask=$6

# basics
datadir=../../data/SFR$subj
resultsdir=../../results/searchlights/$analysis/radius$radius/penalty$penalty/zscore$zscore/mask$mask/SFR$subj
standard=$FSLDIR/data/standard/MNI152_T1_2mm_brain

# transform 'compiled' to standard space
echo 'Transforming to standard space...'
transform=$datadir/transforms/run1/example_func2standard.mat
orig=$resultsdir/compiled
outfile=$resultsdir/transformed
flirt -in $orig -ref $standard -applyxfm -init $transform -out $outfile.nii.gz