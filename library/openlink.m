function [success] = openlink(Hyperlink)
%OPENLINK Open a web browser to an address

try
    system(['start ' Hyperlink]);
    success = true;
    logformat(sprintf('Browser opened to %s',Hyperlink),'INFO')
catch
    success = false;
    logformat(sprintf('Browser failed to open to %s',Hyperlink),'DEBUG')
end

