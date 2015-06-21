#!/bin/bash
# Take average across subjects (of 'transformed')

subjnums=$1
analysis=$2
radius=$3
penalty=$4
zscore=$5
mask=$6

# basics
resultsdir=../../results/searchlights/$analysis/radius$radius/penalty$penalty/zscore$zscore/mask$mask

# take average of 'transformed', across subjects
outfile=$resultsdir/subjavg
cmdstr="fslavg $outfile"
for subj in $subjnums; do
    cmdstr="$cmdstr $resultsdir/SFR$subj/transformed"
done
`$cmdstr`
