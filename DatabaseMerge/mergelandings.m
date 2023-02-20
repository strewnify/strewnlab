for i = 1:size(AllLandings,1)
    switch AllLandings.fall(i)
        case "Fell"
            if isnan(AllLandings.year(i))
                AllLandings.EventID(i) = eventidcalc(AllLandings.LAT(i),AllLandings.LONG(i),NaT);
            else
                AllLandings.EventID(i) = eventidcalc(AllLandings.LAT(i),AllLandings.LONG(i),datetime(AllLandings.year(i),1,1,'TimeZone','UTC'));
            end
        case "Found"
            if isnan(AllLandings.year(i))
                AllLandings.EventID(i) = eventidcalc(AllLandings.LAT(i),AllLandings.LONG(i),NaT);
            else
                AllLandings.EventID(i) = eventidcalc(AllLandings.LAT(i),AllLandings.LONG(i),datetime(AllLandings.year(i),1,1,'TimeZone','UTC'));
            end
    end
end