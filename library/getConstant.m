function [constantValue] = getConstant(constantName)
    % GETCONSTANT Retrieve a physical constant

    % Physical constants are defined within the function
    switch constantName
        
        % Gravitational constant 'G'
        case 'G_constant'
            constantValue = 6.67430e-11;  % m^3 kg^-1 s^-2
        
        % Speed of light 'c'
        case 'c_mps'
            constantValue = 299792458;  % meters per second
        
        % Avogadro constant
        case 'Avogadro'
            constantValue = 6.02214076e23; % particles per mole
            
        % Planck constant 'h'
        case 'Planck_Js'
            constantValue = 6.62607015e-34;  % Joule second
            
        % Add other cases for additional constants
        otherwise
            error('Constant "%s" not found.', constantName);
    end
end