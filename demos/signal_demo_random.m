%% signal_demo_random.m
% ------------------------------------------------------------
% Pure visualization demo (NO peak detection, NO HR inference)
%
% Fixed sampling rate:
%   fs = 125 Hz
%
% Channel order (confirmed):
%   Row 1: PPG
%   Row 2: ABP
%   Row 3: ECG
%
% What this script does:
%   - Load dataset_MIMICII.mat (variable: p)
%   - Pick one sample
%   - Randomly extract 10 s and 30 s segments
%   - Plot PPG / ABP / ECG only
% ------------------------------------------------------------

clear; clc; close all;

%% ========== 0) Configuration ==========
%% -------- 1) Load dataset --------
dataFile = fullfile('..', 'data', 'dataset_MIMICII.mat');
fs = 125;                   % FINAL, fixed
durations = [10, 30];        % seconds to visualize
use_random_sample = false;   % true: random sample, false: fixed
idx = 1;                     % used if not random

rng(0); % reproducibility

%% ========== 1) Load dataset ==========
S = load(dataFile);
assert(isfield(S,'p'), 'Variable "p" not found in %s.', dataFile);
p = S.p;

fprintf('[INFO] Loaded %s with %d samples.\n', dataFile, numel(p));

%% ========== 2) Pick a sample ==========
if use_random_sample
    idx = randi(numel(p));
end

X = p{idx};
assert(isnumeric(X) && ndims(X)==2 && size(X,1)==3, ...
    'p{%d} must be a 3xN numeric matrix.', idx);

% ✅ Confirmed channel mapping
PPG = X(1,:);
ABP = X(2,:);
ECG = X(3,:);

N = numel(ECG);
T = N / fs;

fprintf('[INFO] Sample #%d length: %d points (%.2f s @ %d Hz)\n', ...
    idx, N, T, fs);

%% ========== 3) Random segments & plot ==========
for k = 1:numel(durations)

    dur = durations(k);
    L = dur * fs;

    if L >= N
        error('Segment duration %d s exceeds signal length.', dur);
    end

    start_idx = randi([1, N - L + 1]);
    id = start_idx : (start_idx + L - 1);
    t = (0:L-1) / fs;

    figure('Name', sprintf('Pure 3-Channel Demo | %ds (fs=%dHz) | sample #%d', ...
        dur, fs, idx), 'Color','w');

    tiledlayout(3,1,'Padding','compact','TileSpacing','compact');

    nexttile;
    plot(t, PPG(id), 'LineWidth', 1.0);
    grid on;
    ylabel('PPG');
    title(sprintf('PPG – %d s segment', dur));

    nexttile;
    plot(t, ABP(id), 'LineWidth', 1.0);
    grid on;
    ylabel('ABP');
    title(sprintf('ABP – %d s segment', dur));

    nexttile;
    plot(t, ECG(id), 'LineWidth', 1.0);
    grid on;
    ylabel('ECG');
    xlabel('Time (s)');
    title(sprintf('ECG – %d s segment', dur));
end

fprintf('[INFO] Pure demo finished (fs = %d Hz, no HR inference).\n', fs);
