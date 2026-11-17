%% LIVE_HELP  Full pipeline on a live recording:
%   capture -> FFT + plots -> MFCC -> compare with templates (DTW)
%   -> threshold -> rule-based scream/cry check -> final decision
%
% Needs models/help_model.mat (run help_train_evaluate.m first).

clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths
cfg = config();
load(cfg.paths.helpModel, 'templates', 'thr', 'Fs');

%% 1. Capture
rec = audiorecorder(Fs, 16, 1, cfg.sound.micID);
disp('Recording 2 s... say or scream "help" (or something else)');
recordblocking(rec, 2);
disp('Done.');
y = getaudiodata(rec);
y = y - mean(y);
t = (0:length(y)-1) / Fs;

%% 2. MFCCs of the trimmed word
[C, seg, info] = word_features(y, Fs);

%% 3. Compare with every template (DTW) and apply the threshold
d = cellfun(@(T) dtw_distance(C, T), templates);
[dMin, iBest] = min(d);
isHelp = dMin <= thr;

%% 4. FFT of the loudest 32 ms frame (same as our earlier code)
N = round(0.032*Fs);  hop = round(N/2);
nF = floor((length(y) - N)/hop) + 1;
frameRms = zeros(nF, 1);
for k = 1:nF
    frameRms(k) = sqrt(mean(y((k-1)*hop + (1:N)).^2));
end
[~, kMax] = max(frameRms);
y1 = y((kMax-1)*hop + (1:N));
x  = (0:floor(N/2)) * Fs/N;
m  = abs(fft(hamming(N) .* y1));
m  = m(1:numel(x));
mb = m;  mb(x < 250 | x > 4000) = 0;    % search the peak between 250 and 4000 Hz
[maxPeak, iPk] = max(mb);
peakFreq = x(iPk);

%% 5. Rule-based scream/cry check on the 1 s around the loudest frame
L  = Fs;
c  = (kMax-1)*hop + round(N/2);                    % centre of the loudest frame
s0 = min(max(1, c - round(L/2)), length(y) - L + 1);
F  = extract_features(y(s0:s0+L-1), Fs);
[isCry, failed] = classify_window(F);

%% 6. Plots
figure('Position', [100 100 1100 750]);

subplot(3, 2, 1);
plot(t, y); hold on;
idx = info.startSample:info.endSample;
plot(t(idx), y(idx), 'r');
xlabel('Time (s)'); title('Waveform (red = detected word)');

subplot(3, 2, 2);
plot(x/1000, m); hold on;
plot(peakFreq/1000, maxPeak, 'rv', 'MarkerFaceColor', 'r');
xlim([0 4]); xlabel('Frequency (kHz)'); ylabel('|FFT|');
title(sprintf('Spectrum of loudest frame (peak %.0f Hz)', peakFreq));

subplot(3, 2, 3);
spectrogram(y, hamming(N), N-hop, N, Fs, 'yaxis');
ylim([0 4]); title('Spectrogram');

subplot(3, 2, 4);
bar(d); hold on;
yline(thr, 'r--', 'threshold', 'LineWidth', 1.5);
xlabel('Template'); ylabel('DTW distance');
title(sprintf('Distance to each template (best: %.2f)', dMin));

subplot(3, 2, 5);
imagesc(C); axis xy; colorbar;
xlabel('Frame (10 ms)'); ylabel('MFCC'); title('MFCCs of this recording');

subplot(3, 2, 6);
imagesc(templates{iBest}); axis xy; colorbar;
xlabel('Frame (10 ms)'); ylabel('MFCC'); title(sprintf('Closest template (#%d)', iBest));

%% 7. Decision
fprintf('\nStage 1 (rules)    : %s', ternary(isCry, 'CRY/SCREAM', 'no cry/scream'));
if ~isCry, fprintf('  (failed: %s)', failed); end
fprintf('\nStage 2 (template) : best distance %.3f vs threshold %.3f -> %s\n', ...
    dMin, thr, ternary(isHelp, '"HELP"', 'not "help"'));
fprintf('==> %s\n', ternary(isCry || isHelp, 'VICTIM DETECTED', 'nothing detected'));

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
