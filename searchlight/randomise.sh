#!/bin/bash

subjnums=$1 
radius=$2
penalty=$3
prefix=$4 # prefix for randomise results

# params for randomise
C='2.5' # cluster-forming threshold
nperm=10000

# paths
resultsdir=../../results/searchlights/radius$radius/penalty$penalty
tempdata=../../tempdata
mkdir_ifnotexist $tempdata
randomisedir=$resultsdir/randomise
mkdir_ifnotexist $randomisedir

nsubj=$(( ${#subjnums[@]} - 1 ))
	    
# concatenate all subjects
merged=$tempdata/merged
fslmerge_str="fslmerge -t $merged"
for subj in $subjnums; do
    fslmerge_str="$fslmerge_str $resultsdir/SFR$subj/transformed"
done
echo "merging..."
`$fslmerge_str`

# randomise_parallel
echo "running randomise..."
output_file=$randomisedir/$prefix
randomise_parallel -i $merged -o $output_file -1 -T -x -n $nperm -C $C
