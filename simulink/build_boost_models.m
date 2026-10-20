function files = build_boost_models(varargin)
%BUILD_BOOST_MODELS  Build every Simulink model of the recreation with the Simulink API.
%
%   build_boost_models()                               all models the installed products allow
%   build_boost_models('plants', {'diffeq'})           only some plants
%   build_boost_models('controllers', {'cascade_pi_mrac'}, 'outdir', 'my_models')
%
%   Closed-loop models  boost_<controller>_<plant>.slx
%     controllers  single_pi           Fig. 8,  Eq. 33
%                  cascade_pi          Fig. 9,  Eqs. 42-43
%                  cascade_pi_mrac     Figs. 10, 12, 19; Eqs. 44, 54-56 as written
%                  cascade_pi_mrac_mf  same, outer loop tracks the reference-model output
%     plants       sps      circuit (Specialized Power Systems; needs Simscape Electrical)
%                  diffeq   differential-equation model of Fig. 6 (Simulink only)
%                  average  state-space averaged model, Eqs. 3-9 (Simulink only)
%   Open-loop model     boost_openloop_models.slx   (Fig. 7)
%   Frequency response  boost_frest_<plant>.slx     (Fig. 1, Eq. 2)
%
%   Models are written to <repo>/models by default. Parameters live in the
%   base-workspace struct BM (boost_mrac_params.m); each model's PreLoadFcn
%   and InitFcn create BM if it is missing.
root = setup_paths();
opts.plants = {'sps', 'diffeq', 'average'};
opts.controllers = {'single_pi', 'cascade_pi', 'cascade_pi_mrac', 'cascade_pi_mrac_mf'};
opts.outdir = fullfile(root, 'models');
opts.openloop = true;
opts.frest = true;
for k = 1:2:numel(varargin)
    assert(isfield(opts, varargin{k}), 'build_boost_models:option', ...
        'Unknown option %s', varargin{k});
    opts.(varargin{k}) = varargin{k + 1};
end
if ~exist(opts.outdir, 'dir')
    mkdir(opts.outdir);
end
addpath(opts.outdir);
load_system('simulink');
spsOk = has_sps();
if ~spsOk && any(strcmp(opts.plants, 'sps'))
    warning('build_boost_models:noSps', ['Simscape Electrical (Specialized Power ' ...
        'Systems) is not available: skipping the circuit plant.']);
    opts.plants = setdiff(opts.plants, {'sps'}, 'stable');
end
boost_mrac_params();
files = {};
for p = opts.plants
    for c = opts.controllers
        mdl = build_closed_loop_model(c{1}, p{1}, opts.outdir);
        files{end + 1} = fullfile(opts.outdir, [mdl '.slx']); %#ok<AGROW>
    end
end
if opts.openloop
    mdl = build_openloop_model(opts.outdir, spsOk);
    files{end + 1} = fullfile(opts.outdir, [mdl '.slx']);
end
if opts.frest
    for p = intersect(opts.plants, {'sps', 'diffeq'}, 'stable')
        mdl = build_frest_model(p{1}, opts.outdir);
        files{end + 1} = fullfile(opts.outdir, [mdl '.slx']); %#ok<AGROW>
    end
end
fprintf('build_boost_models: %d models in %s\n', numel(files), opts.outdir);
end

function ok = has_sps()
ok = false;
try
    ok = license('test', 'Power_System_Blocks') && ~isempty(which('sps_lib'));
    if ok
        load_system('sps_lib');
    end
catch err
    fprintf('Specialized Power Systems not usable: %s\n', err.message);
    ok = false;
end
end
