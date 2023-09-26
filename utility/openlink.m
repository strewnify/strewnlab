function [success] = openlink(Hyperlink)
%OPENLINK Open a web browser to an address

try
    system(['start ' Hyperlink]);
    success = true;
catch
    success = false;
end

