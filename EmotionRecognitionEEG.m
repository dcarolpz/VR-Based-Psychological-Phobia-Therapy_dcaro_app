% >> EmotionRecognitionEEG.m
% Usage: EmotionRecognitionEEG
% -------------------------------------------------------------------------
% Emotion Recognition with EEG.
% This script receives data via an LSL inlet connected to the Aura EEG
% software, then preprocess it with the following steps:
%       1. Bandpass filter (1-50 Hz).
%       2. Common Average Reference.
%       3. Stopband filter (60 Hz).
%       4. WAAF. 
%
% The data is received in 6-second chunks. After cleaning, only
% 5-second windows are preserved due to window edge artifacts, fixed by
% removing 0.5 seconds from the start and end of each original window. 
% 
% Once the data is clean, a Neural Network (CNN + LSTM) assigns one of
% these four labels to the window:
%       1. Surprise.
%       2. Relief.
%       3. Fear. 
%       4. Disgust. 
%__________________________________________________________________________
%
% by: Diego Caro López, Mirai Innovation Research Institute,
%     EMFUTECH Fall 2025, Osaka, Japan. 
%     05-Nov-2025.

clear
clc
close all

% General parameters 
load('Models/1_5-Nov-2025.mat')
fs = 250;
window_size = 6;    
recorded = 0;

% Initializing TCP/IP communication with Python/Unity
try
    fprintf('Starting TCP/IP client. \n')
    t = tcpclient('localhost',4000);
    fprintf('Ready to send emotion data. \n\n')
catch
    warning('Could not start TCP/IP client.')
end

channels = {'Fp2','F7','F8','T7','T8','P7','P3','P8'};
classes = {'Surprise','Relief','Fear','Disgust'};
if recorded == 0
    window = zeros(size(channels,2),fs*window_size);
else
    window = zeros(size(channels,2),8*fs*window_size);
end

% Initializing LSL library
fprintf('Starting LSL stream.\n')
lib = lsl_loadlib();

% Resolving stream
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG'); 
end

% Opening inlet
inlet = lsl_inlet(result{1},[],size(window,2),0);
inlet.open_stream
inlet.set_postprocessing(15)
fprintf('Success.\n\nNow receiving Aura data -dcarolpz.\n')

figure
while true
    [chunk,stamps] = inlet.pull_chunk();

    if isempty(chunk) || size(chunk,2) ~= size(window,2)
        pause(0.05);
        continue
    else
        [clean,raw] = dcaro_aura_fix(chunk,recorded);
        scores = predict(dcaro_net,clean);
        clf
        dcaro_stacked(raw,'fs',fs,'color','r','ref',1:8,'scale',200,'tile',1)
        dcaro_stacked(clean,'fs',fs,'color','k','scale',200,'tile',1)
        fprintf('\n')
        for i = 1:numel(classes)
            fprintf([classes{i} ': ' num2str(round(100*scores(i),2)) '%%\n'])
        end
        [~,id] = max(scores);
        try 
            write(t,uint8(id))
            fprintf('Emotion sent successfully! -dcarolpz.\n')
        catch
            warning('Emotion not sent.')
        end
    end
end
% inlet.close_stream
% inlet.delete
