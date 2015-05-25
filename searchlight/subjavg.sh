#!/bin/bash
# Take average across subjects (of 'transformed')

subjnums=$1
radius=$2
penalty=$3

# basics
resultsdir=../../results/searchlights/radius$radius/penalty$penalty

# take average of 'transformed', across subjects
outfile=$resultsdir/subjavg
cmdstr="fslavg $outfile"
for subj in $subjnums; do
    cmdstr="$cmdstr $resultsdir/SFR$subj/transformed"
done
`$cmdstr`
