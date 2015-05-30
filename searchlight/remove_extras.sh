#!/bin/bash

for v in {1..$nvox}; do
    if ( ls -d vox${v}_* | wc -w ) > 1; then
	second=`ls -d vox${v}_* | sed -n 2p`
	rm -rf $second
    fi
done 