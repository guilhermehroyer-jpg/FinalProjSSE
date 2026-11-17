function level = band_level(y, Fs, band)
% BAND_LEVEL  Loudness (RMS) of a recording, counting only 300-3000 Hz.
%
%   level = band_level(y, Fs)
%   level = band_level(y, Fs, [fLo fHi])
%
%   Used to compare directions when following a sound: motor hum and very
%   low rumble fall outside the band, cries and screams fall inside it.
%   By Parseval's theorem, the RMS of the band-limited signal equals
%   sqrt(2 * sum |Y(k)|^2) / N over the positive frequencies in the band.

if nargin < 3
    band = [300 3000];
end
y = y(:) - mean(y);
N = numel(y);
Y = fft(y);
f = (0:N-1)' * Fs/N;
inBand = f >= band(1) & f <= band(2);          % positive frequencies only
level  = sqrt(2 * sum(abs(Y(inBand)).^2)) / N;
end
