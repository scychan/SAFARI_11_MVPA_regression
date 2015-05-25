#!/bin/bash
# submit the voxels that didn't complete. 
# list of voxels in check_results.txt 
# (generated by check_searchlight_results.sh + split manually into rows using Emacs macros)

# main options
subjnum=$1
radius=$2
penalty=$3

# file to read from
voxlisting=../../results/searchlights/radius$radius/penalty$penalty/SFR$subjnum/check_results.txt
 
# run_mvpa for all the voxels
cat $voxlisting | while read line; do
    submit_short set_params_and_run_mvpa.m $subjnum searchlight_radius $radius penalty $penalty voxels_to_run "'$line'"
done