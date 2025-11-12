% >> dcaro_aura_fix()
% Usage: chunk = dcaro_aura_fix(chunk);
%        [chunk,times] = dcaro_aura_fix(chunk);
% 
%  Inputs:
%     chunk:            - Data chunk received from AURA LSL inlet. 
%                         Obtained from 'inlet.pull_chunk()' [nxm double].
% -------------------------------------------------------------------------
%  Optional inputs:
%     recorded:         - Whether the signal is pre-recorded or
%                         live-streamed from AURA software [1x1 double].
%                               Live-streamed: 0 (Default). 
%                               Pre-recorded: 1.
% -------------------------------------------------------------------------
%  Outputs:
%     chunk3:           - Fixed chunk without Ocular Artifacts. OA removal
%                         is achieved by dcaro_DWT_ANC.m [nxm double].
%     chunk2:           - Fixed chunk. Reconstructed original signal sent
%                         from AURA software via LSL [nxm double]. 
%     times             - Timestamps of the fixed samples [1xm double].
%
% ________________________________________________________________________
% 
%   This function takes the received raw chunk from the LSL inlet connected
%   to the AURA software and returns the closest corrected version of the
%   original chunk sent. 
% 
%   If loading a pre-recorded signal:
%       The number of samples in the returned chunk is equal to an eight 
%       part of the number of samples in the received chunk, now matching 
%       the correct 250 Hz sample rate from the AURA software.
%
%       This method works by computing the ifft of a segment of the 
%       corrupted fft of the original chunk. Then applies highpass-lowpass 
%       (bandpass) filters from 1-50 Hz and finally a stopband filter at 
%       60 Hz. 
%
%   If loading a live-streamed signal:
%       The number of samples in the returned chunk is equal to the number
%       of samples in the original streamed signal @ 250 Hz sample rate. 
%   
%       This method only applies a bandpass (highpass then lowpass) filter
%       and then a stopband filter to the received chunk.
% _________________________________________________________________________
% 
% by: Diego Caro López, Mirai Innovation Research Institute,
%     EMFUTECH Fall 2025, Osaka, Japan. 
%     23-Oct-2025

function varargout = dcaro_aura_fix(chunk,recorded)
    arguments
        chunk double 
        recorded (1,1) double {mustBeMember(recorded,[0 1])} = 0
    end

    if recorded
        n = round(size(chunk,2)/8);
        chunk2 = zeros(size(chunk,1),size(chunk,2)/8);
        for i = 1:size(chunk,1)
            y = fft(chunk(i,:));
            y = y(1:n);
            x = abs(ifft(y));
            chunk2(i,:) = -x/4;
        end
    else
        chunk2 = chunk;
    end
    % Bandpass filter
    [b,a] = butter(2,1/(250/2),'high');
    chunk2 = filtfilt(b,a,chunk2')';
    [b,a] = butter(2,50/(250/2));
    chunk2 = filtfilt(b,a,chunk2')';

    % CAR
    chunk2 = chunk2 - mean(chunk2,2);

    % Stopband filter
    [b,a] = butter(2,[59 61]/(250/2),'stop');
    chunk2 = filtfilt(b,a,chunk2')';

    % WAAF
    chunk2 = chunk2(:,0.5*250+1:size(chunk2,2)-0.5*250);
    chunk3 = dcaro_WAAF(chunk2);
    times = 0:size(chunk2,2)-1;
    times = times/250;

    varargout{1} = -chunk3;
    varargout{2} = -chunk2;
    varargout{3} = times;
end

% dcaro_stacked(EEG,'tile',1,'scale',200,'color','r','ref',1:8,'scalecol','none','lw',2) 
% hold on
% dcaro_stacked(clean,'tile',1,'scale',200,'color','k','scalecol','r')
