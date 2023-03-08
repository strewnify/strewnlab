function [response] = addmailchimp(firstname,lastname,email)
%[RESPONSE] = ADDMAILCHIMP(FIRSTNAME, LASTNAME, EMAIL) Summary of this function goes here
%   Detailed explanation goes here

% Load API key
loadprivate

MailchimpURL = 'https://us4.api.mailchimp.com/2.0/lists/subscribe';

try
    response = webwrite(MailchimpURL,'apikey',Mailchimp_APIkey,...
        'id','d65ba3c975','email[email]',email,'merge_vars[FNAME]',...
        firstname,'merge_vars[LNAME]',lastname,'double_optin','false');
    logformat(sprintf('%s %s - %s added to Mailchimp mailing list',firstname, lastname, email),'EMAIL')
catch
    response = -1;
    logformat(sprintf('Failed to add %s %s - %s to Mailchimp mailing list',firstname, lastname, email),'DEBUG')
end
    
% Developer note:  all attempts to add tags via API have failed.  Tried 
% json and csv array format susing weboptions and variouds char and string
% cell arrays and nested cell array.  Struct data format could potentially
% work, but the '['  characters are not allowed by matlab as struct 
% variable names

