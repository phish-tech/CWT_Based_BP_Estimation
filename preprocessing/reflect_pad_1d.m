function y = reflect_pad_1d(x, pad_len)
%REFLECT_PAD_1D Reflect padding on both ends (exclude boundary repetition).

    x = x(:);
    if pad_len <= 0
        y = x;
        return;
    end

    N = numel(x);
    if pad_len >= N
        error('pad_len must be smaller than signal length.');
    end

    left  = flipud(x(2:pad_len+1));
    right = flipud(x(end-pad_len:end-1));
    y = [left; x; right];
end
