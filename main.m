%% Initialization
clc;
clear;
close all;

%% Parameters
Fs = 250; % Sampling rate (Hz) BENCHMARKDATASET
Nh = 5; % Number of harmonics to considerato for the reference signal
duration = 3.5; % Duration of signal we want to analyze (include pre & after stimulus) [seconds]
duration_raw_dataset= 6; %Entire length of the raw signal [seconds]
cut_time = 0.5; % time used to cut the signal pre & after stimulus
delay = 0.14; % Delay time due to neural pathways and creation of the SSVEP
duration_ref = duration-cut_time*2-delay; % Cutted EEG duration time to analyze [seconds]
Len = duration * Fs; % # samples of the entire EEG
t_raw = linspace(0, duration_raw_dataset, duration_raw_dataset * Fs); % time pint cutted EEG
t = linspace(0, duration, Len); % time points entire EEG
Len_ref = round(duration_ref * Fs); % # samples of the Cutted EEG
t_ref = linspace(0, duration_ref, Len_ref); % time points of the Cutted EEG
svm_enabled = input('Do you want to enable SVM? (1 for Yes, 0 for No): '); % Used to enable/disable SVM and use only standard-CCA

channels = [48 54 55 56 57 58 61 62 63]; % Channels used in this study: Pz, PO5, PO3, POz, PO4, PO6, O1, Oz, O2-> 9 channels
n_channels = length(channels);
frequency_band = [5 90]; % Bandpass filter frequency range (Hz)
n_subjects = 35; % Number of subjects
n_runs = 240; % Number of runs per subject (40 trials x 6 blocks)
n_classes = 40; % Number of classes
n_blocks = 6;

%% ( Extraction and creation of the dataset )
% Load of datas in directory
data_dir = "data";
% Get a list of all .mat files in the directory
file_list = dir(fullfile(data_dir, 'S*.mat'));

% Preallocate for storing data
all_subjects_data = cell(length(file_list), 1);

% Loop through files
for i = 1:length(file_list)
    % Load each .mat file
    file_path = fullfile(data_dir, file_list(i).name);
    loaded_data = load(file_path);

    % Store the 'data' matrix in a cell array
    all_subjects_data{i} = loaded_data.data;
end

% Access data for subject 1
subject1_data = all_subjects_data{1};
disp(size(subject1_data)); % Output: [64, 1500, 40, 6]

%% Selection of the 9 electrodes
% Preallocate for storing data
Nine_channels_data = cell(length(file_list), 1);

% Loop through all subjects and modify the data to keep only selected electrodes
for i = 1:length(all_subjects_data)
    % Get the data for the current subject
    subject_data = all_subjects_data{i};

    % Extract the data corresponding to the selected electrodes
    % The 'extracted_indexes' holds the indices of the target electrodes
    subject_data_selected = subject_data(channels, :, :, :); % Select electrodes

    % Store the filtered data back into the cell array (or you could save it)
    Nine_channels_data{i} = subject_data_selected;
end

% Example: Access modified data for subject 1 (only selected electrodes)
Nine_channels_data1 = Nine_channels_data{1};
disp(size(Nine_channels_data1)); % This will output: [9, 1500, 40, 6] for the 9 selected electrodes

%% Cutted Dataset--> Remotion of pre-stimulus & post stimulus parts (0.5 seconds each) + Remotion of delay time (first 0.14 seconds of after the stimulus start)
new_data = cell(length(file_list), 1);

for sbj = 1:length(Nine_channels_data)
    % Get the data for the current subject
    subject_data = Nine_channels_data{sbj};

    % Concatenate trials across all blocks
    %EEGdata = concatenate_runs(subject_data); % [9 x 1500 x 240]

    % loop over all blocks
    for block = 1:n_blocks
        EEGdata = subject_data(:,:,:,block);

        for trial = 1:n_classes
            % Extract EEG data for the current run
            X = EEGdata(:, :, trial); % [9 x 1500]

            % Extract the segment of X for the relevant time window
            X_segment = X(:,find(t >= cut_time & t <= cut_time + duration_ref)); % [9 x time points]

            new_data{sbj}(:,:,trial,block)=X_segment;
        end
    end
end

% Example: Access modified data for subject 1 (only selected electrodes)
new_data1 = new_data{1};
disp(size(new_data1)); % This will output: [9, 1215, 40, 6]

%% Create reference signals for each class
% Load stimulus frequencies and phases
load('Freq_Phase.mat');
fstim = freqs;
clear freqs;

%Reference signal generation
Xref = generate_reference_signals(fstim, Nh, t_ref);

% Plot the first three harmonics
figure(1);
hold on;
subplot(3,1,1);
plot(t_ref, Xref(:,1,1), 'b', 'LineWidth', 1.5); % 1st Harmonic, 1st Class
subtitle('8 Hz');
xlabel('Time (s)');
ylabel('Amplitude(uV)');
grid on;
legend('8 Hz', 'Location', 'best');

subplot(3,1,2);
plot(t_ref, Xref(:,3,1), 'r', 'LineWidth', 1.5); % 2nd Harmonic, 1st Class
subtitle('16 Hz');

subplot(3,1,3);
plot(t_ref, Xref(:,5,1), 'g', 'LineWidth', 1.5); % 3rd Harmonic, 1st Class
subtitle('24 Hz');

hold off;

sgtitle("Sine-based reference waves");

figure(2);
hold on;
subplot(3,1,1);
plot(t_ref, Xref(:,2,1), 'b', 'LineWidth', 1.5);

subplot(3,1,2);
plot(t_ref, Xref(:,4,1), 'r', 'LineWidth', 1.5);

subplot(3,1,3);
plot(t_ref, Xref(:,6,1), 'g', 'LineWidth', 1.5);

hold off;

sgtitle("Cos-based reference waves");

%% Common Average Referencing (CAR) Application
CAR_data = cell(length(file_list), 1);

for sbj = 1:n_subjects
    subject_data = new_data{sbj};

    for block = 1:n_blocks
        EEGdata = subject_data(:,:,:,block);

        for trial = 1:n_classes
            X = EEGdata(:,:,trial)';

            % CAR filter
            CAR_data{sbj}(:,:,trial,block) = apply_car_filter(X)';
        end
    end
end

CAR_data1 = CAR_data{1};
disp(size(CAR_data1)); % This will output: [9, 1215, 40, 6] for the 9 selected electrodes

%% BAND-Pass Filtering

%---> Design of the filter
[b, a] = butter(15, frequency_band / (Fs / 2), 'bandpass'); % designs an IIR (Infinite Impulse Response) Butterworth
filter of the third order
% frequency_band / (Fs / 2): normalizes the passband [8, 88] Hz to [8/(Fs/2), 88/(Fs/2)]
% b and a: The filter coefficients for the numerator and denominator of the filter's transfer function
% Frequency Response using freqz
[H, f] = freqz(b, a, 1024, Fs); % Compute frequency response

% Plot Magnitude Response
figure(3);
subplot(2, 1, 1);
plot(f, abs(H), 'b', 'LineWidth', 1.5); % Magnitude in linear scale
title('Frequency Response (Magnitude)');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
grid on;

% Plot Magnitude in Decibels
subplot(2, 1, 2);
plot(f, 20*log10(abs(H)), 'r', 'LineWidth', 1.5); % Magnitude in dB
title('Frequency Response (Magnitude in dB)');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on;

%----> Application of BP-Filter on the dataset
band_pass_data = cell(length(file_list), 1);

for sbj = 1:n_subjects
    subject_data = CAR_data{sbj};

    for block = 1:n_blocks
        EEGdata = subject_data(:,:,:,block);

        for trial = 1:n_classes
            X = EEGdata(:,:,trial)';

            % Band-pass filter
            band_pass_data{sbj}(:,:,trial,block) = filtfilt(b, a, X)';
        end
    end
end

filtered_data = band_pass_data;
filtered_data1 = filtered_data{1};
disp(size(filtered_data1)); % This will output: [9, 1215, 40, 6] for the 9 selected electrodes

%% Extract signals for plots of the different stage of Pre-Processing(SEE LATER)
% Extract the signals for each stage (for example, for electrode 1)
electrode_signal = Nine_channels_data{1}(1, :, 1,1); % Original signal (before filtering)
electrode_signal1 = new_data{1}(1, :, 1,1); % Original signal (before filtering)
CAR_signal = CAR_data{1}(1,:,1,1); % CAR filtered signal
filtered_signal = filtered_data{1}(1, :, 1,1); % Band-pass + CAR filtered signal


%% FFT plots Creation
nfft = 2^nextpow2(length(electrode_signal)); % Zero-padding for FFT
frequencies = (0:nfft/2-1) * (Fs / nfft); % Frequency axis (0 to Nyquist)

% FFT of the original signal
fft_original = fft(electrode_signal, nfft) / length(electrode_signal);
power_original = abs(fft_original(1:nfft/2)).^2; % Power spectrum

% FFT of the CAR filtered signal
fft_CAR_filtered = fft(CAR_signal, nfft) / length(CAR_signal);
power_CAR_filtered = abs(fft_CAR_filtered(1:nfft/2)).^2; % Power spectrum

% FFT of the CAR + band pass filtered signal
fft_filtered = fft(filtered_signal, nfft) / length(filtered_signal);
power_filtered = abs(fft_filtered(1:nfft/2)).^2; % Power spectrum

% Plot the power spectrum
figure;
subplot(3, 1, 1);
plot(frequencies, power_original, 'b');
title('Power Spectrum of raw EEG');
xlabel('Frequency (Hz)');
ylabel('Power');
grid on;
xlim([0 100]); % Restrict x-axis to 0-100 Hz

subplot(3, 1, 2);
plot(frequencies, power_CAR_filtered, 'r');
title('Power Spectrum After CAR Filter');
xlabel('Frequency (Hz)');
ylabel('Power');
grid on;
xlim([0 100]); % Restrict x-axis to 0-100 Hz

subplot(3, 1, 3);
plot(frequencies, power_filtered);
title('Power Spectrum After CAR + band pass Filter');
xlabel('Frequency (Hz)');
ylabel('Power');
grid on;
xlim([0 100]); % Restrict x-axis to 0-100 Hz

sgtitle('Comparison of Power Spectrum Before and After Filters');

%% AVERAGE SIGNALS (Data Exploration)
%------> average across blocks
% Preallocate the averaged dataset
averaged_data = cell(size(filtered_data));

% Loop through each subject
for i = 1:length(filtered_data)
    % Extract the data for the current subject
    subject_data = filtered_data{i}; % Dimension: 9x1215x40x6

    % First, average across the 4th dimension (blocks)
    data_avg_blocks = mean(subject_data, 4); % Dimension: 9x1215x40

    % Then, average across the 1st dimension (electrodes)
    %data_avg_electrodes = mean(data_avg_blocks, 1); % Dimension: 1x1215x40

    % Squeeze the result to remove singleton dimensions
    %averaged_data{i} = data_avg_electrodes; % Dimension: 1x1215x40
    averaged_data{i} = data_avg_blocks; % Dimension: 9x1215x40
end

% Now averaged_data contains the dataset with the last dimension averaged
averaged_signal1 = averaged_data{1}(1, :, 1,1);
disp(size(averaged_signal1));

%------> average across all patients
% Preallocate for the final averaged data
final_averaged_data = zeros(size(averaged_data{1})); % Dimension: 9x1215x40

% Loop through each subject and sum their data
for i = 1:length(averaged_data)
    final_averaged_data = final_averaged_data + averaged_data{i};
end

% Divide by the number of subjects to compute the average
final_averaged_data = final_averaged_data / length(averaged_data);

% Display the size of the final averaged data
disp(size(final_averaged_data)); % Should be 9x1215x40


% plot final average
final_average_signal = final_averaged_data(1,:,1);

% FFT of the average signal
final_fft_average = fft(final_average_signal, nfft) / length(final_average_signal);
final_power_average = abs(final_fft_average(1:nfft/2)).^2; % Power spectrum

% Plot the smoothed signal
figure;
plot(frequencies, final_power_average, 'b', 'LineWidth', 0.5); % Original signal
title('Power Spectrum');
xlabel('Frequency (Hz)');
ylabel('Power');
grid on;
xlim([0 100]);

% Averaging across all subjects--> 10.37 Hz disappear!

%% Analisys of FFT peaks
%------> find peaks in the FFT signal
[peak_heights, peak_indices] = findpeaks(final_power_average); % Applica findpeaks solo al segnale FFT

% Calculate corresponding frequencies
peak_frequencies = frequencies(peak_indices);

% sort peaks from the highest to the lowest
[sorted_heights, sort_order] = sort(peak_heights, 'descend');
sorted_frequencies = peak_frequencies(sort_order);

% keep just the highest peaks
num_peaks_to_keep = 10;
if length(sorted_heights) > num_peaks_to_keep
    sorted_heights = sorted_heights(1:num_peaks_to_keep);
    sorted_frequencies = sorted_frequencies(1:num_peaks_to_keep);
end

% Now sort the selected frequencies from lowest to highest
[sorted_frequencies, freq_sort_order] = sort(sorted_frequencies, 'ascend');
sorted_heights = sorted_heights(freq_sort_order);

% Save the sorted frequencies in an array
resulting_frequencies = sorted_frequencies;

% show results
disp('Frequencies corresponding to the highest peaks:');
disp(resulting_frequencies);

% plot the result with highlighted peaks
figure;
plot(frequencies, final_power_average);
hold on;
plot(sorted_frequencies, sorted_heights, 'ro', 'MarkerSize', 8);
title('FFT with the 10 highest peaks highlighted');
xlabel('Frequency (Hz)');
ylabel('Power spectrum');
legend('FFT spectrum', 'Peaks');
hold off;

%% Analisys of SNR
% Range of frequencies for SNR calculation
freq_range = 5:0.1:90; % Frequencies of interest
snr_values = zeros(size(freq_range)); % Array for SNR

% Noise window (5 Hz above and below each frequency)
noise_window = 5; % 5 Hz above and below the frequency

for i = 1:length(freq_range)
    % Find the index of the current frequency in the FFT
    [~, freq_index] = min(abs(frequencies- freq_range(i)));

    % Define the indices of the noise window
    noise_indices = (frequencies >= freq_range(i)- noise_window & ...
        frequencies <= freq_range(i) + noise_window);
    noise_indices(freq_index) = false; % Exclude the current peak

    % Calculate the signal power (current frequency)
    signal_power = final_power_average(freq_index);

    % Calculate the noise power (average of the window)
    noise_power = mean(final_power_average(noise_indices));

    % Calculate the SNR for the current frequency
    snr_values(i) = 10 * log10(signal_power / noise_power);
end

% Plot of SNR across all frequencies
figure;
plot(freq_range, snr_values, 'LineWidth', 1.5); % Continuous line for SNR
xlabel('Frequency (Hz)');
ylabel('SNR (dB)');
title('SNR across Frequencies (5-90 Hz)');
grid on;

%% SSVEP frequency recognition and performance evaluation (simple CCA)
% Variables Initialization--> [depends on the method used (CCA or CCA-SVM)]
if svm_enabled==1
    output_data=cell(n_subjects,n_runs);
else
    outputs = zeros(1, n_runs);
    output_data=zeros(n_subjects,n_runs);
    Ave_Acc_across_groups = zeros(n_subjects, 1);
end


% Method application
for sbj = 1:n_subjects
    subject_data = filtered_data{sbj};
    EEGdata = concatenate_runs(subject_data);

    % outputs = cells(40, n_runs);
    for run = 1:n_runs
        X = EEGdata(:,:,run)';

        % SSVEP frequency recognition using CCA
        Rho = zeros(1, size(Xref, 3));

        for j = 1:size(Xref, 3) % loop along all the 40 targets
            % Extract the segment of X for the relevant time window and channels
            X_segment = X(:,:)';

            % Perform CCA between the extracted segment and the reference signal
            %[Wx, Wy, Rho(j)] = myCCA(X_segment, Xref(:,:,j)');
            [Wx, Wy, r] = myCCA(X_segment, Xref(:,:,j)');

            % Store the largest canonical correlation for this target frequency
            Rho(j) = r(1);
        end
        if svm_enabled==1
            %rho vevtor for the SVM model
            output_data{sbj,run}=Rho;
        else
            % Determine the frequency with the highest canonical correlation
            [~, outputs(run)] = max(Rho);

        end

    end
    if svm_enabled==1
        disp(['CCA-SVM: Sbj_number', num2str(sbj)]);
    else
        output_data(sbj,:)=outputs;

        % Performance evaluation
        labels = repmat(1:n_classes, 1, n_runs / n_classes);
        TotalAccuracy = compute_accuracy(labels, outputs);
        Ave_Acc_across_groups(sbj) = TotalAccuracy;

        disp(['ONLY CCA: Total accuracy(', num2str(sbj), '): ', num2str(TotalAccuracy), ' %']);

    end



end

% If CCA--> will display the results directy
% If CCA-SVM will create a cell output_data (subj x runs) where runs is #trialsx#blocks: Inside each cells there is a 40-dimension vector (this has the correlation values for each frequences of stimulation)


%% Support Vector Machine Implementation

if svm_enabled==1
    % Train & Test Set Split
    train_set_cell = output_data(:,1:200);
    test_set_cell = output_data(:,201:240);

    % Creation of Dataset from Cells (subjectxtrials, n_classes))
    train_set = cellToMatrix(train_set_cell, n_classes, n_subjects, 200); % Matrix 7000x40 contains #subjects x 200 (WE USE FIRST 5 BLOCKS FOR THE TRAIN)
    test_set = cellToMatrix(test_set_cell, n_classes, n_subjects, 40); % Matrix 1400x40 contains #subjects x 40 (WE USE LAST 5 BLOCK FOR THE TEST)

    % Concatenate Labels to datasets (as Row)
    labels_train = repmat(1:40, 1, 175)';
    labels_test = repmat(1:40, 1, 35)';
    train_set = [train_set, labels_train];
    test_set = [test_set, labels_test];

    %% Classification Model
    train_sett = train_set(:,1:40);
    train_labelss = train_set(:,end);
    test_sett = test_set(:,1:40);
    test_labelss = test_set(:,end);

    % Model & Cross-validation
    cross_val_model = fitcecoc(train_sett, train_labelss, 'KFold', 5); % 5-fold cross-validation

    % Train accuracy calculation
    cv_accuracy = (1- kfoldLoss(cross_val_model)) * 100; % Percentuale di accuratezza
    disp(['Accuratezza durante la validazione incrociata: ', num2str(cv_accuracy), '%']);

    % Addestramento del modello finale sui dati di training completi
    final_model = fitcecoc(train_sett, train_labelss);

    % Prediction of the trained model
    predicted_labelss = predict(final_model, test_sett);

    % Test Accuracy
    test_accuracy = sum(predicted_labelss == test_labelss) / length(test_labelss) * 100;
    disp(['Accuratezza sul test set: ', num2str(test_accuracy), '%']);

    % Valutazione dell'overfitting
    disp('Valutazione dell''overfitting:');
    if test_accuracy < cv_accuracy
        disp('Possibile overfitting rilevato: la performance sul test set è inferiore a quella di validazione.');
    else
        disp('Nessun overfitting rilevato.');
    end

    % Matrice di confusione
    figure(8);
    confusionchart(test_labelss, predicted_labelss);
    title('Matrice di confusione');

    %% ROC CURVE
    % Calcolo delle probabilità (per curve ROC, il modello deve supportare score posteriori)
    [~, scores] = predict(final_model, test_sett);

    % Creazione della curva ROC per ogni classe
    figure(9);
    for class = 1:numel(unique(test_labelss)) % Usa test_labelss al posto di y
        [Xroc, Yroc, ~, AUC] = perfcurve(test_labelss, scores(:, class), class);
        plot(Xroc, Yroc, 'LineWidth', 2); hold on;
        disp(['AUC per la classe ', num2str(class), ': ', num2str(AUC)]);
    end
    xlabel('False Positive Rate');
    ylabel('True Positive Rate');
    title('ROC Curve per ogni classe');
    legend(arrayfun(@(x) ['Classe ', num2str(x)], unique(test_labelss), 'UniformOutput', false), 'Location', 'Best');
    grid on;

    %% PLOT EEG's signals
    figure(10);
    % Plot the signal at each preprocessing stage
    subplot(5, 1, 1);
    plot(t_raw, electrode_signal, 'b');
    title('Raw EEG Signal');
    xlabel('Time (s)');
    ylabel('Amplitude (\muV)');
    grid on;

    subplot(5, 1, 2);
    plot(t_ref, electrode_signal1, 'b');
    title('Raw EEG Signal cutted');
    xlabel('Time (s)');
    ylabel('Amplitude (\muV)');
    grid on;

    subplot(5, 1, 3);
    plot(t_ref, CAR_signal, 'g');
    title('EEG Signal After CAR Filter');
    xlabel('Time (s)');
    ylabel('Amplitude (\muV)');
    grid on;

    subplot(5, 1, 4);
    plot(t_ref, filtered_signal, 'm');
    title('EEG Signal After Band-pass + CAR Filters');
    xlabel('Time (s)');
    ylabel('Amplitude (\muV)');
    grid on;

    subplot(5, 1, 5);
    plot(t_ref, averaged_signal1, 'k');
    title('Averaged EEG Signal Across Blocks');
    xlabel('Time (s)');
    ylabel('Amplitude (\muV)');
    grid on;

    sgtitle('EEG Signal Preprocessing Stages');

    % ITR
    P = test_accuracy/100;
    ITR = (log2(n_classes)+P*log2(P)+(1-P)*log2((1-P)/(n_classes-1)))*60/duration;
    disp(['CCA-SVM Average ITR: ', num2str(ITR)]);
else
    %% Final results
    stderror = std(Ave_Acc_across_groups) / sqrt(length(Ave_Acc_across_groups));
    Ave_Acc_across_sbjs = mean(Ave_Acc_across_groups);
    plusminu = char(177);
    disp(['ONLY CCA Average accuracy: ', num2str(Ave_Acc_across_sbjs), ' ', plusminu, ' ', num2str(stderror), ' %']);

    % ITR
    P = Ave_Acc_across_sbjs/100;
    ITR = (log2(n_classes)+P*log2(P)+(1-P)*log2((1-P)/(n_classes-1)))*60/duration;
    disp(['ONLY CCA Average ITR: ', num2str(ITR)]);
end