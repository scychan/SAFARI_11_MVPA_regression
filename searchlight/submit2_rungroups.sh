#!/bin/bash

# main options
subjnums=$1
analysis=$2
searchlight_radius=$3
penalty=$4
zscore=$5

# run_mvpa for all the voxels (array job)
for subjnum in $subjnums; do
    echo "subjnum = $subjnum"
    . ../../results/searchlights/$analysis/radius$searchlight_radius/penalty$penalty/zscore$zscore/SFR$subjnum/precomputations/groupstats.sh
    echo "ngroups = $ngroups"
    if ismachine rondo; then
	submit $ngroups set_params_and_run_mvpa.m $subjnum $analysis searchlight_radius $searchlight_radius penalty $penalty dozscore $zscore # array job
    elif ismachine della; then
	for igroup in `seq 1 $ngroups`; do
	    echo $igroup
	    submit_short set_params_and_run_mvpa.m $subjnum $analysis searchlight_radius $searchlight_radius penalty $penalty dozscore $zscore groupnum $igroup
	done
    fi
done