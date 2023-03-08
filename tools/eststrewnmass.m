function [predicted_strewnmass] = eststrewnmass(mass,velocity,ablationheat, HTC)
% [PREDICTEDMASS] = ESTSTREWNMASS(MASS, VELOCITY, ABLATIONHEAT, HTC)

coef = HTC./(4.*0.5);
mass_fraction = 1./exp((coef.*velocity.^2)/ablationheat);
predicted_strewnmass = mass * mass_fraction;

end

