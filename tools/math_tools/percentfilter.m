function [filter_out] = percentfilter(filter_in, percent)
% PERCENTFILTER Remove a random percent of a filter
% 
% [FILTER_OUT] = REMOVEPERCENT(FILTER_IN, PERCENT) takes a logical filter 
% array and randomly falsifies some of the filter, leaving a percentage of
% the TRUE indicies remaining. 
%
% For example, to identify 80% of coordinates inside of a polygon, this 
% function could be used as follows:
% 
% data_in_polygon = inpolygon(data_lat, data_lon, poly_lat, poly_lon)
% data_in_polygon_80pct = percentfilter(data_in_polygon, 80) 

if isempty(filter_in)
    error('Filter is empty')
end
if isempty(percent)
    error('Percent is empty')
end
if percent < 1 || percent > 100
    error('Percent must be a number between 1 and 100')
end
if ~islogical(filter_in)
    error('Filter input not logical')
end

% Create a working copy
filter_out = filter_in;

% get the indicies of the trues
true_indices = find(filter_out);

% calculate the number of indices to remove
num_indices = round(length(true_indices) * (100-percent) * 0.01);

% generate a vector of random indices to remove
indices_to_remove = randperm(length(true_indices), num_indices);

% create a logical array indicating which indices were removed
filter_out(true_indices(indices_to_remove)) = false;
    
end

