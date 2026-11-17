function [C, seg, info] = word_features(y, Fs)
% WORD_FEATURES  Cut the spoken word out of a recording and compute its MFCCs.
%
%   [C, seg, info] = word_features(y, Fs)
%
%   C     MFCC matrix, 12 coefficients x frames (one column every 10 ms)
%   seg   the trimmed audio (only the word, silence removed)
%   info  .startSample / .endSample of seg inside y
%
%   Steps:
%     1. Endpoint detection: keep only frames louder than the background.
%     2. MFCC per 25 ms frame (10 ms hop):
%        Hamming -> FFT -> power -> mel filterbank -> log -> DCT
%     3. Drop c0 (overall loudness) and subtract the mean of each
%        coefficient (removes differences between microphones).

y   = y(:) - mean(y);
N   = round(0.025*Fs);                 % 25 ms frames (400 samples at 16 kHz)
hop = round(0.010*Fs);                 % 10 ms hop

%% 1. Endpoint detection (where does the word start and end?)
nF = floor((length(y) - N)/hop) + 1;
E  = zeros(nF, 1);
for k = 1:nF
    s = y((k-1)*hop + (1:N));
    E(k) = sqrt(mean(s.^2));           % RMS energy per frame
end
thr = max(0.1*max(E), 2*median(E));    % above 10% of the peak AND above the noise floor
active = find(E > thr);
if isempty(active)                     % nothing stands out: use everything
    active = [1; nF];
end
first = max(1,  active(1)   - 3);      % keep 3 frames (30 ms) of margin
last  = min(nF, active(end) + 3);
info.startSample = (first-1)*hop + 1;
info.endSample   = (last-1)*hop + N;
seg = y(info.startSample:info.endSample);

%% 2. MFCCs of the trimmed word
nFFT  = 2^nextpow2(N);                 % 512
nFilt = 26;                            % number of mel filters
nCoef = 12;                            % coefficients we keep
w = hamming(N);
H = mel_filterbank(nFilt, nFFT, Fs, 100, Fs/2);
D = dct_matrix(nFilt);

nF = floor((length(seg) - N)/hop) + 1;
C  = zeros(nCoef, nF);
for k = 1:nF
    s = seg((k-1)*hop + (1:N)) .* w;
    P = abs(fft(s, nFFT)).^2;          % power spectrum
    P = P(1:nFFT/2 + 1);               % first half
    melE = H * P;                      % energy in each mel band
    c = D * log(melE + eps);           % log + DCT = cepstrum
    C(:, k) = c(2:nCoef+1);            % drop c0 (loudness)
end

%% 3. Cepstral mean normalisation
C = C - mean(C, 2);
end

function H = mel_filterbank(nFilt, nFFT, Fs, fLo, fHi)
% Triangular filters, equally spaced on the mel scale.
mel  = @(f) 2595*log10(1 + f/700);
imel = @(m) 700*(10.^(m/2595) - 1);
edges = imel(linspace(mel(fLo), mel(fHi), nFilt + 2));   % in Hz
f = (0:nFFT/2) * Fs/nFFT;                                 % FFT bin frequencies
H = zeros(nFilt, nFFT/2 + 1);
for i = 1:nFilt
    lo = edges(i); ce = edges(i+1); hi = edges(i+2);
    up   = (f - lo) / (ce - lo);
    down = (hi - f) / (hi - ce);
    H(i, :) = max(0, min(up, down));   % triangle: rises to 1 at ce, falls to 0
end
end

function D = dct_matrix(n)
% DCT-II matrix, so that c = D * x is the discrete cosine transform of x.
k = (0:n-1)';
j = 0:n-1;
D = sqrt(2/n) * cos(pi/n * k .* (j + 0.5));
D(1, :) = D(1, :) / sqrt(2);
end
