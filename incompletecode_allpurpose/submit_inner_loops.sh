#!/bin/bash
# USAGE: bash submit_inner_loops.sh $SUBJNUM

subjnum=$1

njobs=`cat ../tempdata/SFR$subjnum/n_inner_loops.txt`
submit_short $njobs run_mvpa_inner_loops.m SFR$subjnum
