function [mass] = A2mass(A_m2pkg, speed_mps)
%A2MASS Calculate entry mass range from deceleration coefficient A 
    
temperature_C = -40;  % negligable impact for entry speeds
speedsound = 20.05.*sqrt(temperature_C + 273.15);

% Assign distribution of meteoriod materials
% stony - 90%, iron - 4%, carbonaceous - 5%, stony-iron - 1%
possible_materials = [repmat({'stony'},1,90) repmat({'iron'},1,4) repmat({'carbonaceous'},1,5) repmat({'stony-iron'},1,1)];

for idx = 1:10000

    % Pick a random material, within distribution
    material = possible_materials{randi(size(possible_materials,2),1)};

    % Get materal properties
    [nom_density, error_density, ~, ~, ~] = materialprops(material);
    
    % Choose random density, within limits
    density = randbetween(nom_density - error_density, nom_density + error_density);
    
    % Pick random shape
    cubicity = randbetween(0, 1);
    
    % calculate drag coefficient
    machspeed = speed_mps./speedsound;
    CD = dragcoef(machspeed,cubicity);

    % Calculate mass range
    mass(idx) = (CD./A_m2pkg).^3 .* ((9.*pi)./(16.*density^2));
    
end

figure
hold on
histogram(mass,'Normalization','probability')
title(['Estimated Mass Range at Entry' newline 'Considering measurement error and expected material distribution'])
xlabel('Entry Mass, kg')
ylabel('Probability')

end

