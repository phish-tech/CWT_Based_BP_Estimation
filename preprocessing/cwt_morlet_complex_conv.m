function W = cwt_morlet_complex_conv(x, fs, n_scales, f0_hz, freq_range_hz)
%CWT_MORLET_COMPLEX_CONV Complex Morlet CWT via (FFT) convolution.
%
% Paper alignment:
%   - Morlet wavelet
%   - Center frequency fixed (f0_hz = 1 Hz in the paper)
%   - Convolution method
%
% Inputs:
%   x            : (Nx1) double, padded signal allowed
%   fs           : sampling rate
%   n_scales     : number of scales (paper uses 256)
%   f0_hz        : Morlet center frequency in Hz (paper: 1 Hz)
%   freq_range_hz: [fmin fmax] analysis band, default [0.1 20]
%
% Output:
%   W : (n_scales x N) complex

    arguments
        x (:,1) double
        fs (1,1) double {mustBePositive}
        n_scales (1,1) double {mustBePositive} = 256
        f0_hz (1,1) double {mustBePositive} = 1
        freq_range_hz (1,2) double {mustBePositive} = [0.1 20]
    end

    x = x(:);
    N = numel(x);
    dt = 1/fs;

    % --- Define pseudo-frequencies (log spaced) ---
    fmin = freq_range_hz(1);
    fmax = min(freq_range_hz(2), 0.5*fs - 1e-6);
    freqs = logspace(log10(fmax), log10(fmin), n_scales);

    % Relationship for Morlet pseudo-frequency:
    %   f ≈ f0 / a  ->  a ≈ f0 / f
    scales = f0_hz ./ freqs;

    % --- FFT of signal ---
    X = fft(x);

    W = complex(zeros(n_scales, N));

    % --- Build each scaled wavelet and convolve ---
    % Mother wavelet (complex Morlet):
    %   psi(t) = pi^(-1/4) * exp(j*2*pi*f0*t) * exp(-t^2/2)
    % Scaled:
    %   psi_a(t) = 1/sqrt(a) * psi(t/a)
    %
    % For convolution CWT coefficient:
    %   W(a, b) = ∫ x(t) * (1/sqrt(a)) * conj(psi((t-b)/a)) dt
    %
    for i = 1:n_scales
        a = scales(i);

        % choose finite support: +/- 4 sigma (sigma=1 -> scaled sigma=a)
        half = ceil(4*a/dt);
        t = (-half:half) * dt;

        psi = (pi^(-1/4)) .* exp(1j*2*pi*f0_hz*(t./a)) .* exp(-(t./a).^2/2) ./ sqrt(a);

        % convolution with conj(psi) flipped
        h = conj(flip(psi(:)));

        % FFT-based convolution, keep 'same'
        H = fft(h, N);
        y = ifft(X .* H);

        W(i,:) = y;
    end
end
