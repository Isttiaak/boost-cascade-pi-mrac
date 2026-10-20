%RUN_RECREATION  Run the whole recreation on your own MATLAB, exactly as GitHub Actions does.
%
%   >> run_recreation
%
%   1. reference   plain-MATLAB recreation (matlab/run_all.m: equations, Table 6,
%                  Figs. 1, 5, 7, 13-18, Table 10) and the scenario reference of
%                  matlab/boost_sim.m, plus the paper checks of Sections II-IV
%   2. simulink    builds every Simulink model (simulink/build_boost_models.m),
%                  runs the 21 scenarios on the differential-equation plant and,
%                  with Simscape Electrical, on the circuit plant; compares each
%                  with the reference and with the paper
%   3. frestimate  Section II-A with Simulink Control Design (if installed)
%   4. summary     results/SUMMARY.md
%
%   Products: MATLAB, Simulink, Control System Toolbox. Optional: Simscape and
%   Simscape Electrical (circuit plant), Simulink Control Design (frestimate).
%   Run time on a desktop: about 15-25 minutes. Outputs: results/<job>/ (log,
%   tables, figures, model diagrams) and models/*.slx.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'simulink'));
setup_paths();
has = @(lic) license('test', lic) == 1;
jobs = {};
if has('Control_Toolbox')
    jobs(end + 1, :) = {'reference', {}};
else
    warning('run_recreation:cst', ['The Control System Toolbox is missing: skipping the ' ...
        'reference job (the Simulink jobs then have nothing to compare with).']);
end
jobs(end + 1, :) = {'simulink', {'diffeq'}};
if has('Power_System_Blocks') && ~isempty(which('sps_lib'))
    jobs(end + 1, :) = {'simulink', {'sps'}};
else
    fprintf('Simscape Electrical not found: skipping the circuit (sps) plant.\n');
end
if has('Simulink_Control_Design') && has('Power_System_Blocks')
    jobs(end + 1, :) = {'frestimate', {}};
else
    fprintf('Simulink Control Design or Simscape Electrical not found: skipping frestimate.\n');
end
results = cell(size(jobs, 1), 1);
for k = 1:size(jobs, 1)
    name = strjoin([jobs(k, 1), jobs{k, 2}], '-');
    fprintf('\n==================== %s ====================\n', name);
    try
        ci_run(jobs{k, 1}, jobs{k, 2}{:});
        results{k} = [name '=success'];
    catch err
        fprintf(2, '%s: %s\n', name, err.message);
        results{k} = [name '=failure'];
    end
end
ci_report(fullfile(root, 'results'), strjoin(results, ' '));
fprintf('\nSummary: %s\n', fullfile(root, 'results', 'SUMMARY.md'));
