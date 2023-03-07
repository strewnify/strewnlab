function [Datetime] = datedlg()
%DATEDLG Use a dialog box to allow the user to select a date

fig = uifigure('Position',[340 400 415 300]);
d = uidatepicker(fig,'DisplayFormat','MM-dd-yyyy',...
    'Position',[130 190 150 22],...
    'Value',datetime(2014,4,9),...
    'ValueChangedFcn', @datechange);

    function datechange (src,event)
        lastdate = char(event.PreviousValue);
        newdate = char(event.Value);
        msg = ['Change date from ' lastdate ' to ' newdate '?'];
        % Confirm new date
        selection = uiconfirm(fig,msg,'Confirm Date');
        
        if (strcmp(selection,'Cancel'))
            % Revert to previous selection if cancelled
            d.Value = event.PreviousValue;
        end
    end
end

