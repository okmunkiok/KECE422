WHETHER_JUST_RX_OR_GET_READY_FOR_TX = true;
% WHETHER_JUST_RX_OR_GET_READY_FOR_TX = false;

% Parameter setting
% sampling frequency
sampling_freq = 10000;
% repetition coding 반복 횟수
repetition_factor = 3;
% N, that is #sub-carrier
N = 256;
% cyclic prefix len
N_cp = N / 4;
% 이미지 경로
img_path = 'C:\Users\okmun\OneDrive\대외 공개 가능\고려대학교 전기전자공학부\24_2\통신시스템설계 (신원재 교수님)\실습 수업 매트랩 코드\week9_HW';
% preamble len
Tp = 1000;
% rest of preamble setting
omega = 10;
mu = 0.1;
tp = (1:Tp).';
preamble = cos(omega * tp + mu * tp.^2 / 2);

% 설정 단계에서 recording time이 계산된다
% recording_time_sec = 20;
buffer_for_recording_time_sec = 5;
img_resize_scale_rate = 0.5;


if WHETHER_JUST_RX_OR_GET_READY_FOR_TX == false
    clc;
    clearvars -except sampling_freq N N_cp Tp img_path omega mu tp preamble repetition_factor buffer_for_recording_time_sec;
    close all;
    WHETHER_JUST_TX_OR_GET_READY_FOR_TX = false;

    disp('image 경로를 지정해줍니다.');
    % img_path = 'C:\Users\okmun\OneDrive\대외 공개 가능\고려대학교 전기전자공학부\24_2\통신시스템설계 (신원재 교수님)\실습 수업 매트랩 코드\week9_HW';
    disp(img_path);
    
    disp('image를 읽어옵니다.');
    img = imread(fullfile(img_path, 'Lena_color.png'));
    
    disp('image를 factor 비율만큼 줄입니다.');
    img_resize_scale_rate = 0.5;
    resized_img = imresize(img, img_resize_scale_rate);
    
    disp('image를 gray-scale로 바꿉니다.');
    gray_img = rgb2gray(resized_img);
    
    disp('image를 monochrome으로 바꿉니다.');
    binarised_img = imbinarize(gray_img);
    
    disp('bit로 전송하기 위해, Column vector로 형식을 바꿉니다.');
    bits = binarised_img(:);
    
    disp('repetition coding을 적용합니다. 반복 횟수는 3회입니다.');
    channel_coded_bits = repelem(bits, repetition_factor);
    
    disp('BPSK modulation을 합니다.');
    symbols = 2 * channel_coded_bits - 1;
    
    disp('symbol len, 전체 OFDM 심볼의 개수, pilot 신호를 포함한 전체 블록의 개수를 설정합니다.');
    M = length(symbols);
    cn = M / (N / 2);
    N_blk = cn + cn / 4;

    recording_time_sec = (Tp + (cn + cn/4) * (N + N_cp)) / sampling_freq
    recording_time_sec = recording_time_sec + buffer_for_recording_time_sec
else
    clc;
    close all;
    % 수신 시작
    devicereader = audioDeviceReader(sampling_freq);
    setup(devicereader);
    disp(['총 녹음 시간: ', num2str(recording_time_sec), '초']);
    rx_signal = [];
    elapsed = 0;
    tic;
    
    while toc < recording_time_sec  % recording_time_sec 동안 녹음
        acquiredAudio = devicereader();
        rx_signal = [rx_signal; acquiredAudio];
        
        % 1초마다 진행 상태 업데이트
        if floor(toc) > elapsed
            elapsed = floor(toc);
            fprintf('\r녹음 진행: %d초 / %d초 (%.1f%%)', ...
                elapsed, ceil(recording_time_sec), (elapsed/recording_time_sec)*100);
        end
    end
    fprintf('\n');  % 줄바꿈 추가
    disp('Recording Completed')
    
    % Time Synchronisation
    [xC, lags] = xcorr(rx_signal, preamble);
    [~, idx] = max(xC);
    start_pt = lags(idx);
    
    rx_signal = rx_signal(start_pt + Tp + 1 : end);
    
    % Serial to Parallel
    OFDM_blks = {};
    for i = 1 : N_blk
        OFDM_blks{end + 1} = rx_signal(N_cp + 1 : N + N_cp);
        rx_signal = rx_signal(N_cp + N + 1 : end);
    end
    
    % Discrete Fourier Transform (DFT)
    demode_OFDM_blks = {};
    for i = 1 : length(OFDM_blks)
        demode_OFDM_blks{end + 1} = fft(OFDM_blks{i} / sqrt(N));
    end
    
    % Channel Estimation & Equalisation
    symbols_eq = {};
    for i = 1 : length(demode_OFDM_blks)
        if rem(i, 5) == 1
            channel = demode_OFDM_blks{i} ./ ones(N, 1);
        else
            symbols_eq{end + 1} = demode_OFDM_blks{i} ./ channel;
        end
    end
    
    % Detection
    symbols_detect = {};
    for i = 1 : length(symbols_eq)
        symbols_detect{end + 1} = sign(real(symbols_eq{i}));
    end
    
    % Demodulation
    symbols_est = [];
    for i = 1 : length(symbols_detect)
        symbols_est = [symbols_est; symbols_detect{i}(2 : N / 2 + 1)];
    end
    
    % BPSK Demodulation
    decoded_bits = (symbols_est + 1) / 2;
    
    % Repetition Decoding
    % 3개씩 묶어서 reshape
    decoded_bits_reshaped = reshape(decoded_bits, repetition_factor, []);
    
    % 각 열의 합을 계산 (다수결 원칙 적용)
    sums = sum(decoded_bits_reshaped);
    
    % 합이 2 이상이면 1, 미만이면 0으로 판정
    repetition_decoded_bits = (sums > repetition_factor / 2).';
    
    % Source Decoding & Show img
    % 이미지 크기 계산 시 repetition decoding으로 인한 크기 변화 고려
    img_size = sqrt(length(repetition_decoded_bits));
    estimated_img = reshape(repetition_decoded_bits, [img_size, img_size]); 
    resized_estimated_img = imresize(estimated_img, 1 / img_resize_scale_rate);
    imshow(resized_estimated_img);

    disp('Communication Tool box에 있는 biterr 함수를 사용하여 Bit Error Rate를 구합니다.');
    [~, BER] = biterr(binarised_img, estimated_img);
    BER
end