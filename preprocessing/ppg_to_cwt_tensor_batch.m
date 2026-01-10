function [X_tensor, meta] = ppg_to_cwt_tensor_batch(ppg, fs, win_sec, stride_sec, pad_sec, n_scales, f0_hz, out_hw)
%PPG_TO_CWT_TENSOR_BATCH
% Paper-aligned pipeline:
%   PPG -> segment (win_sec) -> reflect pad (pad_sec) -> complex Morlet CWT (f0=1Hz)
%       -> split real/imag -> resize -> HxW x2 tensor
%
% Inputs:
%   ppg        : (1xN) or (Nx1) double
%   fs         : sampling rate (Hz)
%   win_sec    : window length in seconds (paper: 5)
%   stride_sec : hop size in seconds (paper can be non-overlap; you may use 1s)
%   pad_sec    : reflect padding length in seconds (paper: reflect padding; choose e.g., 1s)
%   n_scales   : number of scales (paper output uses 256; we set 256 scales)
%   f0_hz      : Morlet center frequency in Hz (paper: 1 Hz)
%   out_hw     : output size [H W] (paper: [256 256])
%
% Outputs:
%   X_tensor : (H x W x 2 x num_windows) single
%   meta     : struct with segmentation & cwt settings

    arguments
        ppg (:,1) double
        fs (1,1) double {mustBePositive}
        win_sec (1,1) double {mustBePositive} = 5
        stride_sec (1,1) double {mustBePositive} = 1
        pad_sec (1,1) double {mustBeNonnegative} = 1
        n_scales (1,1) double {mustBePositive} = 256
        f0_hz (1,1) double {mustBePositive} = 1
        out_hw (1,2) double {mustBePositive} = [256 256]
    end

    % ---- 1) segment ----
    [segs, seg_info] = segment_ppg_windows(ppg, fs, win_sec, stride_sec);

    % ---- 2) per-window CWT -> tensor ----
    num_win = size(segs,1);
    H = out_hw(1); W = out_hw(2);
    X_tensor = zeros(H, W, 2, num_win, 'single');

    pad_len = round(pad_sec * fs);

    for i = 1:num_win
        x = segs(i,:).';
        x_pad = reflect_pad_1d(x, pad_len);

        % ---- 3) convolution-based complex Morlet CWT ----
        Wc = cwt_morlet_complex_conv(x_pad, fs, n_scales, f0_hz);

        % Optional: if padding was added, you may crop back to the original window region
        % to reduce border artifacts in the time axis.
        % Here we crop the central part corresponding to the original window:
        %   padded length = L + 2*pad_len; crop indices (pad_len+1 : pad_len+L)
        L = numel(x);
        Wc = Wc(:, pad_len+1 : pad_len+L);

        % ---- 4) split real/imag, resize -> 256x256x2 ----
        tensor = cwt_to_tensor_real_imag(Wc, out_hw);

        X_tensor(:,:,:,i) = single(tensor);
    end

    meta = struct();
    meta.fs = fs;
    meta.win_sec = win_sec;
    meta.stride_sec = stride_sec;
    meta.pad_sec = pad_sec;
    meta.n_scales = n_scales;
    meta.f0_hz = f0_hz;
    meta.out_hw = out_hw;
    meta.seg_info = seg_info;
end
