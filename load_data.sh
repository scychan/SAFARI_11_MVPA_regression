#!/bin/bash

# set 'copy' function
shopt -s expand_aliases
if ismachine rondo; then
    echo 'is rondo'
    alias copy='rsync -av'
else
    echo 'is not rondo'
    alias copy='rsfa -f'
fi

# subjnums and directory shortcuts
subjnums='101 102 103 104 105 106 107 108 109 110 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 129 130 131 132 133 134'
SFR='/jukebox/norman/stephanie/safari'

# Prompt for instructions
read -p 'Copy all data? (y/n) ' copyall
if [ ! $copyall = 'y' ]; then
    read -p 'Copy whole-brain masks? (y/n) ' copybrainmasks
    read -p 'Copy run lengths? (y/n) ' copyrunlens
    read -p 'Copy EPIs? (y/n) ' copyEPIs
    read -p 'Copy regressors/selectors? (y/n) ' copyregs
fi


# iterate through subjects
for subj in $subjnums; do

    # make data directory
    subjdir=../data/SFR$subj
    mkdir_ifnotexist $subjdir

    # load wholebrain masks
    if [ $copyall = 'y' ] || [ $copybrainmasks = 'y' ]; then
	copy $SFR/6_fMRI_data/SFR$subj/feat_preproc/run1_mc_fmu.feat/mask.nii.gz $subjdir/mask_wholebrain.nii.gz
    fi
    
    # load run_lengths
    if [ $copyall = 'y' ] || [ $copyrunlens = 'y' ]; then
	copy $SFR/6_fMRI_data/SFR$subj/run_lengths.txt $subjdir/
    fi

    # load EPI data (take runs only, and gunzip)
    if [ $copyall = 'y' ] || [ $copyEPIs = 'y' ]; then
	copy $SFR/6_fMRI_data/SFR$subj/nifti/big4D_mc_fmu.nii.gz $subjdir/
	sumTRs=0; for i in `cat run_lengths.txt`; do echo $i; sumTRs=$((sumTRs+$i)); done
	fslroi $subjdir/big4D_mc_fmu $subjdir/big4D_mc_fmu_runs 0 $sumTRs
	gunzip $subjdir/big4D_mc_fmu_runs
	rm $subjdir/big4D_mc_fmu
    fi

    # load regressors/selectors
    if [ $copyall = 'y' ] || [ $copyregs = 'y' ]; then
	copy $SFR/11_MVPA_regression/results/regressors/SFR$subj/* $subjdir
    fi
    
done