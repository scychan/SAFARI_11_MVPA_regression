#!/bin/bash

searchlight_radius=$1
penalty=$2

# main options
subjnums="101" # 102 103 104 105 106 107 108 109 110 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 129 130 131 132 133 134"
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
