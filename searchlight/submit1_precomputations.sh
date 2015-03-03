#!/bin/bash

subjnums=$1
searchlight_radius=$2
penalty=$3

# main options
if ismachine rondo; then
    ngroups_max=5000
elif ismachine della; then
    ngroups_max=250
fi
    

# submit precomputations
for subjnum in $subjnums; do
    submit_short precomputations.m $subjnum $ngroups_max searchlight_radius $searchlight_radius penalty $penalty
    sleep 1
done
