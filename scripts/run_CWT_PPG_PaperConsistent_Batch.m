%% =========================================================================
%  run_CWT_PPG_PaperConsistent_Batch.m
%
%  Batch generation of PPG peaks + paper-consistent CWT tensors
%  for cuffless BP estimation (MIMIC-II derived dataset).
%
% =========================================================================
clear; clc; close all;

%% -------------------- Resolve project root -------------------------------
script_dir  = fileparts(mfilename('fullpath'));
project_root = fileparts(script_dir);

%% -------------------- 0. Load dataset -----------------------------------
data_root = fullfile(project_root, 'data');
data_file = fullfile(data_root, 'dataset_MIMICII.mat');

if ~exist(data_file, 'file')
    error('Dataset not found: %s', data_file);
end

S = load(data_file);
p = S.p;
num_samples = numel(p);

fprintf('[INFO] Loaded dataset with %d samples.\n', num_samples);

%% -------------------- 1. Global parameters (paper-consistent) ------------
fs          = 125;          % sampling rate
win_sec     = 5;            % CWT window length
stride_sec  = 1;            % overlap
pad_sec     = 1;            % reflect padding
f0_hz       = 1;            % Morlet center frequency
freq_band   = [0.5 8];      % physiological PPG band
n_scales    = 256;
out_hw      = [256 256];

%% -------------------- 2. Output folder ----------------------------------
out_root = fullfile(project_root, 'outputs', 'CWT_Dataset');
if ~exist(out_root, 'dir')
    mkdir(out_root);
end

fprintf('[INFO] Output directory: %s\n', out_root);

%% -------------------- 3. Precompute CWT scales ---------------------------
freqs  = logspace(log10(freq_band(2)), ...
                  log10(freq_band(1)), n_scales);
scales = f0_hz ./ freqs;

%% -------------------- 4. Loop over samples -------------------------------
for idx = 1:num_samples

    fprintf('[%04d/%04d] Processing sample...\n', idx, num_samples);

    %% ---- 4.1 Load PPG channel ----
    X = p{idx};
    ppg = X(1, :);                 % PPG channel
    ppg = ppg(:).';

    %% ---- 4.2 Peak detection (PPG beat-level) ----
    [pks, locs] = findpeaks(ppg, ...
        'MinPeakDistance', round(0.4 * fs), ...
        'MinPeakProminence', 0.05 * std(ppg));

    ppg_peaks.peaks = pks;
    ppg_peaks.locs  = locs;
    ppg_peaks.fs    = fs;

    %% ---- 4.3 Sliding window segmentation ----
    Lw = round(win_sec * fs);
    Hs = round(stride_sec * fs);
    Lp = round(pad_sec * fs);

    N = numel(ppg);
    num_win = floor((N - Lw) / Hs) + 1;

    if num_win <= 0
        warning('Sample %d too short. Skipped.', idx);
        continue;
    end

    %% ---- 4.4 Allocate CWT tensor ----
    X_cwt = zeros(out_hw(1), out_hw(2), 2, num_win, 'single');

    %% ---- 4.5 Window-wise CWT ----
    for w = 1:num_win

        s = (w-1)*Hs + 1;
        x = ppg(s : s + Lw - 1);

        % reflect padding
        x_pad = [flip(x(1:Lp)), x, flip(x(end-Lp+1:end))];

        % complex Morlet CWT
        W = zeros(n_scales, numel(x_pad));
        t = (-3*fs : 3*fs) / fs;

        for k = 1:n_scales
            sc = scales(k);
            psi = (pi^(-0.25)) .* ...
                  exp(1j*2*pi*f0_hz*t/sc) .* ...
                  exp(-(t.^2)/(2*sc^2));
            psi = psi / sqrt(sc);
            W(k,:) = conv(x_pad, conj(fliplr(psi)), 'same');
        end

        % remove padding
        W = W(:, Lp+1 : Lp+Lw);

        % resize + normalize (paper-consistent)
        R = imresize(real(W), out_hw, 'bilinear');
        I = imresize(imag(W), out_hw, 'bilinear');

        R = R / max(abs(R(:)) + eps);
        I = I / max(abs(I(:)) + eps);

        X_cwt(:,:,1,w) = single(R);
        X_cwt(:,:,2,w) = single(I);
    end

    %% ---- 4.6 Save results ----
    out_dir = fullfile(out_root, sprintf('sample_%04d', idx));
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    save(fullfile(out_dir, 'X_cwt.mat'), 'X_cwt', '-v7.3');
    save(fullfile(out_dir, 'ppg_peaks.mat'), 'ppg_peaks');

    meta = struct();
    meta.fs          = fs;
    meta.win_sec     = win_sec;
    meta.stride_sec  = stride_sec;
    meta.freq_band   = freq_band;
    meta.num_windows = num_win;

    save(fullfile(out_dir, 'meta.mat'), 'meta');

end

fprintf('[DONE] All samples processed. CWT dataset ready.\n');
