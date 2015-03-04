#!/bin/bash
# Transform 'interpolated' from subject space to standard space

subj=$1
radius=$2
penalty=$3

# basics
datadir=../../data/SFR$subj
resultsdir=../../results/searchlights/radius$radius/penalty$penalty/SFR$subj
standard=$FSLDIR/data/standard/MNI152_T1_2mm_brain

# transform 'interpolated' to standard space
echo 'Transforming to standard space...'
transform=$datadir/transforms/run1/example_func2standard.mat
orig=$resultsdir/interpolated
outfile=$resultsdir/transformed
flirt -in $orig -ref $standard -applyxfm -init $transform -out $outfile.nii.gz