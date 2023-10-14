function [reference] = getRef
%GETREF Get reference data, as defined at initialization
% The reference data is stored in a global struct, from the
% STREWN_INITIALIZE function.

global initialized
global ref_data

% Initialize, if necessary
if isempty(initialized) || ~initialized
    strewn_initialize
    logformat('Unexpected StrewnLAB initialization.','DEBUG')
    
% Check for unknown initialization error
elseif isempty(ref_data) || ~isfield(ref_data,'G_constant')        
    logformat('Unexpected missing ref data.','ERROR')    

end

% Store output
reference = ref_data;

end

