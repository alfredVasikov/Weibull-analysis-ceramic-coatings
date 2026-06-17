This MATLAB script fits experimental data to a two-parameter Weibull distribution using Maximum Likelihood Estimation.
It automates reliability quantification, goodness-of-fit validation, and statistical plotting.

TECHNICAL CAPABILITIES:
The script calculates the shape parameter (m) for failure behavior and the scale parameter (σ) for characteristic strength.
It extracts the 5th (q₀₅) and 95th (q₉₅) percentiles to define safety limits.
Model fidelity is validated by comparing the empirical coefficient of determination (R²) against the threshold R²(critical).
Automated outputs include Probability Density Function (PDF) curves, linearized log-Weibull plots and Excel spreadsheet (weibull_results), 
compiling m, σ, q₀₅, q₉₅, R², and R²(critical) values for each specimen.

Input file ("weibull_data"): Data matrix (CSV/Txt), where each column represents independent samples of one specimen.
