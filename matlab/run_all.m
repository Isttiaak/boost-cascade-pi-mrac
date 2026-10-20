%RUN_ALL  Runs the complete MATLAB recreation (figures and tables go to ../results_matlab).
%   Requires MATLAB R2018b or newer with the Control System Toolbox.
%   Typical run time: 10-20 minutes (the frequency-response sweep dominates).
%   Run from this folder:  >> run_all
here = fileparts(mfilename('fullpath'));
cd(here);
tic;
verify_equations;      % printed vs recomputed equations
sec2_3_modeling;       % Fig. 1, Eq. 2, Table 6, Fig. 5, Fig. 7
sec4_design;           % controllers, reference model, loop analysis
sec5_6_simulations;    % Figs. 13-18, Table 10, Figs. 22-24
fprintf('\nAll done in %.1f min. Results in ../results_matlab\n', toc/60);
