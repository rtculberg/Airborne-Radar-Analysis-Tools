%--------------------------------------------------------------------------
% Author: Riley Culberg
% Date: 1/1/2021
%
% This function adjusts the fast time axis to account for the system
% transmission delay. This function should be run before using the system
% fast time to calculate absolute ranges from the aircraft (for example,
% for calculating geometric spreading losses). 
% 
% Inputs:
%   data - radar data structure output by HiCARS_ReadData.m
%
% Outputs:
%   data - radar data structure output by HiCARS_ReadData.m
%       .Data [MxN double vector] - radar returned power from combined
%       channels [linear power units]
%--------------------------------------------------------------------------

function data = HiCARS_Calibrate_MergeChannels(data)

    % Calibrate the high and low gain channels by adding the gain offset to
    % the low gain channel
    offset = data.params.HiGain - data.params.LoGain;
    data.Data_Low_Gain = data.Data_Low_Gain*10.^(offset./10);
    
    % For 
    ilat = 1:1000:size(data.Data_Low_Gain,2);
    clip_ind = NaN*ones(size(data.Data_Low_Gain,2));
    for k = ilat
        % If the surface is tracked, use that location, otherwise use
        % location of max value in low gain data
        if ~isempty(data.Surface)
            surf = data.Surface(:,k);
        else
            [~, surf] = max(data.Data_Low_Gain(:,k));
        end
        % Splice the data at the point where the average high gain power
        % drops more than 3 dB below the low gain power
        difference = movmean(abs(10*log10(data.Data_Low_Gain(surf:end,k)) - 10*log10(data.Data_High_Gain(surf:end,k))),30);
        ind = find(difference > 3);
        ind2 = find(ind > 100);
        if ~isempty(ind2) && ~isempty(ind)
            clip_ind(k) = ind(ind2(1)) + surf - 1;
        end
    end
    
    % Number of fast time samples to back-off before splicing
    backset = 10;
    % Average fast time sample at which to splice channels
    mean_clip = round(nanmean(clip_ind));
    
    % Splice high and low gain channels 
    top = data.Data_Low_Gain(1:mean_clip - backset,:);
    bottom = data.Data_High_Gain(mean_clip - backset + 1:end,:);
    data.Data = vertcat(top,bottom);

end