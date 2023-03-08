function [mass_string] = stringmass(mass_kg)
%STRINGMASS Creates a reader-friendly mass string, in appropriate units.

for i = 1:numel(mass_kg)
    
    magnitude = floor(log(mass_kg(i)) / log(1000));
    
    if mass_kg(i) == 0
               mass_string{i} = '0g';
    else
        switch magnitude
            case -4
                mass_string{i} = num2str(mass_kg(i)*1000000000,'%.3Gng');
            case -3
                mass_string{i} = num2str(mass_kg(i)*1000000000,'%.3Gug');
            case -2
                mass_string{i} = num2str(mass_kg(i)*1000000,'%.3Gmg');
            case -1
                mass_string{i} = num2str(mass_kg(i)*1000,'%.3Gg');
            case 0
                mass_string{i} = num2str(mass_kg(i),'%.3Gkg');
            case 1
                mass_string{i} = num2str(mass_kg(i)/1000,'%.3Gtonne');
            case 2
                mass_string{i} = num2str(mass_kg(i)/1000000,'%.3Gkt');
            case 3
                mass_string{i} = num2str(mass_kg(i)/1000000000,'%.3GMT');
            case 4
                mass_string{i} = num2str(mass_kg(i)/1000000000000,'%.3GGT');    
            otherwise
                warning('unknown magnitude in STRINGMASS')
                mass_string{i} = num2str(mass_kg(i),'%.3Gkg');
        end
    end
end

