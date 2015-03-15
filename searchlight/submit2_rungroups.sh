#!/bin/bash

# main options
subjnums=$1
searchlight_radius=$2
penalty=$3
zscore=$4

# run_mvpa for all the voxels (array job)
for subjnum in $subjnums; do
    echo "subjnum = $subjnum"
    . ../../results/searchlights/radius$searchlight_radius/penalty$penalty/SFR$subjnum/precomputations/groupstats.sh
    echo "ngroups = $ngroups"
    if ismachine rondo; then
	submit $ngroups set_params_and_run_mvpa.m $subjnum searchlight_radius $searchlight_radius penalty $penalty zscore $zscore # array job
    elif ismachine della; then
	for igroup in `seq 1 $ngroups`; do
	    echo $igroup
	    submit_short set_params_and_run_mvpa.m $subjnum searchlight_radius $searchlight_radius penalty $penalty zscore $zscore groupnum $igroup
	done
    fi
done