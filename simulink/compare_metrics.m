function [T, ok] = compare_metrics(refFile, testFile, label, outdir, only)
%COMPARE_METRICS  Compare the scenario metrics of an implementation with the reference.
%   [T, ok] = compare_metrics(refFile, testFile, label, outdir)
%   [T, ok] = compare_metrics(..., only)   compare only the scenarios in the
%                                          cell array ONLY (subset runs)
%   Both files: scenario,metric,value (SCENARIO_METRICS). The reference is the
%   plain-MATLAB simulator matlab/boost_sim.m (EXPORT_REFERENCE). Writes
%   <outdir>/comparison_<label>.csv and .md. ok is true when every gating
%   metric agrees within its tolerance (METRIC_TOLERANCE).
if nargin < 5
    only = {};
end
ref = read_metrics(refFile);
tst = read_metrics(testFile);
keys = ref.keys;
if ~isempty(only)
    keep = cellfun(@(k) any(strcmp(extractBefore(k, '|'), only)), keys);
    keys = keys(keep);
end
n = numel(keys);
scen = cell(n, 1); met = cell(n, 1);
a = nan(n, 1); b = nan(n, 1); tolA = nan(n, 1); tolR = nan(n, 1);
gating = false(n, 1); pass = false(n, 1); found = false(n, 1);
for i = 1:n
    parts = split(keys{i}, '|');
    scen{i} = parts{1}; met{i} = parts{2};
    a(i) = ref(keys{i});
    if isKey(tst, keys{i})
        found(i) = true;
        b(i) = tst(keys{i});
    end
    [tolA(i), tolR(i), gating(i)] = metric_tolerance(scen{i}, met{i});
    if isnan(a(i)) && isnan(b(i)) && found(i)
        pass(i) = true;
    else
        pass(i) = found(i) && abs(b(i) - a(i)) <= max(tolA(i), tolR(i) * abs(a(i)));
    end
end
% the divergence at gamma = 1 is checked as a property, not a value
idx = strcmp(scen, 'lr_g1') & strcmp(met, 'vmax_tail');
j = strcmp(scen, 'lr_g1') & strcmp(met, 'vmin_tail');
if any(idx) && any(j)
    spanRef = a(idx) - a(j);
    spanTst = b(idx) - b(j);
    divergeOk = spanRef > 20 && spanTst > 20;
    pass(idx) = divergeOk;
    pass(j) = divergeOk;
    gating(idx) = true;
    gating(j) = true;
end
diffv = b - a;
T = table(scen, met, a, b, diffv, tolA, tolR, gating, pass, ...
    'VariableNames', {'scenario', 'metric', 'reference', 'value', 'difference', ...
    'abs_tol', 'rel_tol', 'gating', 'pass'});
ok = all(pass(gating));
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
writetable(T, fullfile(outdir, sprintf('comparison_%s.csv', label)));
write_markdown(T, label, ok, fullfile(outdir, sprintf('comparison_%s.md', label)));
fprintf('compare_metrics(%s): %d/%d gating metrics within tolerance, %d informational differ\n', ...
    label, sum(pass & gating), sum(gating), sum(~pass & ~gating));
bad = find(gating & ~pass);
for i = bad(:).'
    fprintf('   FAIL %-14s %-14s reference %.6g  %s %.6g\n', scen{i}, met{i}, a(i), label, b(i));
end
end

% -------------------------------------------------------------------------
function M = read_metrics(file)
fid = fopen(file, 'r');
assert(fid > 0, 'compare_metrics:file', 'Cannot open %s', file);
c = textscan(fid, '%s %s %s', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fid);
M = containers.Map();
for i = 1:numel(c{1})
    M([c{1}{i} '|' c{2}{i}]) = str2double(c{3}{i});
end
end

function write_markdown(T, label, ok, file)
fid = fopen(file, 'w');
status = 'PASS';
if ~ok
    status = 'FAIL';
end
fprintf(fid, '## MATLAB reference (matlab/boost_sim.m) vs %s: %s\n\n', label, status);
fprintf(fid, ['%d of %d gating metrics within tolerance; %d informational metrics ' ...
    'listed for reference.\n\n'], sum(T.pass & T.gating), sum(T.gating), sum(~T.gating));
fprintf(fid, '| Scenario | Metric | Reference | %s | Difference | Tolerance | Gating | Result |\n', ...
    label);
fprintf(fid, '|---|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    tol = sprintf('max(%g, %g%%)', T.abs_tol(i), 100 * T.rel_tol(i));
    res = 'ok';
    if ~T.pass(i)
        res = 'differs';
        if T.gating(i)
            res = '**FAIL**';
        end
    end
    g = 'yes';
    if ~T.gating(i)
        g = 'no';
    end
    fprintf(fid, '| %s | %s | %.5g | %.5g | %.3g | %s | %s | %s |\n', T.scenario{i}, ...
        T.metric{i}, T.reference(i), T.value(i), T.difference(i), tol, g, res);
end
fclose(fid);
end
