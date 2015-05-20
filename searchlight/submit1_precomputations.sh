#!/bin/bash

subjnums=$1
analysis=$2
searchlight_radius=$3
penalty=$4
dozscore=$5
smoothedEPIs=$6

# main options
if ismachine rondo; then
    ngroups_max=5000
elif ismachine della; then
    ngroups_max=250
fi

# submit precomputations
for subjnum in $subjnums; do
    submit_short precomputations.m $subjnum $analysis $ngroups_max searchlight_radius $searchlight_radius penalty $penalty dozscore $dozscore smoothedEPIs $smoothedEPIs
    sleep 1
done
