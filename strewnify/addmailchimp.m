function response = addmailchimp(firstname, lastname, email)
    % Load API key
    loadprivate

    % Set Mailchimp API configuration
    serverPrefix = 'us4';  % Replace with your Mailchimp server prefix

    listId = 'd65ba3c975';  % Replace with your Mailchimp list ID

    % Add StrewnNotify tag to the request
    % Mailchimp has bad documentation on tags, it must be an array within an array
    tags = {{'StrewnNotify'}};
    
    
    MailchimpURL = ['https://' serverPrefix '.api.mailchimp.com/3.0/lists/' listId '/members'];

    % Set up webwrite options
    authHeader = ['apikey ' getPrivate('Mailchimp_APIkey')];
    webwriteOptions = weboptions('HeaderFields', {'Authorization', authHeader}, 'RequestMethod', 'post', 'ContentType', 'json');

    % Prepare data
    requestData = struct(...
        'email_address', email, ...
        'status', 'subscribed', ...
        'merge_fields', struct('FNAME', firstname, 'LNAME', lastname),...
        'tags', tags...
    );

    % Convert data to JSON
    jsonData = jsonencode(requestData);

    % Troubleshooting info
%     disp('Request Headers:');
%     disp(webwriteOptions.HeaderFields);
    
    % Make API request
%     try
        response = webwrite(MailchimpURL, jsonData, webwriteOptions);
        logformat(sprintf('%s %s - %s added to Mailchimp mailing list', firstname, lastname, email), 'EMAIL')
%     catch
%         response = -1;
%         logformat(sprintf('Failed to add %s %s - %s to Mailchimp mailing list',firstname, lastname, email),'DEBUG')
%     end
end
