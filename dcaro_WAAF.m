% >> dcaro_WAAF()
% Usage: eeg = dcaro_WAAF(eeg)
% 
%  Inputs:
%     eeg:            - EEG data with Ocular Artifacts [nxm double]. 
% -------------------------------------------------------------------------
%  Optional inputs:  
%     wavelet:        - Mother wavelet to use in wavelet decomposition. See 
%                       https://mathworks.com/help/wavelet/ref/wfilters.html 
%                       for supported wavelets. Default: 'db4'. [# char].
%     level:          - Wavelet decomposition level. Default: 7. A low 
%                       level doesn't remove noise effectively. A high 
%                       level has low SNR. Default: 7 [1x1 double].
%     attn:           - Detail coefficient levels to attenuate. Default: 
%                       lowest 4 levels [1xn double]. 
% -------------------------------------------------------------------------
%  Outputs:
%      eeg:           - Denoised EEG data [nxm double]. 
%      ref:           - Reference signals removed by ANC. A reference is
%                       extracted for each channel [nxm double].
%      weights:       - Weights returned by the RLS algorithm.
%__________________________________________________________________________
%
%   dcaro_WAAF: Wavelet-Assisted Adaptative Filter.
%
%   This function removes Ocular Artifacts from EEG signals by creating a 
%   reference signal that contains only these artifacts using a soft 
%   treshold in low frequency levels of a wavelet decomposition. This 
%   reference signal is removed from the original EEG through an Adaptative 
%   Noise Cancelling algorithm based on Recursive Least Squares. 
% 
%   Original paper: 
%   [1] Peng, H., Hu, B., Shi, Q., Ratcliffe, M., Zhao, Q., Qi, Y., & Gao,
%       G. (2013). Removal of ocular artifacts in EEG—An improved approach 
%       combining DWT and ANC for portable applications. IEEE journal of 
%       biomedical and health informatics, 17(3), 600-607.
% 
%   Soft treshold value obtained from: 
%   [2] Coifman, R. R., & Donoho, D. L. (1995). Translation-invariant 
%       de-noising. In Wavelets and statistics (pp. 125-150). New York, 
%       NY: Springer New York.
%__________________________________________________________________________
%
% by: Diego Caro López, Mirai Innovation Research Institute,
%     EMFUTECH Fall 2025, Osaka, Japan. 
%     24-Oct-2025 

function varargout = dcaro_WAAF(eeg,wavelet,level,attn)
    arguments
        eeg double
        wavelet char = 'db4'
        level double {mustBeInteger} = 7
        attn double {mustBeLessThanOrEqual(attn,level)} = 1:4
    end
    
    chans = size(eeg,1);
    refs = zeros(size(eeg));
    eeg2 = zeros(size(eeg));
    weights = zeros(size(eeg));
    for j = 1:chans
        x = eeg(j,:);
        
        % Wavelet decomp.
        [c,l] = wavedec(x,level,wavelet);
        D = detcoef(c,l,1:level);
        AN = appcoef(c,l,wavelet,level);
    
        T = zeros(1,level);
        D2 = D;
        for i = 1:level
            if ismember(i,attn)
                % Using treshold value proposed in [2]
                sj = median(abs(D{i}-median(D{i})))/0.6745; 
                T(i) = sj*sqrt(2*log(length(D2{i})));
                D2{i} = wthresh(D{i},'s',T(i));
            end
        end
        
        % Signal reconstruction
        c2 = [AN flip(cell2mat(cellfun(@flip,D2,'UniformOutput',false)))];
        ref = waverec(c2,l,wavelet);
    
        % ANC based on RLS 
        % (Order M=1; P is scalar, Taken direclty from [1]).
        e = zeros(size(x));
        P = 1e4;                            % Inverse Autocorrelation.
        lambda = 0.98;                      % Forgetting factor.
        w = ones(1,size(ref,2)+1);          % Initial weights.
        for k = 1:size(ref,2)
            % Cross-correlation 
            Pi = ref(k)*P;
            
            % Obtain gain & filter output
            g = Pi/(lambda + Pi.*ref(k));
            y = w(k)*ref(k);
            
            % Update EEG
            e(k) = x(k) - y;
            
            % Update weights and correlation matrix
            w(k+1) = w(k) + g*e(k);
            P = (P - g*Pi)/lambda;
        end
        refs(j,:) = ref;
        eeg2(j,:) = e;
        weights(j,:) = w(1:end-1);
    end   
    varargout{1} = eeg2;
    varargout{2} = refs;
    varargout{3} = weights;
end
