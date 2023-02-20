% WARNING, THIS SCRIPT COULD COST MONEY!

user_continue = questdlg('This script uses an external API could cost money!','Warning','Continue','Cancel','Cancel');

switch user_continue
    case 'Continue'
        
        % Populate locations in the database
        for i = 1:size(StrewnifyDatabase,1)
            if ismember({'AMS'},StrewnifyDatabase.DataSource(i))
                StrewnifyDatabase.Location(i) = {getlocation(StrewnifyDatabase.LAT(i),StrewnifyDatabase.LONG(i))};
            end
            pause(0.03);
        end
    otherwise
        warning('Process cancelled by user.')
end