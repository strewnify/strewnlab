for i = 1:3587
    if strlength(StrewnifyDatabase.HyperMap(i)) >5 
        StrewnifyDatabase.HyperMap(i) =  {StrewnifyDatabase.HyperMap{i}(13:61)};
    end  
end