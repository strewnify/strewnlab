function rockID = generateRockID()
% Generates a random hash value to uniquely identify a simulated rock
    rockID = string(DataHash(datenum(now)*rand));
end
