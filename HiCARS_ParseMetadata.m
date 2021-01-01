%--------------------------------------------------------------------------
% Author: Riley Culberg
% Date: 1/1/2021
%
% This scripts uses regular expressions to parse the radar system and
% procressing parameters out of the NetCDF Attribute text fields. This
% function is called by HiCARS_ReadData.m.
% 
% Inputs:
%   parameters - data structure returned by ncread
%
% Outputs:
%   .meta
%       .Instrument [string] - name of radar instrument
%       .CenterFrequency [double] - center frequency of chirp [Hz]
%       .F1 [double] - start frequency of chirp [Hz]
%       .F2 [double] - end frequency of chirp [Hz]
%       .PRF [double] - pulse repetition frequency [Hz]
%       .PulseLength [double] - pulse length [s]
%       .HiGain [double] - high gain channel gain [dB]
%       .LoGain [double] - low gain channel gain [dB]
%       .SamplingRate [double] - fast time sampling rate [Hz]
%       .OnboardStacks [double] - number of onboard coherent sums
%       .TXDelay [double] - offset between start of fast time axis and
%        signal transmission
%       .CoherentSums [double] - number of post-processing coherent
%        sums
%       .IncoherentSums [double] - number of post-processing incoherent
%        sums 
%--------------------------------------------------------------------------

function meta = HiCARS_ParseMetadata(parameters)

    % Allocate data structure for parameters
    meta.Instrument = [];
    meta.CenterFrequency = [];
    meta.F1 = [];
    meta.F2 = [];
    meta.PRF = [];
    meta.PulseLength = [];
    meta.HiGain = [];
    meta.LoGain = [];
    meta.SamplingRate = [];
    meta.OnboardStacks = [];
    meta.TXDelay = [];
    meta.CoherentSums = [];
    meta.IncoherentSums = [];
    
    % Find the fields of interest in the NetCDF attributes
    indices = zeros(1,5);
    for k = 1:length(parameters.Attributes)
        switch parameters.Attributes(k).Name
            case 'instrument'
                indices(1) = k;
            case 'rfparams'
                indices(2) = k;
            case 'digital'
                indices(3) = k;
            case 'TX-record_offset'
                indices(4) = k;
            case 'processing'
                indices(5) = k;
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%% Instrument Name %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    meta.Instrument = parameters.Attributes(indices(1)).Value;
   
%%%%%%%%%%%%%%%%%%%%%%%%%%% RF Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Find center frequency
    [startIndex, endIndex] = regexp(parameters.Attributes(indices(2)).Value, '(Center Frequency:)\s\d{1,}[.]*\d*\s(MHz)');
    if isempty(startIndex)
        fprintf('No center frequency found.\n');
    else
        seg = parameters.Attributes(indices(2)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.CenterFrequency = 1e6*str2double(seg(startIndex:endIndex));
    end
    
    % Find bandwidth
    [startIndex, endIndex] = regexp(parameters.Attributes(indices(2)).Value, '(Chirp:)\s\d{1,}[.]*\d*\s(MHz)\s(to)\s\d{1,}[.]*\d*\s(MHz)');
    if isempty(startIndex)
        fprintf('No bandwidth found.\n');
    else
        seg = parameters.Attributes(indices(2)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.F1 = 1e6*str2double(seg(startIndex(1):endIndex(1)));
        meta.F2 = 1e6*str2double(seg(startIndex(2):endIndex(2)));
    end
    
    % Find the PRF
        [startIndex, endIndex] = regexp(parameters.Attributes(indices(2)).Value, '(PRF:)\s\d{1,}[.]*\d*\s(Hz)');
    if isempty(startIndex)
        fprintf('No PRF found.\n');
    else
        seg = parameters.Attributes(indices(2)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.PRF = str2double(seg(startIndex:endIndex));
    end
    
    % Find pulse length
    [startIndex, endIndex] = regexp(parameters.Attributes(indices(2)).Value, '\d{1,}[.]*\d*\s(microsecond)');
    if isempty(startIndex)
        fprintf('No PRF found.\n');
    else
        seg = parameters.Attributes(indices(2)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.PulseLength = 1e-6*str2double(seg(startIndex:endIndex));
    end
    
    % Find high gain
    [startIndex, endIndex] = regexp(parameters.Attributes(indices(2)).Value, '(high gain)\s(()\d{1,}[.]*\d*( dB)');
    if isempty(startIndex)
        fprintf('No high gain found.\n');
    else
        seg = parameters.Attributes(indices(2)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.HiGain = str2double(seg(startIndex:endIndex));
    end
   
    % Find low gain
    [startIndex, endIndex] = regexp(parameters.Attributes(indices(2)).Value, '(low gain)\s(()\d{1,}[.]*\d*( dB)');
    if isempty(startIndex)
        fprintf('No low gain found.\n');
    else
        seg = parameters.Attributes(indices(2)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.LoGain = str2double(seg(startIndex:endIndex));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%% Digital Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Find sampling rate
    [startIndex, endIndex] = regexp(parameters.Attributes(indices(3)).Value, '(Sample rate: )\d{1,}[.]*\d*( MHz)');
    if isempty(startIndex)
        fprintf('No sampling rate found.\n');
    else
        seg = parameters.Attributes(indices(3)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.SamplingRate = 1e6*str2double(seg(startIndex:endIndex));
    end
    
    % Find onboard stacking
    [startIndex, endIndex] = regexp(parameters.Attributes(indices(3)).Value, '\d{1,}[.]*\d*( onboard stacks)');
    if isempty(startIndex)
        fprintf('No onboard stacks found.\n');
    else
        seg = parameters.Attributes(indices(3)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.OnboardStacks = str2double(seg(startIndex:endIndex));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%% TX Offset Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Find TX delay
    [startIndex, endIndex] = regexp(parameters.Attributes(indices(4)).Value, '\d{1,}[.]*\d*( microseconds)');
    if isempty(startIndex)
        fprintf('No TX delay found.\n');
    else
        seg = parameters.Attributes(indices(4)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.TXDelay = 1e-6*str2double(seg(startIndex:endIndex));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%% Processing Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%

    % Find coherent sums
    [startIndex, endIndex] = regexp(parameters.Attributes(indices(5)).Value, '(Coherent stacking: )\d{1,}[.]*\d*');
    if isempty(startIndex)
        fprintf('No coherent sums found.\n');
    else
        seg = parameters.Attributes(indices(5)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.CoherentSums = str2double(seg(startIndex:endIndex));
    end
    
    % Find incoherent sums
    [startIndex, endIndex] = regexp(parameters.Attributes(indices(5)).Value, '(Incoherent averaging: )\d{1,}[.]*\d*');
    if isempty(startIndex)
        fprintf('No incoherent sums found.\n');
    else
        seg = parameters.Attributes(indices(5)).Value(startIndex:endIndex);
        [startIndex, endIndex] = regexp(seg, '\d{1,}[.]*\d*');
        meta.IncoherentSums = str2double(seg(startIndex:endIndex));
    end
    
end