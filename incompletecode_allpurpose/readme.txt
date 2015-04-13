1. make_regressors.m
2. set_params_and_run.m
     calls run_mvpa.m
3. submit_inner_loops.sh
      run_mvpa_inner_loops.m
          calls run_xvalidation.m
4. run_mvpa_outer_loops.m
     calls run_xvalidation.m

Analyze data
* perf_across_subjs.m
* importance_maps.m
    
Other analyses
* entropy_vs_regs.m  -- is entropy correlated with the indiv latent cause regressors?