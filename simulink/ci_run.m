function ci_run(job, varargin)
%CI_RUN  Entry point of the GitHub Actions jobs (.github/workflows/verify.yml).
%   ci_run('matlab_scripts')      run matlab/run_all.m, export the scenario
%                                 metrics of matlab/boost_sim.m, compare with Python
%   ci_run('simulink', 'diffeq')  build the models, run every scenario on the
%   ci_run('simulink', 'sps')     given plant, compare with Python
%   ci_run('frestimate')          Section II-A with Simulink Control Design
%   Results go to results/<job>[_<plant>]/ ; the log is results/.../log.txt.
%   Errors are re-thrown at the end so the CI step fails.
root = setup_paths();
cd(root);
switch job
    case 'matlab_scripts'
        out = fullfile(root, 'results', 'matlab_scripts');
    case 'simulink'
        out = fullfile(root, 'results', ['simulink_' varargin{1}]);
    case 'frestimate'
        out = fullfile(root, 'results', 'frestimate');
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
okCompare = true;
tJob = tic;
try
    probe_environment();
    ref = fullfile(root, 'results', 'reference', 'metrics_python.csv');
    traces = fullfile(root, 'results', 'reference', 'traces_python');
    switch job
        case 'matlab_scripts'
            evalin('base', sprintf('run(''%s'')', fullfile(root, 'matlab', 'run_all.m')));
            cd(root);
            if exist(fullfile(root, 'results_matlab'), 'dir')
                copyfile(fullfile(root, 'results_matlab'), fullfile(out, 'run_all_outputs'));
            end
            export_metrics_matlab_scripts(out);
            [~, okCompare] = compare_metrics(ref, fullfile(out, 'metrics_matlab_scripts.csv'), ...
                'matlab_scripts', out);
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
            run_simulink_study(plant, out, 'models', modeldir, 'pytraces', traces);
            label = ['simulink_' plant];
            [~, okCompare] = compare_metrics(ref, fullfile(out, ...
                sprintf('metrics_simulink_%s.csv', plant)), label, out);
            if strcmp(plant, 'sps')
                loss_sensitivity(out);
            end
            copyfile(modeldir, fullfile(out, 'models'));
        case 'frestimate'
            modeldir = fullfile(root, 'models');
            build_boost_models('plants', {'sps'}, 'controllers', {}, 'openloop', false, ...
                'outdir', modeldir);
            run_frestimate_study('sps', out);
            copyfile(modeldir, fullfile(out, 'models'));
    end
catch err
    ok = false;
    report = getReport(err, 'extended', 'hyperlinks', 'off');
    fprintf(2, '\n*** ci_run(%s) failed ***\n%s\n', job, report);
    annotate('error', sprintf('ci_run(%s)', job), report);
end
fprintf('ci_run(%s) finished in %.1f min\n', job, toc(tJob) / 60);
clear cleanupDiary
if ~ok
    error('ci_run:failed', 'ci_run(%s) failed: %s', job, report);
end
if ~okCompare
    annotate('error', sprintf('ci_run(%s) comparison', job), ...
        'Some gating metrics differ from the Python reference; see comparison_*.md.');
    error('ci_run:compare', ['ci_run(%s): some gating metrics differ from the Python ' ...
        'reference (see comparison_*.md).'], job);
end
end

% -------------------------------------------------------------------------
function sanity_check(plant)
%SANITY_CHECK  Open-loop run at D = 0.5: the circuit must give about +40 V.
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
assert(s.T == 0.05);
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
msg = strrep(msg, '%', '%25');
msg = strrep(msg, sprintf('\r'), '%0D');
msg = strrep(msg, sprintf('\n'), '%0A');
if numel(msg) > 6000
    msg = [msg(1:6000) '...'];
end
fprintf('::%s title=%s::%s\n', level, title, msg);
end
