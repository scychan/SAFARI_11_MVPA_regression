- submit1_precomputations.sh
	calls precomputations.m

- submit2_rungroups.sh
	calls set_params_and_run_mvpa.m, run_mvpa.m

- if any missed voxels:
     - check_searchlight_results.sh
     - manually split check_results.txt into rows, using Emacs macros
     - submit2_rungroups_missed.sh

- compile_results.m

- interpolate.m

- transform.sh
