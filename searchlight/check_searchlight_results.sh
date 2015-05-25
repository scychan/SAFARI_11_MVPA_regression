#!/bin/bash
subjnum=$1
radius=$2
penalty=$3

# resultsdir
resultsdir=../../results/searchlights/radius$radius/penalty$penalty/SFR$subjnum
echo $resultsdir

# get nvox
. $resultsdir/precomputations/groupstats.sh

# check that all the voxels are there
outfile=$resultsdir/check_results.txt
rm $outfile
touch $outfile
for i in `seq 1 $nvox`; do
    # print $i for every 100 voxels
    if [ $(( $i % 100 )) = 0 ]; then echo $i; fi
    # check for the directory
    if ! ls -duf $resultsdir//searchlights/vox${i}_* &> /dev/null; then
	echo "$i " >> $outfile
    fi
done
