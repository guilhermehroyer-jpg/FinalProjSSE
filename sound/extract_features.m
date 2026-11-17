function F = extract_features(y, Fs)
% EXTRACT_FEATURES  Features of one audio window (about 1 s) for the cry/scream rules.
%
%   F = extract_features(y, Fs)
%
%   The window is cut into 32 ms frames (50% overlap). Each frame gets a
%   Hamming window and an FFT, exactly like our earlier single-frame code.
%   The frame results are then summarised into one value per feature:
%
%     F.rms        loudness of the whole window
%     F.peakFreq   median dominant frequency (Hz) of the loud frames,
%                  searched only between 250 and 4000 Hz
%     F.flatness   median spectral flatness of the loud frames
%                  (close to 0 = tonal/harmonic sound, about 0.5 = noise)
%     F.voicedFrac fraction of frames that are loud, tonal AND have their
%                  peak in the cry range -> high for sustained cries/screams
%     F.bandRatio  share of the window's energy between 250 and 4000 Hz
%                  (low for motor hum, which sits below 250 Hz)

y = y(:) - mean(y);                     % column vector, remove DC offset

N   = round(0.032*Fs);                  % frame length: 32 ms (512 samples at 16 kHz)
hop = round(N/2);                       % 50% overlap between frames
w   = hamming(N);
nFrames = floor((length(y) - N)/hop) + 1;

f    = (0:floor(N/2))' * Fs/N;          % frequency axis for the first half of the FFT
band = f >= 250 & f <= 4000;            % where we look for the peak

cryRange  = [300 2000];                 % peak range that counts as cry-like (per frame)
tonalFlat = 0.3;                        % frames below this flatness count as tonal

frameRms = zeros(nFrames, 1);
peakF    = zeros(nFrames, 1);
flat     = zeros(nFrames, 1);
Etotal = 0;
Eband  = 0;

for k = 1:nFrames
    seg = y((k-1)*hop + (1:N));
    frameRms(k) = sqrt(mean(seg.^2));

    m = abs(fft(w .* seg));             % magnitude spectrum
    m = m(1:numel(f));                  % keep the first half
    P = m.^2;                           % power

    Etotal = Etotal + sum(P);
    Eband  = Eband  + sum(P(band));

    mb = m;
    mb(~band) = 0;                      % ignore DC, hum and very high noise
    [~, i] = max(mb);                   % highest peak inside the band
    peakF(k) = f(i);

    Pb = P(band) + eps;                 % eps avoids log(0)
    flat(k) = exp(mean(log(Pb))) / mean(Pb);   % geometric mean / arithmetic mean
end

loud = frameRms > 0.25*max(frameRms);   % frames that actually contain the sound
good = loud & peakF >= cryRange(1) & peakF <= cryRange(2) & flat < tonalFlat;

F.rms        = sqrt(mean(y.^2));
F.peakFreq   = median(peakF(loud));
F.flatness   = median(flat(loud));
F.voicedFrac = mean(good);
F.bandRatio  = Eband / Etotal;
end
