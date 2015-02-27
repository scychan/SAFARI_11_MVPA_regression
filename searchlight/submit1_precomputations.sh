#!/bin/bash

searchlight_radius=$1
penalty=$2

# main options
subjnums="109 110 112 `seq 116 129`"
if ismachine rondo; then
    ngroups_max=5000
elif ismachine della; then
    ngroups_max=250
fi
    

# submit precomputations
for subjnum in $subjnums; do
    submit precomputations.m $subjnum $ngroups_max searchlight_radius $searchlight_radius penalty $penalty
    sleep 1
done
