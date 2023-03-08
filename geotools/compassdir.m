function [ direction ] = compassdir( azimuth )
% [DIRECTION] = COMPASSDIR(AZIMUTH) Converts azimuth in degrees to 16-point 
% compass rose direction

%initialize compass direction to default
direction = '';

bin = -11.25:22.5:371.25;
points = [{'N'} {'NNE'} {'NE'} {'ENE'} {'E'} {'ESE'} {'SE'} {'SSE'} {'S'} {'SSW'} {'SW'} {'WSW'} {'W'} {'WNW'} {'NW'} {'NNW'} {'N'}]; 
for i = 1:18
    if azimuth >= bin(i) && azimuth < bin(i+1)
        direction = points{i};
        return
    end
end

