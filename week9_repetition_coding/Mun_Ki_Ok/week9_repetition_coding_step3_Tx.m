WHETHER_JUST_TX_OR_GET_READY_FOR_TX = true;
% WHETHER_JUST_TX_OR_GET_READY_FOR_TX = false;

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

if WHETHER_JUST_TX_OR_GET_READY_FOR_TX == false
    % Tx_signal을 만들 때에는, 깨끗하게 백지에서 시작합니다.
    % 굳이 여기서 if문을 한 번 더 쓴 것은, DISP 함수 정의가 지워지지 않게 하기 위해서입니다.
    clc;
    clearvars -except sampling_freq N N_cp Tp img_path omega mu tp preamble repetition_factor buffer_for_recording_time_sec;
    close all;
    WHETHER_JUST_TX_OR_GET_READY_FOR_TX = false;
end

% DISP 함수의 출력 여부를 맨 위에서 변수 하나로 제어하기 위한 함수 정의입니다.
% WHETHER_DISP = false;
WHETHER_DISP = true;

DISP = @(str) disp_or_not(str, WHETHER_DISP);
function disp_or_not(str, enable)
    if enable
        disp(str);
    end
end

% 키 입력 콜백 함수
function keyPressCallback(evt, player)
    if strcmp(evt.Key, 'space')  % 스페이스바가 눌렸을 때
        if isplaying(player)
            stop(player);
            fprintf('\n재생이 중지되었습니다.\n');
        end
    end
end


if WHETHER_JUST_TX_OR_GET_READY_FOR_TX
    clc;
    close all;
    DISP('################################### 만들어져 있는 tx_signal을 보내겠습니다.');

    % audioplayer 객체 생성
    player = audioplayer(tx_signal, sampling_freq);    
    
    % 키보드 입력 처리를 위한 figure 생성
    fig = figure('KeyPressFcn', @(src, evt)keyPressCallback(evt, player));
    set(fig, 'Name', 'Press Space to Stop Playback', 'NumberTitle', 'off');
    
    % 재생 시작
    start_time = datetime("now", "Format", "yyyy-MM-dd HH:mm:ss");
    DISP(['tx 시작 시각: ', char(start_time)]);
    play(player);
    
    % 재생 상태 모니터링
    disp(['총 재생 시간: ', num2str(recording_time_sec), '초 (스페이스바를 누르면 중지됩니다)']);
    elapsed = 0;
    while isplaying(player)
        pause(1);
        elapsed = elapsed + 1;
        fprintf('\r진행 시간: %d초 / %d초 (%.1f%%)', ...
            elapsed, ceil(recording_time_sec), (elapsed/recording_time_sec)*100);
        
        if ~ishandle(fig)  % figure가 닫혔는지 확인
            stop(player);
            break;
        end
    end
    fprintf('\n');  % 줄바꿈을 추가하여 다음 출력이 깔끔하게 보이도록 함
    
    % 재생 종료 처리
    end_time = datetime("now", "Format", "yyyy-MM-dd HH:mm:ss");
    DISP('.');
    DISP(['tx 종료 시각: ', char(end_time)]);
    elapsed_time = end_time - start_time;
    DISP(['tx 중 총 경과 시간[s]: ', char(elapsed_time)]);
    
    % figure 정리
    if ishandle(fig)
        close(fig);
    end



else
    DISP('############### Step 3. 이미지 전송에 repetition coding을 적용해 보겠습니다.');
    DISP('################################### tx_signal을 만들겠습니다.');
    
    % % Parameter setting
    % % 맨 위로 위치 옮겼습니다. 원래 여기 있었다는 흔적 남기기 위해 지우지 않고 주석으로 처리합니다.
    % DISP('sampling frequency, N(=#sub-carrier), cyclic prefix len, preamble len 을 설정합니다.');
    % % sampling frequency
    % sampling_freq = 10000;
    % % N, that is #sub-carrier
    % N = 256;
    % % cyclic prefix len
    % N_cp = N / 4;
    % % preamble len
    % Tp = 1000;
    
    % % 맨 위로 위치 옮겼습니다. 원래 여기 있었다는 흔적 남기기 위해 지우지 않고 주석으로 처리합니다.
    DISP('image 경로를 지정해줍니다.');
    % img_path = 'C:\Users\okmun\OneDrive\대외 공개 가능\고려대학교 전기전자공학부\24_2\통신시스템설계 (신원재 교수님)\실습 수업 매트랩 코드\week9_HW';
    DISP(img_path);
    
    DISP('image를 읽어옵니다.');
    img = imread(fullfile(img_path, 'Lena_color.png'));
    
    DISP('image를 factor 비율만큼 줄입니다.');
    img_resize_scale_rate = 0.5;
    resized_img = imresize(img, img_resize_scale_rate);
    
    DISP('image를 gray-scale로 바꿉니다.');
    gray_img = rgb2gray(resized_img);
    
    DISP('image를 monochrome으로 바꿉니다.');
    binarised_img = imbinarize(gray_img);
    
    DISP('bit로 전송하기 위해, Column vector로 형식을 바꿉니다.');
    bits = binarised_img(:);
    
    DISP('repetition coding을 적용합니다. 반복 횟수는 3회입니다.');
    channel_coded_bits = repelem(bits, repetition_factor);
    
    DISP('BPSK modulation을 합니다.');
    symbols = 2 * channel_coded_bits - 1;
    
    DISP('symbol len, 전체 OFDM 심볼의 개수, pilot 신호를 포함한 전체 블록의 개수를 설정합니다.');
    M = length(symbols);
    cn = M / (N / 2);
    N_blk = cn + cn / 4;
    
    DISP('Block별로 Serial 신호를 싣기 위해 Parallel로 바꿉니다.');
    symbols_freq = {};
    for i = 1:cn
        symbols_freq{end + 1} = [0; symbols(N/2*(i-1)+1 : N/2*i)];
        symbols_freq{end} = [symbols_freq{end}; flip(symbols_freq{end}(2 : end-1))];
    end
    
    DISP('Inverse Discrete Fourier Transform을 합니다.')
    symbols_time = {}
    for i = 1:length(symbols_freq)
        symbols_time{end + 1} = ifft(symbols_freq{i}, N) * sqrt(N);
    end
    
    DISP('cyclic prefix를 집어넣습니다.');
    for i = 1 : length(symbols_time)
        symbols_time{i} = [symbols_time{i}(end - N_cp + 1 : end); symbols_time{i}];
    end
    
    DISP('Pilot signal을 집어넣습니다.');
    pilot_freq = ones(N, 1);
    pilot_time = ifft(pilot_freq) * sqrt(N);
    pilot_time = [pilot_time(end - N_cp + 1 : end); pilot_time];
    
    % % 맨 위로 위치 옮겼습니다. 원래 여기 있었다는 흔적 남기기 위해 지우지 않고 주석으로 처리합니다.
    % DISP('Preamble을 설정합니다. ** preamble 길이는 맨 위에서 Tp로 이미 설정하였습니다.');
    % omega = 10;
    % mu = 0.1;
    % tp = (1:Tp).';
    % preamble = cos(omega * tp + mu * tp.^2 / 2);
    
    DISP('전송하려면 serial이어야 하기 때문에 serial로 바꿉니다.');
    
    tx_signal = [preamble; pilot_time];
    for i = 1 : length(symbols_time)
        tx_signal = [tx_signal; symbols_time{i}];
        if rem(i, 4) == 0 && i ~= length(symbols_time)
            tx_signal = [tx_signal; pilot_time];
        end
    end

    recording_time_sec = (Tp + (cn + cn/4) * (N + N_cp)) / sampling_freq
    % recording_time_sec = recording_time_sec + buffer_for_recording_time_sec
    DISP("############Tx가 준비되었습니다.");
end