%% =========================================================================
%  run_CWT_PPG_PaperConsistent.m
%
%  One-click runnable script to generate paper-consistent CWT images
%  for PPG-based BP estimation (Figure(b), right panel in the paper).
%
% =========================================================================
clear; clc; close all;

%% -------------------- 0. Load data ---------------------------------------
data_root = fullfile('..', 'data');   % scripts/ → data/
data_file = fullfile(data_root, 'dataset_MIMICII.mat');

S = load(data_file);
p = S.p;
num_samples = numel(p);

idx = 1;                    % choose sample index
X = p{idx};
ppg = X(1, :);              % PPG channel (paper-consistent)

fprintf('[INFO] Sample #%d loaded, length = %d points\n', idx, numel(ppg));

%% -------------------- 1. Paper-fixed parameters --------------------------
fs          = 125;          % sampling rate
win_sec     = 5;            % window length (paper)
stride_sec  = 1;            % overlap stride (paper)
pad_sec     = 1;            % reflect padding
f0_hz       = 1;            % Morlet center frequency
freq_band   = [0.5 8];      % physiological PPG band
n_scales    = 256;
out_hw      = [256 256];

%% -------------------- 2. Select one window (for visualization) ----------
Lw = round(win_sec * fs);
Hs = round(stride_sec * fs);
Lp = round(pad_sec * fs);

start_sec = 10;             % arbitrary segment
s0 = round(start_sec * fs) + 1;

x = ppg(s0 : s0 + Lw - 1);

%% -------------------- 3. Reflect padding --------------------------------
x_pad = [flip(x(1:Lp)), x, flip(x(end-Lp+1:end))];

%% -------------------- 4. Build scale axis (paper-consistent) ------------
freqs  = logspace(log10(freq_band(2)), log10(freq_band(1)), n_scales);
scales = f0_hz ./ freqs;

%% -------------------- 5. Complex Morlet CWT -----------------------------
W = zeros(n_scales, numel(x_pad));

t = (-3*fs : 3*fs) / fs;

for i = 1:n_scales
    s = scales(i);
    psi = (pi^(-0.25)) * exp(1j*2*pi*f0_hz*t/s) .* exp(-(t.^2)/(2*s^2));
    psi = psi / sqrt(s);
    W(i,:) = conv(x_pad, conj(fliplr(psi)), 'same');
end

% remove padding
W = W(:, Lp+1 : Lp+Lw);

%% -------------------- 6. Paper-style processing -------------------------
% magnitude compression (implicit in paper)
A = abs(W);
A = log1p(A);
A = A / max(A(:));

% resize
A_rs = imresize(A, out_hw, 'bilinear');
R_rs = imresize(real(W), out_hw, 'bilinear');
I_rs = imresize(imag(W), out_hw, 'bilinear');

R_rs = R_rs / max(abs(R_rs(:)));
I_rs = I_rs / max(abs(I_rs(:)));

%% -------------------- 7. Visualization (paper-style) --------------------
figure('Color','w','Name','Paper-consistent CWT input');

subplot(1,2,1);
imagesc(R_rs); axis image off;
title('Real(CWT)');

subplot(1,2,2);
imagesc(I_rs); axis image off;
title('Imag(CWT)');

fprintf('[DONE] Paper-consistent CWT generated (256×256×2)\n');
