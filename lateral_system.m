%% =========================================================
%  BIO-INSPIRED DISTURBANCE SENSING SYSTEM — MATLAB ANALYSIS
%  Fish Lateral Line Simulation | Potentiometer-Based Sensor
%  Task 09 | Signal Processing, FFT & Threshold Detection
%% =========================================================

clc; clear; close all;

%% ─────────────────────────────────────────────────────────
%  SECTION 1: SIMULATE POTENTIOMETER / SENSOR DATA
%  (Replace this block with actual Arduino serial data)
%% ─────────────────────────────────────────────────────────

Fs      = 100;          % Sampling frequency (Hz)
T       = 10;           % Total duration (seconds)
t       = 0:1/Fs:T-1/Fs;
N       = length(t);

% ── Baseline: slow drift + ambient electrical noise ──────
baseline  = 512 + 20*sin(2*pi*0.1*t);          % ADC midpoint ~2.5V
noise     = 8*randn(1, N);                       % Sensor noise

% ── Disturbance Events (3 separate trials) ───────────────
%    Each event = sudden flow disturbance in water
event_times = [1.5, 4.2, 7.8];   % seconds
event_amp   = [180, 220, 195];    % ADC amplitude change
event_dur   = [0.4, 0.5, 0.35];  % seconds (duration)

disturbance = zeros(1, N);
for k = 1:length(event_times)
    t_on  = event_times(k);
    t_off = event_times(k) + event_dur(k);
    mask  = (t >= t_on) & (t <= t_off);
    % Sharp rise, exponential decay — mimics lateral line hair cell response
    local_t = t(mask) - t_on;
    disturbance(mask) = event_amp(k) * (1 - exp(-local_t / 0.05)) .* exp(-local_t / 0.15);
end

% ── Raw Signal (what Arduino would read from potentiometer) ──
raw_signal = baseline + disturbance + noise;
raw_signal = max(0, min(1023, raw_signal));   % Clamp to 10-bit ADC range

% ── Convert ADC to Voltage (5V reference) ────────────────
voltage = (raw_signal / 1023) * 5.0;

fprintf('=== Lateral Line Sensing System | Signal Analysis ===\n');
fprintf('Sampling Rate : %d Hz\n', Fs);
fprintf('Duration      : %d s  (%d samples)\n', T, N);
fprintf('Events Planted: %d disturbances\n\n', length(event_times));


%% ─────────────────────────────────────────────────────────
%  SECTION 2: PRE-PROCESSING
%% ─────────────────────────────────────────────────────────

% ── Moving Average (low-pass smoothing) ──────────────────
window_size    = 15;                            % ~150 ms window
filtered_signal = movmean(raw_signal, window_size);

% ── Baseline Correction (remove slow drift) ──────────────
poly_order   = 3;
p            = polyfit(t, filtered_signal, poly_order);
baseline_fit = polyval(p, t);
corrected    = filtered_signal - baseline_fit;

% ── Normalise to zero-mean, unit variance ────────────────
normalised = (corrected - mean(corrected)) / std(corrected);

fprintf('Pre-processing complete.\n');
fprintf('  DC Offset (mean): %.2f ADC units\n', mean(raw_signal));
fprintf('  Signal Std Dev  : %.2f ADC units\n\n', std(raw_signal));


%% ─────────────────────────────────────────────────────────
%  SECTION 3: FFT FREQUENCY ANALYSIS
%% ─────────────────────────────────────────────────────────

% ── FFT on corrected signal ───────────────────────────────
Y         = fft(corrected, N);
P2        = abs(Y / N);
P1        = P2(1 : floor(N/2) + 1);
P1(2:end-1) = 2 * P1(2:end-1);
f_axis    = Fs * (0 : floor(N/2)) / N;

% ── Dominant frequency ────────────────────────────────────
[peak_mag, peak_idx] = max(P1(2:end));   % Skip DC
dominant_freq = f_axis(peak_idx + 1);

fprintf('FFT Analysis:\n');
fprintf('  Dominant Frequency : %.2f Hz\n', dominant_freq);
fprintf('  Peak Magnitude     : %.4f\n\n', peak_mag);


%% ─────────────────────────────────────────────────────────
%  SECTION 4: THRESHOLD DETECTION (Bio-Inspired Response)
%% ─────────────────────────────────────────────────────────

% ── Adaptive threshold = mean + 2.5 * std ────────────────
mu         = mean(corrected);
sigma      = std(corrected);
threshold  = mu + 2.5 * sigma;
lower_thr  = mu - 2.5 * sigma;

% ── Binary detection (above threshold) ───────────────────
detected   = corrected > threshold;

% ── Find event edges (rising + falling) ──────────────────
diff_det   = diff([0, detected, 0]);
rise_idx   = find(diff_det == 1);
fall_idx   = find(diff_det == -1) - 1;

n_detected = length(rise_idx);
fprintf('Threshold Detection:\n');
fprintf('  Threshold Value    : %.4f (mean + 2.5σ)\n', threshold);
fprintf('  Events Detected    : %d\n', n_detected);

% ── Response times ────────────────────────────────────────
response_times = zeros(1, n_detected);
for k = 1:n_detected
    response_times(k) = (rise_idx(k) - 1) / Fs;
    dur = ((fall_idx(k) - rise_idx(k) + 1) / Fs) * 1000;
    fprintf('  → Event %d at t=%.2fs | duration=%.0f ms\n', ...
            k, response_times(k), dur);
end
fprintf('\n');


%% ─────────────────────────────────────────────────────────
%  SECTION 5: REPEATABILITY ANALYSIS
%% ─────────────────────────────────────────────────────────

% Extract peak values for each detected event
peak_values = zeros(1, n_detected);
for k = 1:n_detected
    seg = corrected(rise_idx(k):fall_idx(k));
    peak_values(k) = max(seg);
end

cv = (std(peak_values) / mean(peak_values)) * 100;   % Coefficient of Variation

fprintf('Repeatability Analysis:\n');
fprintf('  Peak Values   : %s\n', num2str(peak_values, '%.3f  '));
fprintf('  Mean Peak     : %.4f\n', mean(peak_values));
fprintf('  Std Dev       : %.4f\n', std(peak_values));
fprintf('  CV%%           : %.2f%% (lower = more repeatable)\n\n', cv);


%% ─────────────────────────────────────────────────────────
%  SECTION 6: FIGURE 1 — RAW vs FILTERED SIGNAL
%% ─────────────────────────────────────────────────────────

fig1 = figure('Name','Signal Overview','NumberTitle','off', ...
              'Color',[0.05 0.05 0.12],'Position',[50 400 1200 500]);

ax1 = subplot(2,1,1);
plot(t, raw_signal, 'Color',[0.3 0.6 1.0 0.5], 'LineWidth', 0.8);
hold on;
plot(t, filtered_signal, 'Color',[0.0 1.0 0.6], 'LineWidth', 1.8);
yline(mean(raw_signal) + 2.5*std(raw_signal), '--', 'Threshold', ...
      'Color',[1 0.4 0.2], 'LineWidth',1.5, 'LabelHorizontalAlignment','left');
for k = 1:length(event_times)
    xline(event_times(k), '--', 'Color',[1 1 0 0.5], 'LineWidth',1);
end
legend('Raw ADC Signal','Moving Avg Filter','Threshold', ...
       'FontSize',8,'TextColor','w','Color',[0.1 0.1 0.2]);
title('Raw vs Filtered Potentiometer Signal (Simulated Lateral Line)', ...
      'Color','w','FontSize',12,'FontWeight','bold');
xlabel('Time (s)','Color','w'); ylabel('ADC Value (0–1023)','Color','w');
set(ax1,'Color',[0.08 0.08 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
grid on;

ax2 = subplot(2,1,2);
plot(t, voltage, 'Color',[0.9 0.7 0.2], 'LineWidth', 1.4);
hold on;
for k = 1:length(event_times)
    xline(event_times(k), '--', 'Color',[0.4 0.9 0.4 0.7], 'LineWidth', 1.2);
end
title('Voltage Reading (0–5V)', 'Color','w','FontSize',11,'FontWeight','bold');
xlabel('Time (s)','Color','w'); ylabel('Voltage (V)','Color','w');
ylim([0 5.5]);
set(ax2,'Color',[0.08 0.08 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
grid on;

set(fig1,'PaperPositionMode','auto');


%% ─────────────────────────────────────────────────────────
%  SECTION 7: FIGURE 2 — FFT SPECTRUM + THRESHOLD DETECTION
%% ─────────────────────────────────────────────────────────

fig2 = figure('Name','FFT & Threshold Detection','NumberTitle','off', ...
              'Color',[0.05 0.05 0.12],'Position',[50 50 1200 600]);

% ── Subplot 1: Baseline-Corrected Signal with events marked ──
ax3 = subplot(3,1,1);
plot(t, corrected, 'Color',[0.4 0.8 1.0], 'LineWidth', 1.4);
hold on;
yline(threshold, '--r', 'Upper Threshold', 'LabelHorizontalAlignment','left', ...
      'Color',[1 0.3 0.3],'LineWidth',1.5);
yline(lower_thr, '--', 'Lower Threshold', 'LabelHorizontalAlignment','left', ...
      'Color',[0.6 0.3 1.0],'LineWidth',1.2);
% Shade detected events
for k = 1:n_detected
    t_start = (rise_idx(k)-1)/Fs;
    t_end   = fall_idx(k)/Fs;
    patch([t_start t_end t_end t_start], ...
          [min(corrected) min(corrected) max(corrected) max(corrected)], ...
          [1 0.6 0.1], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    text(t_start + 0.05, threshold * 1.1, sprintf('E%d',k), ...
         'Color',[1 0.8 0.2],'FontSize',9,'FontWeight','bold');
end
title('Baseline-Corrected Signal | Event Detection (Orange = Triggered)', ...
      'Color','w','FontSize',11,'FontWeight','bold');
xlabel('Time (s)','Color','w'); ylabel('Amplitude','Color','w');
set(ax3,'Color',[0.08 0.08 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
grid on;

% ── Subplot 2: Binary Detection Indicator ────────────────
ax4 = subplot(3,1,2);
area(t, detected * 1, 'FaceColor',[0.2 1.0 0.5], 'FaceAlpha',0.6, 'EdgeColor','none');
hold on;
plot(t, detected * 1, 'Color',[0.2 1.0 0.5], 'LineWidth', 1.2);
title('Binary Trigger Output  (1 = Disturbance Detected)', ...
      'Color','w','FontSize',11,'FontWeight','bold');
xlabel('Time (s)','Color','w'); ylabel('State (0/1)','Color','w');
ylim([-0.1 1.4]);
set(ax4,'Color',[0.08 0.08 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
grid on;

% ── Subplot 3: FFT Frequency Spectrum ────────────────────
ax5 = subplot(3,1,3);
bar(f_axis, P1, 'FaceColor',[0.6 0.3 1.0], 'EdgeColor','none', 'BarWidth',1.0);
hold on;
xline(dominant_freq, '--', sprintf('Peak: %.2f Hz', dominant_freq), ...
      'Color',[1 0.9 0.2],'LineWidth',2,'LabelHorizontalAlignment','right');
title('FFT Power Spectrum — Frequency Content of Disturbance Signal', ...
      'Color','w','FontSize',11,'FontWeight','bold');
xlabel('Frequency (Hz)','Color','w'); ylabel('|P1(f)|','Color','w');
xlim([0 Fs/2]);
set(ax5,'Color',[0.08 0.08 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
grid on;

set(fig2,'PaperPositionMode','auto');


%% ─────────────────────────────────────────────────────────
%  SECTION 8: FIGURE 3 — REPEATABILITY + RESPONSE TIME
%% ─────────────────────────────────────────────────────────

fig3 = figure('Name','Repeatability & Response Analysis','NumberTitle','off', ...
              'Color',[0.05 0.05 0.12],'Position',[700 400 900 500]);

% ── Subplot 1: Peak Amplitude per Event ──────────────────
ax6 = subplot(1,2,1);
event_labels = arrayfun(@(k) sprintf('Event %d',k), 1:n_detected, 'UniformOutput',false);
b = bar(1:n_detected, peak_values, 'FaceColor','flat', 'EdgeColor','none', 'BarWidth',0.5);
b.CData = [0.2 0.8 0.6; 0.2 0.6 1.0; 0.9 0.5 0.2];
hold on;
yline(mean(peak_values), '--w', sprintf('Mean = %.3f', mean(peak_values)), ...
      'LineWidth', 1.5, 'LabelHorizontalAlignment','right');
% Error bar for std
errorbar(1:n_detected, peak_values, repmat(std(peak_values),1,n_detected), ...
         '.', 'Color','w', 'LineWidth', 1.5);
set(ax6,'XTick',1:n_detected,'XTickLabel',event_labels,'Color',[0.08 0.08 0.15], ...
        'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
title(sprintf('Peak Response per Event\nCV = %.2f%%', cv), ...
      'Color','w','FontSize',11,'FontWeight','bold');
ylabel('Corrected Amplitude','Color','w');
grid on; box off;

% ── Subplot 2: Normalised Event Waveforms Overlay ─────────
ax7 = subplot(1,2,2);
hold on;
colors = {[0.2 0.8 0.6], [0.2 0.6 1.0], [1.0 0.6 0.2]};
max_len = 0;
for k = 1:n_detected
    seg_len = fall_idx(k) - rise_idx(k) + 1;
    if seg_len > max_len, max_len = seg_len; end
end

for k = 1:n_detected
    seg   = corrected(rise_idx(k) : fall_idx(k));
    seg_n = seg / max(abs(seg));             % Normalise to 1
    t_seg = (0:length(seg)-1) * (1000/Fs);  % ms
    plot(t_seg, seg_n, 'Color', colors{k}, 'LineWidth', 2.0, ...
         'DisplayName', sprintf('Event %d', k));
end
legend('FontSize',9,'TextColor','w','Color',[0.1 0.1 0.2]);
title('Normalised Event Waveforms (Repeatability)', ...
      'Color','w','FontSize',11,'FontWeight','bold');
xlabel('Time from Onset (ms)','Color','w');
ylabel('Normalised Amplitude','Color','w');
set(ax7,'Color',[0.08 0.08 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
grid on; box off;

set(fig3,'PaperPositionMode','auto');


%% ─────────────────────────────────────────────────────────
%  SECTION 9: FIGURE 4 — NEUROMAST HAIR CELL MODEL
%  (Bio-inspired: simulates lateral line frequency tuning)
%% ─────────────────────────────────────────────────────────

fig4 = figure('Name','Lateral Line Neuromast Model','NumberTitle','off', ...
              'Color',[0.05 0.05 0.12],'Position',[700 50 900 500]);

% ── Simulate 5 virtual neuromasts with different freq tuning ─
f_tune  = [0.5, 1.0, 2.0, 4.0, 8.0];     % Best-frequency of each hair cell
colors4 = cool(length(f_tune));

ax8 = subplot(2,1,1);
hold on;
for n = 1:length(f_tune)
    % Bandpass response: Gaussian tuning curve
    bw      = f_tune(n) * 0.6;
    tuning  = exp(-((f_axis - f_tune(n)).^2) / (2*bw^2));
    response = P1 .* tuning;
    plot(f_axis, response, 'Color', colors4(n,:), 'LineWidth', 1.8, ...
         'DisplayName', sprintf('NM %.1f Hz', f_tune(n)));
end
title('Virtual Neuromast Responses (Frequency-Tuned Hair Cells)', ...
      'Color','w','FontSize',11,'FontWeight','bold');
xlabel('Frequency (Hz)','Color','w'); ylabel('Response (Filtered Power)','Color','w');
xlim([0 20]);
legend('FontSize',8,'TextColor','w','Color',[0.1 0.1 0.2],'Location','northeast');
set(ax8,'Color',[0.08 0.08 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
grid on;

% ── Population Vector: firing rate proxy ─────────────────
ax9 = subplot(2,1,2);
firing_rates = zeros(1, length(f_tune));
for n = 1:length(f_tune)
    bw      = f_tune(n) * 0.6;
    tuning  = exp(-((f_axis - f_tune(n)).^2) / (2*bw^2));
    firing_rates(n) = sum(P1 .* tuning);    % Total power through this channel
end
firing_rates = firing_rates / max(firing_rates) * 100;  % % firing rate

b2 = bar(1:length(f_tune), firing_rates, 'FaceColor','flat', 'EdgeColor','none');
b2.CData = colors4;
set(ax9,'XTick',1:length(f_tune), ...
        'XTickLabel', arrayfun(@(f) sprintf('%.1f Hz',f), f_tune,'UniformOutput',false), ...
        'Color',[0.08 0.08 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
title('Neuromast Population Code — Relative Firing Rate (%)', ...
      'Color','w','FontSize',11,'FontWeight','bold');
xlabel('Neuromast Best Frequency','Color','w');
ylabel('Relative Firing Rate (%)','Color','w');
grid on; box off;

set(fig4,'PaperPositionMode','auto');


%% ─────────────────────────────────────────────────────────
%  SECTION 10: SUMMARY REPORT
%% ─────────────────────────────────────────────────────────

fprintf('============================================\n');
fprintf('         SYSTEM PERFORMANCE SUMMARY         \n');
fprintf('============================================\n');
fprintf(' Detection Range  : Simulated 5–15 cm zone  \n');

avg_dur_ms = mean((fall_idx - rise_idx + 1) / Fs) * 1000;
fprintf(' Avg Response Time: %.1f ms  (spec: ≤ 1000 ms) — %s\n', ...
    avg_dur_ms, iif(avg_dur_ms <= 1000, '✓ PASS', '✗ FAIL'));
fprintf(' Events Detected  : %d / %d  — %s\n', ...
    n_detected, length(event_times), ...
    iif(n_detected == length(event_times), '✓ PASS', '✗ FAIL'));
fprintf(' Repeatability CV : %.2f%%  (lower is better)\n', cv);
fprintf(' Dominant Freq    : %.2f Hz\n', dominant_freq);
fprintf('============================================\n\n');
fprintf('Figures generated:\n');
fprintf('  Fig 1 — Raw vs Filtered Signal\n');
fprintf('  Fig 2 — FFT Spectrum + Event Detection\n');
fprintf('  Fig 3 — Repeatability Analysis\n');
fprintf('  Fig 4 — Neuromast Hair Cell Model\n\n');
fprintf('Done.\n');


%% ─────────────────────────────────────────────────────────
%  HELPER FUNCTION
%% ─────────────────────────────────────────────────────────

function result = iif(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end