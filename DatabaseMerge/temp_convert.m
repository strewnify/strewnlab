for i = 1:size(StrewnifyDatabase,1)
    StrewnifyDatabase.EventID(i) = {eventidcalc(StrewnifyDatabase.LAT(i),StrewnifyDatabase.LONG(i),StrewnifyDatabase.Datetime(i))};
end