#!/bin/bash

# main options
subjnums=$1 # "109 110 112 `seq 116 129`"
searchlight_radius=$2
penalty=$3
 
# run_mvpa for all the voxels (array job)
for subjnum in $subjnums; do
    echo "subjnum = $subjnum"
    . ../results/radius$searchlight_radius/penalty$penalty/CLO$subjnum/precomputations/groupstats.sh
    echo "ngroups = $ngroups"
    for analysis in CLO_current_category CLO_preceding_category; do
 	echo $analysis
	if ismachine rondo; then
	    submit $ngroups set_params_and_run_mvpa.m $subjnum $analysis searchlight_radius $searchlight_radius # array job
	elif ismachine della; then
	    for igroup in `seq 1 $ngroups`; do
		echo $igroup
		submit_short set_params_and_run_mvpa.m $subjnum $analysis searchlight_radius $searchlight_radius groupnum $igroup
	    done
	fi
    done
done