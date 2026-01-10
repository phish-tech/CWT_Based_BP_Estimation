%% signal_demo.m
% ------------------------------------------------------------
% Minimal demo:
% Load one sample from MIMIC-II derived dataset
% and plot three-channel waveforms (PPG / ABP / ECG).
% ------------------------------------------------------------

clear; clc; close all;

%% -------- 0) Fix working directory --------
script_dir = fileparts(mfilename('fullpath'));
cd(script_dir);

%% -------- 1) Load dataset --------
dataFile = fullfile('..', 'data', 'dataset_MIMICII.mat');
S = load(dataFile);

% dataset cell
p = S.p;

fprintf('[INFO] Loaded dataset with %d samples.\n', numel(p));

%% -------- 2) Pick one sample --------
idx = 1;              % change if needed
X = p{idx};

assert(size(X,1) == 3, 'Expected 3-channel data.');


PPG = X(1, :);
ABP = X(2, :);
ECG = X(3, :);

fprintf('[INFO] Sample #%d length = %d points.\n', idx, size(X,2));

%% -------- 3) Set sampling rate (fixed) --------
fs = 125;   
t = (0:size(X,2)-1) / fs;

%% -------- 4) Plot full waveforms --------
figure('Color','w','Name','Three-channel waveform demo');
tiledlayout(3,1,'Padding','compact','TileSpacing','compact');

nexttile;
plot(t, PPG, 'LineWidth', 1);
grid on;
ylabel('PPG');
title('PPG');

nexttile;
plot(t, ABP, 'LineWidth', 1);
grid on;
ylabel('ABP');
title('ABP');

nexttile;
plot(t, ECG, 'LineWidth', 1);
grid on;
ylabel('ECG');
xlabel('Time (s)');
title('ECG');
