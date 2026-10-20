function ci_run(job, varargin)
%CI_RUN  Entry point of the GitHub Actions jobs (.github/workflows/verify.yml).
%   ci_run('reference')           plain-MATLAB recreation (matlab/run_all.m), the
%                                 scenario reference of matlab/boost_sim.m and the
%                                 paper checks of Sections II-IV
%   ci_run('simulink', 'diffeq')  build the models, run every scenario on the given
%   ci_run('simulink', 'sps')     plant, compare with the reference and the paper
%   ci_run('frestimate')          Section II-A with Simulink Control Design
%   ci_run('compat')              build every model and run a subset of scenarios
%                                 in an older MATLAB release
%   ci_run('report', artDir, 'job=result ...')   SUMMARY.md from all artifacts
%   Results go to results/<job>[_<plant>]/ with a log.txt. Errors and failed
%   checks are re-thrown at the end so the CI step fails. The same jobs can be
%   run on a desktop MATLAB (see run_recreation.m in the repository root).
root = setup_paths();
cd(root);
if strcmp(job, 'report')
    ci_report(varargin{:});
    return
end
switch job
    case 'reference'
        out = fullfile(root, 'results', 'reference');
    case 'simulink'
        out = fullfile(root, 'results', ['simulink_' varargin{1}]);
    case 'frestimate'
        out = fullfile(root, 'results', 'frestimate');
    case 'compat'
        out = fullfile(root, 'results', ['compat_' release_name()]);
    otherwise
        error('ci_run:job', 'Unknown job %s', job);
end
if ~exist(out, 'dir')
    mkdir(out);
end
diary(fullfile(out, 'log.txt'));
cleanupDiary = onCleanup(@() diary('off'));
ok = true;
report = '';
checks = cell(0, 2);               % {name, ok} of every comparison / paper check
tJob = tic;
refDir = fullfile(root, 'results', 'reference');
refMetrics = fullfile(refDir, 'metrics_reference.csv');
refTraces = fullfile(refDir, 'traces_reference');
try
    probe_environment();
    switch job
        case 'reference'
            export_reference(out);
            [~, okA] = paper_checks('analysis', 'analysis', out);
            [~, okS] = paper_checks('simulation', 'matlab_script', out, ...
                fullfile(out, 'metrics_reference.csv'));
            checks = [checks; {'paper checks (analysis)', okA}; ...
                {'paper checks (matlab_script)', okS}];
            evalin('base', sprintf('run(''%s'')', fullfile(root, 'matlab', 'run_all.m')));
            cd(root);
            if exist(fullfile(root, 'results_matlab'), 'dir')
                copyfile(fullfile(root, 'results_matlab'), fullfile(out, 'run_all_outputs'));
            end
        case 'simulink'
            plant = varargin{1};
            plants = {plant};
            if strcmp(plant, 'diffeq')
                plants{end + 1} = 'average';            % build and compile-check only
            end
            modeldir = fullfile(root, 'models');
            build_boost_models('plants', plants, 'outdir', modeldir);
            sanity_check(plant);
            print_model_diagrams(modeldir, fullfile(out, 'model_diagrams'));
            run_simulink_study(plant, out, 'models', modeldir, 'reftraces', refTraces);
            label = ['simulink_' plant];
            metrics = fullfile(out, sprintf('metrics_simulink_%s.csv', plant));
            [~, okC] = compare_metrics(refMetrics, metrics, label, out);
            [~, okP] = paper_checks('simulation', label, out, metrics);
            checks = [checks; {['reference vs ' label], okC}; {['paper checks (' label ')'], okP}];
            if strcmp(plant, 'sps')
                loss_sensitivity(out);
            end
            copyfile(modeldir, fullfile(out, 'models'));
        case 'frestimate'
            modeldir = fullfile(root, 'models');
            build_boost_models('plants', {'sps'}, 'controllers', {}, 'openloop', false, ...
                'outdir', modeldir);
            run_frestimate_study('sps', out);
            [~, okF] = paper_checks('frestimate', 'frestimate', out, ...
                fullfile(out, 'frestimate_fits.csv'));
            checks = [checks; {'paper checks (frestimate)', okF}];
            copyfile(modeldir, fullfile(out, 'models'));
        case 'compat'
            checks = compat_check(out, refMetrics);
    end
catch err
    ok = false;
    report = getReport(err, 'extended', 'hyperlinks', 'off');
    fprintf(2, '\n*** ci_run(%s) failed ***\n%s\n', job, report);
    annotate('error', sprintf('ci_run(%s)', job), report);
end
fprintf('ci_run(%s) finished in %.1f min\n', job, toc(tJob) / 60);
for k = 1:size(checks, 1)
    word = 'passed';
    if ~checks{k, 2}
        word = 'FAILED';
    end
    fprintf('  check %-40s %s\n', checks{k, 1}, word);
end
clear cleanupDiary
if ~ok
    error('ci_run:failed', 'ci_run(%s) failed: %s', job, report);
end
bad = checks(~[checks{:, 2}], 1);
if ~isempty(bad)
    msg = sprintf('Not as expected: %s (see comparison_*.md and paper_checks_*.md).', ...
        strjoin(bad, ', '));
    annotate('error', sprintf('ci_run(%s) checks', job), msg);
    error('ci_run:checks', 'ci_run(%s): %s', job, msg);
end
end

% -------------------------------------------------------------------------
function checks = compat_check(out, refMetrics)
%COMPAT_CHECK  Build every model with this (older) release and run a subset of
%   the scenarios on the differential-equation plant (and the circuit plant
%   when Simscape Electrical is installed); compare with the reference.
root = setup_paths();
modeldir = fullfile(root, 'models');
files = build_boost_models('outdir', modeldir);
fprintf('compat: built %d models with MATLAB %s\n', numel(files), version);
fid = fopen(fullfile(out, 'built_models.txt'), 'w');
fprintf(fid, '%s\n', files{:});
fclose(fid);
plants = {'diffeq'};
if exist(fullfile(modeldir, 'boost_cascade_pi_sps.slx'), 'file')
    plants{end + 1} = 'sps';
end
sanity_check(plants{end});
ctrlModel = struct('pi', 'single_pi', 'cascade', 'cascade_pi', 'mrac', 'cascade_pi_mrac', ...
    'mrac_mf', 'cascade_pi_mrac_mf');
subset = {'lr_g0.5', 'f16_cascade', 'f18_cascade', 'f18_mrac', 'f18_mrac_mf', 'exp_cascade'};
S = scenario_list();
checks = cell(0, 2);
for p = plants
    rows = {};
    for name = subset
        s = S(strcmp({S.name}, name{1}));
        mdl = sprintf('boost_%s_%s', ctrlModel.(s.ctrl), p{1});
        r = run_case(mdl, s);
        m = scenario_metrics(s.name, r.t, r.v, r.iL, r.theta, r.ym);
        f = fieldnames(m);
        for j = 1:numel(f)
            rows(end + 1, :) = {s.name, f{j}, m.(f{j})}; %#ok<AGROW>
        end
        fprintf('  compat %-8s %-14s %5.1f s\n', p{1}, s.name, r.wall);
    end
    label = sprintf('compat_%s_%s', release_name(), p{1});
    file = fullfile(out, sprintf('metrics_%s.csv', label));
    fid = fopen(file, 'w');
    fprintf(fid, 'scenario,metric,value\n');
    for i = 1:size(rows, 1)
        fprintf(fid, '%s,%s,%.17g\n', rows{i, 1}, rows{i, 2}, rows{i, 3});
    end
    fclose(fid);
    [~, okC] = compare_metrics(refMetrics, file, label, out, subset);
    checks = [checks; {['reference vs ' label], okC}]; %#ok<AGROW>
end
bdclose('all');
end

function r = release_name()
%RELEASE_NAME  'R2025a' etc.
r = regexprep(version('-release'), '^(\d+)', 'R$1');
end

function sanity_check(plant)
%SANITY_CHECK  Open-loop run at D = 0.5: every plant must settle near +40 V.
bm = boost_mrac_params('duty_ol', 0.5);
load_system('boost_openloop_models');
out = sim('boost_openloop_models', 'StopTime', '0.05');
names = {'v_de_diode', 'v_de_bidir', 'v_tf'};
if strcmp(plant, 'sps')
    names = [{'v_sps', 'iL_sps'}, names];
end
for k = 1:numel(names)
    x = squeeze(out.get(names{k}).Data);
    n = round(0.04 / bm.Ts);
    fprintf('  sanity %-12s mean over 40-50 ms = %8.3f   max = %8.3f\n', names{k}, ...
        mean(x(n:end)), max(x));
    if startsWith(names{k}, 'v_')
        assert(abs(mean(x(n:end)) - 40) < 3, 'sanity_check:vout', ...
            '%s settles at %.2f V instead of about 40 V (wiring or polarity).', ...
            names{k}, mean(x(n:end)));
    end
end
end

function loss_sensitivity(out)
%LOSS_SENSITIVITY  Single PI and MRAC with the Simscape Electrical default
%   devices (MOSFET Ron = 0.1 Ohm, diode Ron = 1 mOhm, Vf = 0.8 V).
S = scenario_list();
ctrlModel = struct('pi', 'single_pi', 'mrac', 'cascade_pi_mrac');
names = {'f18_pi', 'f18_mrac'};
fid = fopen(fullfile(out, 'loss_sensitivity.csv'), 'w');
fprintf(fid, 'scenario,devices,metric,value\n');
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1000 420]);
hold on; grid on; box on;
cols = {[0.165 0.471 0.839], [0.922 0.408 0.204]};
leg = {};
for k = 1:numel(names)
    s = S(strcmp({S.name}, names{k}));
    mdl = sprintf('boost_%s_sps', ctrlModel.(s.ctrl));
    ideal = run_case(mdl, s);
    lossy = run_case(mdl, s, 'Ron_sw', 0.1, 'Ron_d', 1e-3, 'Vf_d', 0.8);
    for dev = {'ideal', 'default'}
        if strcmp(dev{1}, 'ideal'), r = ideal; else, r = lossy; end
        m = scenario_metrics(s.name, r.t, r.v, r.iL, r.theta, r.ym);
        fn = fieldnames(m);
        for j = 1:numel(fn)
            fprintf(fid, '%s,%s,%s,%.10g\n', s.name, dev{1}, fn{j}, m.(fn{j}));
        end
    end
    if k == 1
        plot(ideal.t, ideal.v, 'Color', cols{1}, 'LineWidth', 0.8);
        plot(lossy.t, lossy.v, 'Color', cols{2}, 'LineWidth', 0.8);
        leg = {'Single PI, ideal devices', ...
            'Single PI, Simscape default devices (R_{on} = 0.1 \Omega, V_f = 0.8 V)'};
    end
end
fclose(fid);
xlabel('Time (s)'); ylabel('Output voltage (V)'); xlim([0 0.5]); ylim([0 60]);
legend(leg, 'Location', 'southeast');
title('Single PI under reference steps in the SPS circuit: effect of device losses');
figdir = fullfile(out, 'figures');
if ~exist(figdir, 'dir'), mkdir(figdir); end
exportgraphics(f, fullfile(figdir, 'loss_sensitivity_single_pi.png'), 'Resolution', 150);
close(f);
end

function annotate(level, title, msg)
%ANNOTATE  GitHub Actions workflow command, shown as an annotation of the job.
if isempty(getenv('GITHUB_ACTIONS'))
    return
end
msg = strrep(msg, '%', '%25');
msg = strrep(msg, sprintf('\r'), '%0D');
msg = strrep(msg, sprintf('\n'), '%0A');
if numel(msg) > 6000
    msg = [msg(1:6000) '...'];
end
fprintf('::%s title=%s::%s\n', level, title, msg);
end
