Types of analyses
1. ridge -- ridge regression to the posterior (one regression for each sector)
2. logregMAPmulti -- multinomial logistic regression
                        traindata = 1 when that sector is the MAP
                        traindata = 0 otherwise
3. logregMAP -- logistic regression (one logreg for each sector)
                        traindata = 1 when that sector is the MAP
                        traindata = 0 otherwise

Scripts:
1. make_runs_selector.m
2. make_regressors.m
3. load_data.sh
4. searchlight/readme.txt