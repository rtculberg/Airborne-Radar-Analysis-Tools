%--------------------------------------------------------------------------
% Author: Riley Culberg
% Date: 1/1/2021
%
% This scripts reads in data from a HiCARS OIB NetCDF file and writes the
% data to the same data structure used by the CReSIS OIB files. It both
% returns this data structure and writes it to a .mat file.
% 
% Inputs:
%   filename [string] - full path to HiCARS NetCDF file
%   out_dir [string] - full path to the directory where the .mat file
%   should be save
%
% Outputs:
%   data - radar data structure matching the format used by CReSIS
%       .Latitude [1xN double vector] - latitude [decimal degrees]
%       .Longitude [1xN double vector] - longitude [decimal degrees]
%       .Elevation [Mx1 double vector] - altitude above sea level (WGS84) [m]
%       .Roll [Mx1 double vector] - aircraft roll [degrees]
%           - Positive is right wing up.
%       .Pitch [Mx1 double vector] - aircraft roll [degrees]
%       .Heading [Mx1 double vector] - aircraft heading [degrees]
%           - Positive is clockwise from above, 0 is true north
%       .GPS_time [Mx1 double vector] - seconds since 00:00:00 on flight
%        day [s]
%       .Surface [Mx1 double vector] - two-way travel time to surface [s]
%       .Bottom [Mx1 double vector] - two way travel time to bed [s]
%       .Data_Low_Gain [MxN double vector] - radar returned power from high 
%        gain channel [linear power units]
%       .Data_High_Gain [MxN double vector] - radar returned power from high 
%        gain channel [linear power units]
%       .Time [Mx1 double vector] - fast time axis [s]
%     	.params = params;
%           .Instrument [string] - name of radar instrument
%           .CenterFrequency [double] - center frequency of chirp [Hz]
%           .F1 [double] - start frequency of chirp [Hz]
%           .F2 [double] - end frequency of chirp [Hz]
%           .PRF [double] - pulse repetition frequency [Hz]
%           .PulseLength [double] - pulse length [s]
%           .HiGain [double] - high gain channel gain [dB]
%           .LoGain [double] - low gain channel gain [dB]
%           .SamplingRate [double] - fast time sampling rate [Hz]
%           .OnboardStacks [double] - number of onboard coherent sums
%           .TXDelay [double] - offset between start of fast time axis and
%            signal transmission
%           .CoherentSums [double] - number of post-processing coherent
%            sums
%           .IncoherentSums [double] - number of post-processing incoherent
%            sums 
%
% Functional Dependencies:
%   HiCARS_ParseMetadata.m
%--------------------------------------------------------------------------

function data = HiCARS_ReadData(filename, out_dir)
    
    % Allocate data structure to fill
    Latitude = [];
    Longitude = [];
    Elevation = [];
    Roll = [];
    Pitch = [];
    Heading = [];
    GPS_time = [];
    Surface = [];
    Bottom = [];
    Data_Low_Gain = [];
    Data_High_Gain = [];
    Time = [];
    params = [];

    parameters = ncinfo(filename);
    
    % Write existing variables to new data structure
    for k = 1:length(parameters.Variables)
        switch parameters.Variables(k).Name
            case 'time'
                GPS_time = ncread(filename, 'time');
            case 'fasttime'
                Time = 1e-6*ncread(filename, 'fasttime');
            case 'lat'
                Latitude = ncread(filename, 'lat');
            case 'lon'
                Longitude = ncread(filename, 'lon');
            case 'altitude'
                Elevation = ncread(filename, 'altitude');
            case 'pitch'
                Pitch = ncread(filename, 'pitch');
            case 'roll'
                Roll = ncread(filename, 'roll');
            case 'heading'
                Heading = ncread(filename, 'heading');
            case 'amplitude_low_gain'
                Data_Low_Gain= 10.^(ncread(filename, 'amplitude_low_gain')./10);
            case 'amplitude_high_gain'
                Data_High_Gain= 10.^(ncread(filename, 'amplitude_high_gain')./10);
            otherwise
                fprintf('Extra variable %s not written to output data.\n', parameters.Variables(k).name);
        end
    end
    
    % Parse radar and processing parameters from NetCDF text fields
    params = HiCARS_ParseMetadata(parameters);
    
    % Save reformatted data
    out_file = strcat(out_dir, parameters.Attributes(8).Value, '.mat');
    save(out_file, 'Latitude', 'Longitude', 'Elevation', 'Roll', 'Pitch', ...
         'Heading', 'GPS_time', 'Surface', 'Bottom', 'Data_Low_Gain', ...
         'Data_High_Gain', 'Time', 'params');
    
    % Return reformatted data
    data.Latitude = Latitude;
    data.Longitude = Longitude;
    data.Elevation = Elevation;
    data.Roll = Roll;
    data.Pitch = Pitch;
    data.Heading = Heading;
    data.GPS_time = GPS_time;
    data.Surface = Surface;
    data.Bottom = Bottom;
    data.Data_Low_Gain = Data_Low_Gain;
    data.Data_High_Gain = Data_High_Gain;
    data.Time = Time;
    data.params = params;
end

