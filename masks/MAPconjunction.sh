#!/bin/bash

smoothed=1
motregs=both
whichTRs=01
radius=3
whichstims=all
likelihoodset=actual
corr=Spearman
episuffix=mc_fmu

thresholds='0.95 0.99'
dir=/jukebox/norman/stephanie/safari/7_RSA/results/compare_RSmats_searchlight/smoothed${smoothed}/motregs_${motregs}/whichTRs${whichTRs}/radius${radius}/whichstims_${whichstims}/likelihoodset_${likelihoodset}/${corr}_corr/${episuffix}/standard_space/randomise/modeldiffs_posdiffs/MAP
basename=$dir/conjunction_allsubjs_tfce_corrp_tstat1_thr

maskdir=../../results/masks
mkdir_ifnotexist $maskdir

for thresh in $thresholds; do
    orig=${basename}${thresh}
    mask=$maskdir/MAPconjunction${thresh}
    fslmaths $orig -bin $mask
done
