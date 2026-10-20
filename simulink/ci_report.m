function file = ci_report(artDir, jobResults)
%CI_REPORT  Combine the CI artifacts into one Markdown summary.
%   file = ci_report(artDir, 'reference=success simulink=success ...')
%   artDir holds one folder per artifact (reference, simulink-diffeq,
%   simulink-sps, frestimate, compat-<release>) or is the local results/
%   folder of run_recreation.m. Writes <artDir>/SUMMARY.md, which the
%   workflow also shows as the run's job summary.
if nargin < 2
    jobResults = '';
end
L = {};
L{end + 1} = '# Verification of the Yanarates & Zhou (2022) recreation in MATLAB/Simulink';
L{end + 1} = '';
L{end + 1} = sprintf('Summary written by `simulink/ci_report.m` with MATLAB %s.', version);
L{end + 1} = '';

% ---- jobs ----------------------------------------------------------------------
pairs = strsplit(strtrim(jobResults));
if ~isempty(pairs) && ~isempty(pairs{1})
    L{end + 1} = '| Job | Result |';
    L{end + 1} = '|---|---|';
    for k = 1:numel(pairs)
        kv = strsplit(pairs{k}, '=');
        if numel(kv) < 2
            continue
        end
        L{end + 1} = sprintf('| %s | %s |', kv{1}, job_word(kv{2})); %#ok<AGROW>
    end
    L{end + 1} = '';
end

% ---- paper checks: analysis -------------------------------------------------------
A = read_checks(fullfile(sub(artDir, 'reference'), 'paper_checks_analysis.csv'));
if ~isempty(A)
    L{end + 1} = '## Paper checks: transfer functions and tables (Sections II-IV)';
    L{end + 1} = '';
    L{end + 1} = ['Table 6 is recomputed with MATLAB''s `stepinfo` on the printed Eq. 2 and ' ...
        'Eq. 32; "differs" rows confirm printed numbers that contradict the paper''s own formulas.'];
    L{end + 1} = '';
    L = [L, check_table(A, {'Recreated'}, {A})];
end

% ---- paper checks: simulations ------------------------------------------------------
impl = {'reference', 'matlab_script', 'MATLAB script'; ...
    'simulink-diffeq', 'simulink_diffeq', 'Simulink diffeq'; ...
    'simulink-sps', 'simulink_sps', 'Simulink circuit (SPS)'};
Ts = {}; names = {};
for k = 1:size(impl, 1)
    T = read_checks(fullfile(sub(artDir, impl{k, 1}), sprintf('paper_checks_%s.csv', impl{k, 2})));
    if ~isempty(T)
        Ts{end + 1} = T; %#ok<AGROW>
        names{end + 1} = impl{k, 3}; %#ok<AGROW>
    end
end
if ~isempty(Ts)
    L{end + 1} = '## Paper checks: simulations (Figs. 7, 13-16, Table 10)';
    L{end + 1} = '';
    L{end + 1} = ['Paper values marked (fig.) are read off the paper''s figures. Table 10 is the ' ...
        '30 -> 40 V reference step at 0.2 s.'];
    L{end + 1} = '';
    L = [L, check_table(Ts{1}, names, Ts)];
end

% ---- paper checks: frestimate -------------------------------------------------------
F = read_checks(fullfile(sub(artDir, 'frestimate'), 'paper_checks_frestimate.csv'));
if ~isempty(F)
    L{end + 1} = '## Paper checks: frequency response with Simulink Control Design (Section II-A)';
    L{end + 1} = '';
    L = [L, check_table(F, {'frestimate'}, {F})];
end
fits = fullfile(sub(artDir, 'frestimate'), 'frestimate_fits.csv');
if exist(fits, 'file')
    R = readtable(fits, 'TextType', 'char', 'Delimiter', ',');
    L{end + 1} = '| Source | DC gain | Zero (rad/s) | Poles (rad/s) | zeta | Fit (%) |';
    L{end + 1} = '|---|---|---|---|---|---|';
    for i = 1:height(R)
        L{end + 1} = sprintf('| %s | %.4g | %.5g | %s, %s | %.3g | %s |', R.source{i}, ...
            R.dc_gain(i), R.zero_rad_s(i), cstr(R.pole1(i)), cstr(R.pole2(i)), R.zeta(i), ...
            num(R.fit_pct(i))); %#ok<AGROW>
    end
    L{end + 1} = '';
end

% ---- agreement between implementations ----------------------------------------------
cmp = dir(fullfile(artDir, '*', 'comparison_*.csv'));
if ~isempty(cmp)
    L{end + 1} = '## Agreement with the MATLAB reference (matlab/boost_sim.m)';
    L{end + 1} = '';
    L{end + 1} = '| Implementation | Gating metrics within tolerance | Informational metrics that differ |';
    L{end + 1} = '|---|---|---|';
    details = {};
    for k = 1:numel(cmp)
        C = readtable(fullfile(cmp(k).folder, cmp(k).name), 'TextType', 'char', 'Delimiter', ',');
        label = regexprep(cmp(k).name, '^comparison_(.*)\.csv$', '$1');
        g = logical(C.gating); p = logical(C.pass);
        L{end + 1} = sprintf('| %s | %d / %d | %d |', label, sum(g & p), sum(g), sum(~g & ~p)); %#ok<AGROW>
        for i = find(g & ~p).'
            details{end + 1} = sprintf('- %s: %s %s reference %.5g vs %.5g', label, ...
                C.scenario{i}, C.metric{i}, C.reference(i), C.value(i)); %#ok<AGROW>
        end
    end
    L{end + 1} = '';
    if ~isempty(details)
        L = [L, {'Gating metrics outside tolerance:', ''}, details, {''}];
    end
end

% ---- outputs ---------------------------------------------------------------------------
figs = dir(fullfile(artDir, '**', 'figures', '*.png'));
models = dir(fullfile(artDir, '**', 'models', '*.slx'));
diagrams = dir(fullfile(artDir, '**', 'model_diagrams', '*.png'));
L{end + 1} = sprintf(['%d model files, %d model diagrams and %d figures are on the ' ...
    '`ci-results` branch and in the run''s artifacts.'], numel(models), numel(diagrams), numel(figs));
L{end + 1} = '';

file = fullfile(artDir, 'SUMMARY.md');
fid = fopen(file, 'w');
fprintf(fid, '%s\n', L{:});
fclose(fid);
fprintf('%s\n', L{:});
end

% -------------------------------------------------------------------------
function d = sub(artDir, name)
%SUB  Artifact folder (CI: simulink-diffeq) or local results folder (simulink_diffeq).
d = fullfile(artDir, name);
if ~exist(d, 'dir')
    d = fullfile(artDir, strrep(name, '-', '_'));
end
end

function T = read_checks(file)
T = [];
if ~exist(file, 'file')
    return
end
T = readtable(file, 'TextType', 'char', 'Delimiter', ',');
for c = {'id', 'item', 'expect', 'note'}
    if ~iscell(T.(c{1}))
        T.(c{1}) = repmat({''}, height(T), 1);
    end
end
T.pass = logical(T.pass);
T.gating = logical(T.gating);
end

function L = check_table(T0, names, Ts)
%CHECK_TABLE  One row per check of T0, one value column per implementation.
L = {};
hdr = ['| Check | Paper | ' strjoin(names, ' | ') ' | Expected | Result |'];
L{end + 1} = hdr;
L{end + 1} = ['|' repmat('---|', 1, numel(names) + 4)];
for i = 1:height(T0)
    id = T0.id{i};
    vals = cell(1, numel(Ts));
    okAll = true;
    for k = 1:numel(Ts)
        j = find(strcmp(Ts{k}.id, id), 1);
        if isempty(j)
            vals{k} = '-';
            okAll = false;
            continue
        end
        vals{k} = num(Ts{k}.value(j));
        if ~Ts{k}.pass(j)
            okAll = false;
            if Ts{k}.gating(j)
                vals{k} = [vals{k} ' (!)'];
            end
        end
    end
    expect = T0.expect{i};
    if strcmp(expect, 'info')
        if okAll
            res = 'close';
        else
            res = 'differs (info)';
        end
    elseif okAll
        res = 'as expected';
    else
        res = '**NOT AS EXPECTED**';
    end
    L{end + 1} = sprintf('| %s | %s | %s | %s | %s |', T0.item{i}, num(T0.paper(i)), ...
        strjoin(vals, ' | '), expect_word(expect, T0.tol(i)), res); %#ok<AGROW>
end
L{end + 1} = '';
end

function s = expect_word(e, tol)
switch e
    case 'match'
        s = sprintf('match (±%g)', tol);
    case 'differs'
        s = sprintf('differs (>%g)', tol);
    case 'positive'
        s = 'unstable (> 0)';
    case 'negative'
        s = 'stable (< 0)';
    case 'at_least'
        s = 'at least the paper value';
    otherwise
        s = e;
end
end

function s = job_word(r)
switch r
    case 'success'
        s = 'passed';
    case 'failure'
        s = '**FAILED**';
    otherwise
        s = r;
end
end

function s = num(x)
if isnumeric(x) && isscalar(x) && ~isnan(x)
    s = sprintf('%.5g', x);
else
    s = '-';
end
end

function s = cstr(z)
if iscell(z)
    s = z{1};
elseif isnumeric(z)
    s = sprintf('%.6g%+.6gj', real(z), imag(z));
else
    s = char(z);
end
end
