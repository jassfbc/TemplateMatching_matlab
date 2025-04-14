
[audioData, fs] = audioread("five.wav");
[audioData1, fs1]= audioread("zero.wav");
[audioData2, fs2 ]= audioread("on.wav");
[audioExample, fs_exp] = audioread("expl1.wav");

%rod hedha yi5dim ou fasa5 il line 3 to test audioresample:
%[audioExample, fs_exp] = audioread("C:\Users\jass\Downloads\1743808833027lq87fdj-voicemaker.in-speech.wav");
%audio_example_resample = audioresample(audioExample,fs_exp,fs); 



% affichage es signatures temporelles des trois signaux
figure;

t = (0:length(audioData)-1) / fs;
subplot(3,1,1);
plot(t, audioData);
xlabel('Temps (secondes)');
ylabel('Amplitude');
title('signature temporelle du mot "five"');
grid on;

t1 = (0:length(audioData1)-1) / fs1;
subplot(3,1,2);
plot(t1, audioData1);
xlabel('Temps (secondes)');
ylabel('Amplitude');
title('signature temporelle du mot "zero"');
grid on;

t2 = (0:length(audioData2)-1) / fs2;
subplot(3,1,3);
plot(t, audioData2);
xlabel('Temps (secondes)');
ylabel('Amplitude');
title('signature temporelle du mot "on"');
grid on;


%%
% Les paramètres utilisé:
windowsize = 265; 
fft_nb = 1024;



%hamming window 
alpha = 0.54;
beta = 1 - alpha;
n= (0:windowsize-1)';
hamming_window_function = alpha - beta * cos((2 * pi * n) / (windowsize - 1));

%% spectrogramme du signal 

F = fs*(0:(fft_nb/2))/fft_nb;

[frame_number, S_db,t_mean] = spectrogram_figure(audioData,fs, windowsize, fft_nb, "Spectrograme du signal du mot five",hamming_window_function, F);
[frame_number1, S_db1,t_mean1] = spectrogram_figure(audioData1,fs1, windowsize, fft_nb, "Spectrograme du signal du mot zero",hamming_window_function, F);
[frame_number2, S_db2,t_mean2] = spectrogram_figure(audioData2,fs2, windowsize, fft_nb, "Spectrograme du mot on ",hamming_window_function, F);



 %%

%spectrogramme du signal d'exemple 
[frame_number_expl, S_db_example, t_mean_expl] = spectrogram_figure(audioExample, fs, windowsize, fft_nb, "Spectrogramme du signal de l'exemple", hamming_window_function, F);


%% template matching with cross correlation

%trimming the template: 
% Threshold for silence in dB
silence_threshold_db = 5;

% Find columns (time frames) where all frequency bins are below the threshold
non_silent_columns = any(S_db > silence_threshold_db, 1);

% Apply the mask to S_db and corresponding time
S_db_trimmed = S_db(:, non_silent_columns);
t_mean_trimmed = t_mean(non_silent_columns);



%plot the spectrogramme
figure Name spectrogrm_for_audioData; 
imagesc(t_mean_trimmed,F,S_db_trimmed);
axis xy;
title("Spectrogram for the Template trimmed"); 
xlabel("Time");
ylabel("Frequencies"); 
colorbar; 

template_trame_number = size(S_db_trimmed,2);

[norm_template,max_index] = correlation(S_db_example,S_db_trimmed, frame_number_expl, template_trame_number, t_mean_expl, F);

norm_S_db_example = (S_db_example - mean(S_db_example(:))) / std(S_db_example(:));


%% Lecture de performance 
lecture_performance(norm_template ,norm_S_db_example,max_index,template_trame_number);




%% adding noise to the signal 

noise_amp = [0.01, 0.05, 0.1, 0.2, 0.5];
for i=1:length(noise_amp)
    noise = noise_amp(i) * randn(size(audioExample)); 
    noisy_example = audioExample + noise; 
    
    % spectrogram of the noisy signal: 
    
    [frame_number_noisy, S_noisy_db,t_mean_noisy] = spectrogram_figure(noisy_example,fs, windowsize, fft_nb, "Spectrograme du signal bruité avec une amplitude de bruit" + string(noise_amp(i)),hamming_window_function, F);
    [norm_template, max_index] = correlation(S_noisy_db,S_db_trimmed, frame_number_noisy, template_trame_number, t_mean_noisy, F);
    
    
    norm_S_noisy_db = (S_noisy_db - mean(S_noisy_db(:))) / std(S_noisy_db(:));
    disp("amplitude du bruit =");
    disp(noise_amp(i));
    
    lecture_performance(norm_template,norm_S_noisy_db,max_index,template_trame_number);
end


%% test with other audios 

%test avec une voie feminine. 
example_2 = audioread("expl2.wav"); 
[frame_number_expl2, S_db_2,t_mean_expl2] = spectrogram_figure(example_2,fs, windowsize, fft_nb, "Spectrograme du second exemple",hamming_window_function, F);
[norm_tempalte,max_index] = correlation(S_db_2,S_db_trimmed, frame_number_expl2, template_trame_number, t_mean_expl2, F);
norm_S_db_2 = (S_db_2 - mean(S_db_2(:))) / std(S_db_2(:));
lecture_performance(norm_template,norm_S_noisy_db,max_index,template_trame_number);

 %% function definitions 

 function [frame_number, S_db, t_mean ] = spectrogram_figure(signal,fs, windowsize, fft_number, plot_title,hamming_window_function, F)
    %division des trames
    frame_number = floor(length(signal)/windowsize);
    signal = signal(1:windowsize*frame_number);
    signal_frames = reshape(signal,windowsize,frame_number);

    t= (0: length(signal )-1) / fs;
    t = t(1:windowsize*frame_number); 
    t_frame  = reshape(t,windowsize,frame_number);
    t_mean = mean(t_frame);

    signal_fft = zeros(fft_number/2 + 1, frame_number);  

    %application de la fft pour chaque trame
    for i=1:frame_number
        frame = signal_frames(:,i) .* hamming_window_function;
        frame_fft = fft(frame,fft_number);
        signal_fft(:, i) = abs(frame_fft(1:fft_number/2 + 1));  
    end
    
    %convertion du resultat en db
    S_db = 10 * log10(signal_fft + eps); 
   
    %affichage du spectrogramme
    figure; 
    imagesc(t_mean,F,S_db);
    axis xy;
    title(plot_title); 
    xlabel("Time");
    ylabel("Frequencies"); 
    colorbar;  
 end 

 function [norm_template,max_index] = correlation(example, template, frame_expl_number, frame_template_number, t_mean_expl, F )
    corr = zeros(1, frame_expl_number - frame_template_number + 1);  
    
    norm_template = (template - mean(template(:))) / std(template(:));
    
    % For each possible shift in the example (slide the template over the example)
    for i = 1:(frame_expl_number - frame_template_number + 1)
        
        % Extract a segment from the example audio that matches the template's size
        segment = example(:, i:i + frame_template_number - 1);
        
        % Compute the normalized cross-correlation between the template and the segment
        % Normalize both the template and the segment before cross-correlation
        
        norm_segment = (segment - mean(segment(:))) / std(segment(:));
        
        
        % Compute the correlation score (element-wise multiplication and summing)
        if size(norm_segment)==size(norm_template)
            corr(i) = dot(norm_template(:),norm_segment(:));
        else
            disp('Size mismatch between template and segment!');
        end
    end
    
    
    % Find the time index where the maximum correlation occurs
    [~, max_index] = max(corr);  % max_index gives the position in time
    
    % Calculate the time where the match occurs
    match_time = t_mean_expl(max_index);
    
    % Display the match time
    disp('Template match found at time:');
    disp(match_time);
    
    % Visualize the spectrogram with the matched region highlighted
    figure;
    imagesc(t_mean_expl, F, example);
    axis xy;
    title("Spectrogram de l'exemple avec la position du template");
    xlabel('Time');
    ylabel('Frequency');
    colorbar;
    
    % Highlight the matching region
    hold on;
    plot([match_time match_time], ylim, 'r', 'LineWidth', 2); 

 end 

 function lecture_performance (template, example, index, trame_number)
    performance = norm(template - example(:,index:index + trame_number-1),'fro');
    disp("performance = ");
    disp(performance);
 end 





