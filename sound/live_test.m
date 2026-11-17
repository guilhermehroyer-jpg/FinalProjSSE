%% LIVE_TEST  Record 5 s, look at the spectrum, and run the cry/scream rules.
% Our earlier FFT code, adapted (stage 1 only).

clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths

C   = config();
Fs  = C.sound.Fs;                     % 16 kHz: cries and screams have energy up to ~4 kHz
rec = audiorecorder(Fs, 16, 1, C.sound.micID);
disp('Recording 5 s... cry, scream "help!", or just talk');
recordblocking(rec, 5);
disp('Done.');
y = getaudiodata(rec);
y = y - mean(y);                      % remove DC offset

t = (0:length(y)-1)/Fs;
figure;
subplot(3,1,1);
plot(t, y);
xlabel('Time (s)'); ylabel('Amplitude'); title('Waveform');

%% Spectrum of the LOUDEST 32 ms frame (instead of the fixed y(10000:10500))
N   = round(0.032*Fs);                % 512 samples = 32 ms
hop = round(N/2);
nFrames  = floor((length(y) - N)/hop) + 1;
frameRms = zeros(nFrames, 1);
for k = 1:nFrames
    seg = y((k-1)*hop + (1:N));
    frameRms(k) = sqrt(mean(seg.^2));
end
[~, kMax] = max(frameRms);
y1 = y((kMax-1)*hop + (1:N));         % exactly N samples

f = fft(hamming(N) .* y1);            % compute FFT
x = (0:floor(N/2)) * Fs/N;            % frequency axis for the first half
m = abs(f(1:numel(x)));               % magnitude of the first half

band = x >= 250 & x <= 4000;          % ignore DC, motor hum and very high noise
mb = m;
mb(~band) = 0;
[pks, locs] = findpeaks(mb);          % find the highest peak inside the band
if isempty(pks)
    [maxPeak, i] = max(mb);
    peakFreq = x(i);
else
    [maxPeak, idx] = max(pks);
    peakFreq = x(locs(idx));
end
fprintf('Loudest frame: highest peak at %.0f Hz (height %.2f)\n', peakFreq, maxPeak);

subplot(3,1,2);
plot(x/1000, m); hold on;
plot(peakFreq/1000, maxPeak, 'rv', 'MarkerFaceColor', 'r');
xlim([0 4]);
xlabel('Frequency (kHz)'); ylabel('|FFT|');
title(sprintf('Spectrum of the loudest frame (peak %.0f Hz)', peakFreq));

subplot(3,1,3);
spectrogram(y, hamming(N), N-hop, N, Fs, 'yaxis');
ylim([0 4]);
title('Spectrogram (cries/screams show stacked horizontal harmonics)');

%% Run the rules on every 1 s window
L = Fs;                               % 1 s = Fs samples
fprintf('\n window   rms    peak(Hz)  flatness  voiced  band  -> decision\n');
for s = 1:L:length(y)-L+1
    F = extract_features(y(s:s+L-1), Fs);
    [isCry, failed] = classify_window(F);
    if isCry
        decision = 'CRY/SCREAM';
    else
        decision = ['other (failed: ' failed ')'];
    end
    fprintf(' %.0f-%.0f s   %.3f  %6.0f    %.3f     %.2f    %.2f  -> %s\n', ...
        (s-1)/Fs, (s-1+L)/Fs, F.rms, F.peakFreq, F.flatness, F.voicedFrac, ...
        F.bandRatio, decision);
end
