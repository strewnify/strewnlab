function [nom_density, error_density, HTC, ablationheat, dot_mark] = materialprops(meteoroid_material)
%MATERIALPROPS Assign material properties
% density in kg/m^3
% heat transfer coefficient, for ablation simulation, unitless
% heat of ablation, in J/kg

switch lower(meteoroid_material)
    case 'stony'
        nom_density = 3230;
        error_density = 730;
        HTC = 0.1; 
        ablationheat = 8245000; 
        dot_mark = 'b.';
    case 'iron'
        nom_density = 7500;
        error_density = 500;
        HTC = 0.1; 
        ablationheat = 8010000; 
        dot_mark = 'r.';
    case 'stony-iron'
        nom_density = 4560;
        error_density = 330;
        HTC = 0.1; 
        ablationheat = 8170000; 
        dot_mark = 'm.';
    case 'carbonaceous'
        nom_density = 2640;
        error_density = 850;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'k.';
    case 'h chondrite'
        nom_density = 3300;
        error_density = 440;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'b.';
    case 'l chondrite'
        nom_density = 3400;
        error_density = 300;
        HTC = 0.1; 
        ablationheat = 7980000; 
        dot_mark = 'b.';
    case 'comet'
        nom_density = 900;
        error_density = 300;
        HTC = 0.1; % unknown
        ablationheat = 7980000; % unknown 
        dot_mark = 'b.';
    otherwise
        error('Invalid meteoroid material')
end

end

