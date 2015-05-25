 #!/bin/bash

radius=$1
penalty=$2
prefix=$3 # prefix for randomise results

# paths
resultsdir=../../results/searchlights/radius$radius/penalty$penalty
randomisedir=$resultsdir/randomise

# remove unnecessaries
rm -rfv $randomisedir/${prefix}_logs
rm -fv $randomisedir/${prefix}.defragment
rm -fv $randomisedir/${prefix}.generate
