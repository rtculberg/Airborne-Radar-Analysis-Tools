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
%--------------------------------------------------------------------------

function data = HiCARS_AdjustFastTime(data)
    
    % Subtract transmission delay time from fast time axis
    data.Time = data.Time - data.params.TXDelay;

end