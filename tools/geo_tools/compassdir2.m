function [ direction ] = compassdir2( azimuth )
% [DIRECTION] = COMPASSDIR(AZIMUTH) Converts azimuth in degrees to 8-point 
% compass rose direction

%initialize compass direction to default
direction = '';

bin = -22.5:45:382.5;
points = [{'north'} {'northeast'} {'east'} {'southeast'} {'south'} {'southwest'} {'west'} {'northwest'} {'north'}]; 
for i = 1:9
    if azimuth >= bin(i) && azimuth < bin(i+1)
        direction = points{i};
        return
    end
end

