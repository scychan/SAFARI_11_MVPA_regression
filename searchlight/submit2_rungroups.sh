#!/bin/bash

# main options
subjnums=$1
analysis=$2
searchlight_radius=$3
penalty=$4
zscore=$5
mask=$6
niters=$7

# run_mvpa for all the voxels (array job)
for subjnum in $subjnums; do
    echo "subjnum = $subjnum"
    . ../../results/searchlights/$analysis/radius$searchlight_radius/penalty$penalty/zscore$zscore/mask$mask/SFR$subjnum/precomputations/groupstats.sh
    echo "ngroups = $ngroups"
    if [ $niters = 0 ]; then
	submit $ngroups set_params_and_run_mvpa.m $subjnum $analysis searchlight_radius $searchlight_radius penalty $penalty dozscore $zscore mask $mask # array job
    else
	for iteration in `seq 1 $niters`; do
	    submit_short $ngroups set_params_and_run_mvpa.m $subjnum $analysis searchlight_radius $searchlight_radius penalty $penalty dozscore $zscore mask $mask iteration $iteration # array job
	done
    fi
done