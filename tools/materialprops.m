function [nom_density, error_density, HTC, ablationheat, dot_mark] = materialprops(meteoroid_material)
%MATERIALPROPS Assign material properties
% density in kg/m^3
% heat transfer coefficient, for ablation simulation, unitless
% heat of ablation, in J/kg
% Sources:
% D. T. Brittl (2004) - Meteorite Porosities and Densities: A Review of Trends in the Data
% 'random' material supports strewn mass estimation in PRINTTRAJECTORY


switch lower(meteoroid_material)
    case 'random'
        nom_density = 3380;
        error_density = 960;
        HTC = 0.1; 
        ablationheat = 8248100; 
        dot_mark = 'k.';
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
        dot_mark = 'g.';
    case 'comet'
        nom_density = 900;
        error_density = 300;
        HTC = 0.1; % unknown 
        ablationheat = 7980000; % unknown 
        dot_mark = 'c.';
    case 'h chondrite'
        nom_density = 3400;
        error_density = 180;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'b.';
    case 'l chondrite'
        nom_density = 3350;
        error_density = 160;
        HTC = 0.1; 
        ablationheat = 7980000; 
        dot_mark = 'b.';
    case 'll chondrite'
        nom_density = 3210;
        error_density = 220;
        HTC = 0.1; 
        ablationheat = 7980000; 
        dot_mark = 'b.';
    case 'eh chondrite'
        nom_density = 3720;
        error_density = 20;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'k.';
    case 'el chondrite'
        nom_density = 3550;
        error_density = 100;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'k.';
    case 'pallasite'
        nom_density = 4760;
        error_density = 100;
        HTC = 0.1; 
        ablationheat = 8010000; 
        dot_mark = 'r.';
    case 'mesosiderite'
        nom_density = 4250;
        error_density = 20;
        HTC = 0.1; 
        ablationheat = 8170000; 
        dot_mark = 'm.';
    case 'steinbach'
        nom_density = 4180;
        error_density = 100;
        HTC = 0.1; 
        ablationheat = 8010000; 
        dot_mark = 'r.';
    case 'diogenite'
        nom_density = 3260;
        error_density = 170;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'k.';
    case 'eucrite'
        nom_density = 2860;
        error_density = 700;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'k.';
    case 'howardite'
        nom_density = 3020;
        error_density = 190;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'k.';
    case 'shergottite'
        nom_density = 3100;
        error_density = 40;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'k.';
    case 'nahkla'
        nom_density = 3150;
        error_density = 70;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'k.';
    case 'ureilite'
        nom_density = 3050;
        error_density = 220;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'g.';
    case 'CI'
        nom_density = 2110;
        error_density = 200;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'g.';
    case 'CM'
        nom_density = 2120;
        error_density = 260;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'g.';
    case 'CR'
        nom_density = 3100;
        error_density = 120;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'g.';
    case 'CO'
        nom_density = 2950;
        error_density = 110;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'g.';
    case 'CV'
        nom_density = 2950;
        error_density = 260;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'g.';
    case 'aubrite'
        nom_density = 3120;
        error_density = 150;
        HTC = 0.1; 
        ablationheat = 8510000; 
        dot_mark = 'g.';
    case 'undiscovered-ld'
        nom_density = 1620;
        error_density = 600;
        HTC = 0.1; % unknown
        ablationheat = 7980000; % unknown 
        dot_mark = 'b.';
    case 'undiscovered-hd'
        nom_density = 15000;
        error_density = 7500;
        HTC = 0.1; % unknown
        ablationheat = 8010000; % unknown 
        dot_mark = 'b.';
    otherwise
        error('Invalid meteoroid material')
end

end

