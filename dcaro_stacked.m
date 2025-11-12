% >> dcaro_stacked()
% Usage: dcaro_stacked(EEG)
%
%  Inputs:
%     EEG:            - EEG struct (1x1 struct)/EEG.data (nxm double) 
%                       from eeglab.
%                     - EEG.data (nxm double) requires argument fs. 
%
%  Optional keywords (name-value):
%     win:            - Time window to plot EEG data [1x2 double]. 
%     color:          - Color to use in figure stacked plots [# string/char]. 
%     fs:             - Sample frequency (if input is EEG.data) [1x1 double].
%     labels:         - Electrode labels [1xn cell].
%     tile:           - Tile to subplot in (as tiledlayout) [1x1 double].
%     scale:          - Fix scale to scalar value (µV) [1x1 double].
%     scalecol:       - Color to use in the scale line [# string/char].
%     ref:            - Reference channels to dim [1xn double]. 
%     lw:             - Linewidth to use for all channels [1x1 double].
%     target:         - Target axes to generate figure [1x1 axes/UIAxes].
% _________________________________________________________________________
%
%  Examples:
%  >> dcaro_stacked(EEG): 
%      - Generates stacked plot from EEG struct.
%      - Plots full signal (window not specified).
%      - Uses default colors. 
%      - Labels are taken from EEG.chanlocs.labels, if the field doesn't
%        exists, labels are auto-generated.
%      - Scale is adjusted to the smallest factor of 50 that is greater 
%        than the average amplitude of all the channels.
%      - Scale color is set to black.
%       
%  >> dcaro_stacked(EEG.data,'fs',1000,'labels',labels,'win',[20 30], ...
%         'scale',100,'color','k','ref',[29:32],'scalecol','r','lw',1.5):
%      - Generates stacked plot from EEG.data.
%      - Uses 1000 Hz as sample rate.
%      - Uses the variable labels with char cell array of channel labels.
%      - Plots window from 20 to 30 seconds of the signal. 
%      - Fixes the scale to 100 µV.
%      - Plots all the channels in black.
%      - Dims the color of channels 29 to 32.
%      - Sets the scale color to red. 
%      - Uses 1.5 linewidth for all channels. 
%  
%  >> dcaro_stacked(EEG_raw.data,'tile',1,'fs',1000,'labels',labels, ...
%         'win',[5 9],'scale',100,'color','k','ref',1:32,'scalecol','none')
%     hold on
%     dcaro_stacked(EEG_clean.data,'tile',1,'fs',1000,'labels',labels,...
%         'win',[5 9],'scale',100,'color','k','scalecol','r'): 
%      - Generates one figure.
%      - Plots raw EEG in dimed black in the background.
%      - Plots clean EEG in black infront of the raw.
%      - Uses 1000 Hz as sample rate.
%      - Uses variable labels with char cell array of channel labels.
%      - Plots window from 5 to 9 seconds of both EEGs.
%      - Fixes the scale of both EEGs to 100 µV.
%      - Displays only one scale bar for both EEGs in color red. 
% _________________________________________________________________________
%
%   If available, this function will use eeglab functions: 
%       - eeg_emptyset.m
%       - pop_select.m
%__________________________________________________________________________
%       
% by: Diego Caro López, University of Houston,
%     Laboratory for Non-Invasive Brain Machine Interface Systems 2024.
%     28-Aug-2024.

function dcaro_stacked(EEG,varargin)
    
    % First, validate arguments
    args = ["win" "fs" "color" "labels" "tile" "scale" "scalecol" "ref" "lw" "target"];
    win = [];

    if mod(size(varargin,2),2) == 1
        error('Invalid number of name-value arguments.')
    elseif size(varargin,2) > 20
        error('Number of possible arguments exceeded.')
    end

    for i = 1:length(varargin)/2
        name = varargin{2*i-1};
        if class(name) == "char" || class(name) == "string"
            if ~ismember(name,args)
                error("Unrecognized argument: " + name)
            else
                save_args(varargin{2*i-1},varargin{2*i}) 
                    % ----> See save_args at the end.
            end
        else
            error("foo:bar","Arguments names must be class string or " + ...
                "char.\n Invalid class of argument in position: " + num2str(2*i))
        end
    end

    try
        EEG.srate;   % Check if EEG is eeglab struct/EEG.data
        if exist('fs','var')
            warning('off','backtrace')
            warning('fs argument ignored. Using EEG.srate instead.')
            warning('on','backtrace')
        end 
    catch me
        switch me.identifier
            % Generate own EEG struct with desired fields
            case 'MATLAB:structRefFromNonStruct'
                if ~isempty(EEG)
                    if ~exist('fs','var')
                        warning('off','backtrace')
                        warning('EEG data requires to specify fs. Plotting samples.')
                        warning('on','backtrace')
                        fs = 1;
                    end
                    fprintf('Input is EEG.data. \n\n')
                    EEG_data = EEG;
                    clear EEG
                    try
                        EEG = eeg_emptyset;
                    catch
                        EEG = struct();
                    end
                    EEG.data = EEG_data;
                    clear EEG_data
                    EEG.pnts = size(EEG.data,2);
                    EEG.xmin = 0;
                    EEG.xmax = (EEG.pnts-1)/fs;
                    EEG.nbchan = size(EEG.data,1);
                    if exist('labels','var')
                        EEG.chanlocs = struct('labels',labels);
                    else
                        fprintf('Labels not found.\n Generating auto labels. \n\n')
                        EEG.chanlocs = struct('labels',convertStringsToChars(string(num2cell(1:EEG.nbchan))));
                    end
                    EEG.times = 1:size(EEG.data,2);
                    EEG.trials = 1;
                    EEG.srate = fs;
                else
                    error('EEG is empty.')
                end
            otherwise
                error('Unexpected error.') 
        end
    end
  
    % Validate window and trim signal
    if ~isempty(win)
        if win(2) > EEG.xmax 
            error('Invalid window: Upper limit greater than max sampled time. ')
        elseif win(1) < EEG.xmin 
            error('Invalid window: Lower limit lower than min sampled time.')
        elseif win(1) > win(2)
            error('Invalid window: Lower limit greater than upper limit.')
        end
    else
        win = [EEG.xmin EEG.xmax];
        fprintf('Window not specified. Plotting full signal.\n\n')
    end  
    try
        EEG = pop_select(EEG,'time',win);           
    catch
        start_EEG = (win(1)*EEG.srate) + 1;
        end_EEG = (win(2)*EEG.srate) + 1;
        EEG.data = EEG.data(:,start_EEG:end_EEG);
        EEG.pnts = size(EEG.data,2);
        EEG.times = (1000/EEG.srate)*((1:size(EEG.data,2))-1);
        EEG.xmin = 0;
        EEG.xmax = win(2) - win(1);
    end
    
    % Set scale
    n = EEG.nbchan;
    if exist('scale','var')
        k = -scale;             % <----------------| K value assigned.
    else                                         % |    
        rans = zeros(n,1);                       % |    
        for i = 1:n                              % |
            rans(i) = range(EEG.data(i,:));      % |
        end                                      % |
        ran = mean(rans);       %                  | 
        k = -ran;               % <----------------| K value adjusted.
    end                         % 

    % Add offset to EEG signal
    for i = 1:n
        EEG.data(i,:) = EEG.data(i,:) + k*i;
    end
    EEG.data = EEG.data - k*n;
       
    % Start generating the figure 
    % To plot:
    %   - in app.UIAxes set 'target' argument in callback function.
    %   - multiple stacked plots in single figure use tiledlayout in 
    %     caller code.
    if exist('target','var')
        if ~isa(target,'matlab.graphics.axis.Axes')
            ax = gca;
        else
            ax = target;
        end
    elseif exist('tile','var')
        nexttile(tile)
    else
        ax = gca;
    end
  
    t = EEG.xmax*((0:length(EEG.times)-1)/length(EEG.times));
    t = repmat(t,n,1)';
    t = t + win(1);
    
    if exist('ref','var')
        no_ref = setdiff(1:EEG.nbchan,ref);
    end

    if exist('lw','var')
        linewidth = lw;
    else
        linewidth = 1;
    end

    % Check which style to plot
    hold(ax,'on')
    if exist('color','var') && exist('ref','var') % Color + ref
        all = plot(ax,t(:,no_ref),EEG.data(no_ref,:)','Color',color,'LineWidth',linewidth);
        
        % if for some reason you want all the channels to be dimed
        try
            new_col = all.Color;
        catch
            solution = plot(ax,win(1),50,'color',color);
            new_col = solution.Color;
        end
        new_col = [new_col 0.1];
        plot(ax,t(:,ref),EEG.data(ref,:)','Color',new_col,'LineWidth',linewidth); 

    elseif exist('color','var') && ~exist('ref','var') % Only Color
        plot(ax,t(:,:),EEG.data(:,:)','Color',color,'LineWidth',linewidth)
        
    elseif ~exist('color','var') && exist('ref','var') % Only ref
        plot(ax,t(:,no_ref),EEG.data(no_ref,:)','LineWidth',linewidth)
        gg = repmat(colororder('default'),ceil(n/7),1);
        gg(:,4) = 0.1;
        for i = ref; plot(ax,t(:,i),EEG.data(i,:),'Color',gg(i,:),'LineWidth',linewidth); end

    else % No color + no ref, default.
        plot(ax,t,EEG.data','LineWidth',linewidth)
    end
    hold(ax,'off')
    
    % Add title and labels
    title(ax,"dcaro stacked eeg plot. Window: [" + num2str(win(1)) + " - " + num2str(win(2)) + "]s")
    xlim(ax,[-inf inf])
    xlabel(ax,'Time (s)')
    ylabel(ax,'Channel')
    v_ticks = 0:-k:-k*(n-1);
    yticks(ax,v_ticks)
    yticklabels(ax,flip({EEG.chanlocs.labels}))
    ylim(ax,[min(v_ticks)+k max(v_ticks)-k])
    
    % Add scale bar
    if exist('scale','var')
        len = scale;
    else                        %          | Auto scale to smallest factor 
        len = 50*ceil(ran/50);  % <--------| of 50 greater than ran.
    end

    msg = num2str(len) + " µV";
    if exist('scalecol','var')
        line(ax,[win(2) win(2)],[v_ticks(end-1) v_ticks(end-1)+len],'LineWidth',3,'Color',scalecol)
        text(ax,win(2) + 0.01*range(win),v_ticks(end-1)+len/2,msg,'Color',scalecol)
    else
        line(ax,[win(2) win(2)],[v_ticks(end-1) v_ticks(end-1)+len],'LineWidth',3,'Color','k')
        text(ax,win(2) + 0.01*range(win),v_ticks(end-1)+len/2,msg,'Color','k')
    end
end

% Aux. function to store arguments as variables
function save_args(name,value)
   assignin('caller',name,value)
end
