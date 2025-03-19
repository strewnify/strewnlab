function [newstring] = validplace(placestring,placenames,abbrev)
%VALIDPLACE looks for a single valid place name or abbreviation in a string, and
%returns the corrected place name

cnt = 0;

% Check for full names
for idx = 1:size(placenames,1)
    clear test
    test = strfind(placestring,placenames{idx,1});
    if ~isempty(test)
        cnt = cnt + 1;
        matchlib(cnt) = idx;
        old = placenames{idx,1};
    end    
end

% Check for abbreviations
for idx = 1:size(placenames,1)
    clear test
    test = strfind(placestring,placenames{idx,2});
    if ~isempty(test)
        cnt = cnt + 1;
        matchlib(cnt) = idx;
        old = placenames{idx,2};
    end    
end

% Choose output format
if abbrev
    name_col = 2;
else
    name_col = 1;
end

% Save place name
if (cnt == 1)
    new = placenames{matchlib,name_col};
    newstring = strrep(placestring,old,new);
else
    newstring = placestring; 
end


