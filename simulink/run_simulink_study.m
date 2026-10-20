function R = run_simulink_study(plant, outdir, varargin)
%RUN_SIMULINK_STUDY  Run every scenario of scenario_list on the Simulink models.
%   R = run_simulink_study('diffeq', outdir)   differential-equation plant
%   R = run_simulink_study('sps', outdir)      circuit plant (Simscape Electrical)
%   R = run_simulink_study(..., 'models', dir)       folder with the built models
%   R = run_simulink_study(..., 'pytraces', dir)     add overlays with the Python traces
%   R = run_simulink_study(..., 'Ron_sw', 0.1, ...)  extra BM overrides
%
%   Writes  <outdir>/metrics_simulink_<plant>.csv   (scenario, metric, value)
%           <outdir>/figures/*.png                  Figs. 7, 13-18, 22-24
%   Returns a containers.Map scenario name -> result struct (see run_case).
root = setup_paths();
modeldir = fullfile(root, 'models');
pytraces = '';
over = {};
k = 1;
while k <= numel(varargin)
    if strcmp(varargin{k}, 'models')
        modeldir = varargin{k + 1};
    elseif strcmp(varargin{k}, 'pytraces')
        pytraces = varargin{k + 1};
    else
        over(end + 1:end + 2) = varargin(k:k + 1); %#ok<AGROW>
    end
    k = k + 2;
end
addpath(modeldir);
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
ctrlModel = struct('pi', 'single_pi', 'cascade', 'cascade_pi', 'mrac', 'cascade_pi_mrac', ...
    'mrac_mf', 'cascade_pi_mrac_mf');
S = scenario_list();
R = containers.Map();
rows = {};
olRun = [];
tStudy = tic;
for i = 1:numel(S)
    s = S(i);
    if strcmp(s.ctrl, 'open')
        if isempty(olRun)
            olRun = run_openloop(s, over);
        end
        r = pick_openloop(olRun, s.name, plant);
    else
        mdl = sprintf('boost_%s_%s', ctrlModel.(s.ctrl), plant);
        r = run_case(mdl, s, over{:});
    end
    m = scenario_metrics(s.name, r.t, r.v, r.iL, r.theta, r.ym);
    f = fieldnames(m);
    for j = 1:numel(f)
        rows(end + 1, :) = {s.name, f{j}, m.(f{j})}; %#ok<AGROW>
    end
    R(s.name) = r;
    fprintf('  %-14s %6.1f s  %s\n', s.name, r.wall, metric_text(m));
end
fprintf('run_simulink_study(%s): %d scenarios in %.1f min\n', plant, numel(S), toc(tStudy) / 60);
write_metrics(fullfile(outdir, sprintf('metrics_simulink_%s.csv', plant)), rows);
plot_study_figures(R, plant, fullfile(outdir, 'figures'), pytraces);
bdclose('all');
end

% -------------------------------------------------------------------------
function ol = run_openloop(s, over)
bm = boost_mrac_params('duty_ol', s.duty, over{:});
mdl = 'boost_openloop_models';
load_system(mdl);
tic;
out = sim(mdl, 'StopTime', sprintf('%.12g', s.T));
ol.wall = toc;
N = round(s.T / bm.Ts);
ol.t = (0:N - 1).' * bm.Ts;
for name = {'v_sps', 'iL_sps', 'v_de_diode', 'iL_de_diode', 'v_de_bidir', 'iL_de_bidir', 'v_tf'}
    try
        x = squeeze(out.get(name{1}).Data);
        ol.(name{1}) = x(1:N);
    catch
        ol.(name{1}) = nan(N, 1);
    end
end
end

function r = pick_openloop(ol, name, plant)
r.t = ol.t;
r.wall = ol.wall;
switch name
    case 'ol_diode'
        if strcmp(plant, 'sps')
            r.v = ol.v_sps;
            r.iL = ol.iL_sps;
        else
            r.v = ol.v_de_diode;
            r.iL = ol.iL_de_diode;
        end
    case 'ol_bidir'
        r.v = ol.v_de_bidir;
        r.iL = ol.iL_de_bidir;
end
r.v_tf = ol.v_tf;
r.v_sps = ol.v_sps;
r.v_de_bidir = ol.v_de_bidir;
n = numel(r.t);
r.theta = ones(n, 1);
r.ym = zeros(n, 1);
r.d = 0.5 * ones(n, 1);
r.iref = zeros(n, 1);
r.vref = zeros(n, 1);
end

function txt = metric_text(m)
f = fieldnames(m);
parts = cell(1, numel(f));
for j = 1:numel(f)
    parts{j} = sprintf('%s=%.5g', f{j}, m.(f{j}));
end
txt = strjoin(parts, '  ');
end

function write_metrics(file, rows)
fid = fopen(file, 'w');
fprintf(fid, 'scenario,metric,value\n');
for i = 1:size(rows, 1)
    fprintf(fid, '%s,%s,%.17g\n', rows{i, 1}, rows{i, 2}, rows{i, 3});
end
fclose(fid);
fprintf('  wrote %s\n', file);
end
