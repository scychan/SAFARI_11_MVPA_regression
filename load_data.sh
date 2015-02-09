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

# ask which data to download XX

# iterate through subjects
for subj in $subjnums; do

    # make data directory
    subjdir=../data/SFR$subj
    mkdir_ifnotexist $subjdir

    # load wholebrain masks
    copy $SFR/6_fMRI_data/SFR$subj/feat_preproc/run1_mc_fmu.feat/mask.nii.gz $subjdir/mask_wholebrain.nii.gz
    
    # load EPI data XX

    # load run_lengths XX

    # load regressors/selectors XX

done