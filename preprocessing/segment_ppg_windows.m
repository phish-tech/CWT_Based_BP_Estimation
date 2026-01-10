function [segs, info] = segment_ppg_windows(ppg, fs, win_sec, stride_sec)

ppg = ppg(:).';
L = round(win_sec * fs);
H = round(stride_sec * fs);

N = numel(ppg);
if N < L
    error('PPG too short.');
end

num_win = floor((N - L) / H) + 1;
segs = zeros(num_win, L);

for i = 1:num_win
    s = (i-1)*H + 1;
    segs(i,:) = ppg(s:s+L-1);
end

info = struct();
info.win_len = L;
info.hop_len = H;
info.num_win = num_win;
end
