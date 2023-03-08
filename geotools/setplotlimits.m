function axis_array = setplotlimits(longdata, latdata, pct_buffer)  
% AXIS_ARRAY = SETPLOTLIMITS( LONGDATA , LATDATA , PCT_BUFFER )  Set plot limits.
%     Calculates latitude and longitude limits from latitude and longitude data.
%     AXIS_ARRAY = [ MINLONG , MAXLONG , MINLAT , MAXLAT ]
%     pct_buffer = [ left, right, bottom, top ]

% precision of rounding
coor_prec = 2;

% find plot limits
minlat = min(latdata);
maxlat = max(latdata); 
minlong = min(longdata);
maxlong = max(longdata);

% find plot center
meanlat = 0.5 * (minlat + maxlat);
meanlong = 0.5 * (minlong + maxlong);

% calculate plot size
dlat = 0.5 * (maxlat - minlat);
dlong = 0.5 * (maxlong - minlong);

% set buffer multipliers
mult = pct_buffer .* 0.01 + 1;

% set plot limits

minlong = rounddown(meanlong - dlong * mult(1),coor_prec);
maxlong = roundup(meanlong + dlong * mult(2),coor_prec);
minlat = rounddown(meanlat - dlat * mult(3),coor_prec);
maxlat = roundup(meanlat + dlat * mult(4),coor_prec);

% return array
axis_array = [ minlong maxlong minlat maxlat ];


    function up = roundup(a,prec_up)
        up = ceil(a*10^prec_up)/10^prec_up;
    end

    function down = rounddown(b,prec_down)
        down = floor(b*10^prec_down)/10^prec_down;
    end

end