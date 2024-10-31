% 깨끗하게 백지에서 시작합니다
clc;
clear all;
close all;

% disp 함수의 출력 여부를 맨 위에서 변수 하나로 제어하기 위한 함수 정의입니다
% WHETHER_DISP = false;
WHETHER_DISP = true;

DISP = @(str) disp_or_not(str, WHETHER_DISP);
function disp_or_not(str, enable)
    if enable
        disp(str);
    end
end



DISP('############### Step 1. 반복 횟수에 맞추어서 인코딩을 하고, 잘 되었는지 확인해 보겠습니다.');
DISP('확인을 위한 예시 bits입니다.');
bits = [1 0 1].';
DISP('bits')
DISP(bits)

DISP('인코딩을 해보겠습니다. 반복 횟수는 3회입니다.');
channel_coded_bits = repelem(bits, 3);
DISP('channel_coded_bits');
DISP(channel_coded_bits);



DISP('############### Step 2. Repetion coding이 진짜 improvement를 가져오는지 확인하겠습니다.');
DISP('############### Step 2-1. improvement 여부를 보려면, coding이 없었을 때의 performance를 먼저 보아야 합니다.');

bits = [1 0 1].';
DISP('bits');
DISP(bits);

DISP('BPSK modulation을 합니다.');
transmit_symbol = 2 * bits - 1;
DISP('transmit_symbol');
DISP(transmit_symbol)

DISP('Flipping error를 발생시키겠습니다. 3개의 symbol마다 1개의 symbol이 flip됩니다.');
flip_err = [1 -1 1].';
received_symbol = transmit_symbol .* flip_err;
DISP('received_symbol의 3개 단위 symbol 중 2번째 symbol이 flip되었습니다. 나머지는 그대로입니다.');

DISP('BPSK demodulation을 합니다. modulation의 역연산입니다.');
decoded_bits = ((received_symbol + 1) / 2);
DISP('decoded_bits');
DISP(decoded_bits);

DISP('Communication Tool box에 있는 biterr 함수를 사용하여 Bit Error Rate를 구합니다.');
[~, BER_uncoded] = biterr(bits, decoded_bits);
DISP('BER_uncoded');
DISP(BER_uncoded);

DISP('############### Step 2-2. 이제 encoding 이후의 performance를 보겠습니다.')
bits = [1 0 1].';
DISP('bits');
DISP(bits);

DISP('인코딩을 해보겠습니다. 반복 횟수는 3회입니다.');
channel_coded_bits = repelem(bits, 3);
DISP('channel_coded_bits');
DISP(channel_coded_bits);

DISP('BPSK modulation을 합니다.');
transmit_symbol = 2 * channel_coded_bits - 1;
DISP('transmit_symbol');
DISP(transmit_symbol);

DISP('Flipping error를 발생시키겠습니다. 3개의 symbol마다 1개의 symbol이 flip됩니다.');
clear flip_err;
flip_err = repmat([1 -1 1].', 3, 1);
DISP('flip_err');
DISP(flip_err);
received_symbol = transmit_symbol .* flip_err;
DISP('received_symbol');
DISP(received_symbol);
DISP('received_symbol의 3개 단위 symbol 중 2번째 symbol이 flip되었습니다. 나머지는 그대로입니다.');

DISP('BPSK demodulation을 합니다. modulation의 역연산입니다.');
decoded_bits = ((received_symbol + 1) / 2);
DISP('decoded_bits');
DISP(decoded_bits);

DISP('Repetition coding의 역연산인 Decoding을 해보겠습니다.');
DISP('이 벡터를 3개 단위로 잘라서 reshape합니다.');
decoded_bits_reshaped = reshape(decoded_bits, 3, []);
DISP('decoded_bits_reshaped');
DISP(decoded_bits_reshaped);

DISP('이제 각 행마다 요소들을 다 더하면 0, 1, 2, 3이 나올 수 있습니다.');
sums = sum(decoded_bits_reshaped);
DISP('sums');
DISP(sums);

DISP('합이 2, 3이면 1이고, 0, 1이면 0에 대응됩니다. 다수결 투표 이후 transpose 해줍니다');
repetition_decoded_bits = (sums >= 2).';
DISP('repetition_decoded_bits');
DISP(repetition_decoded_bits);

DISP('Communication Tool box에 있는 biterr 함수를 사용하여 Bit Error Rate를 구합니다.');
[~, BER_repetition_uncoded] = biterr(bits, repetition_decoded_bits);
DISP('BER_repetition_uncoded');
DISP(BER_repetition_uncoded);
