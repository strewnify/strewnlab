function strewnmail(message,to_mail,subject,priority)
% STREWNMAIL

% Disable table row assignment warning
warning('off','MATLAB:table:RowsAddedExistingVars');

% Get timestamp
nowtime_utc = datetime('now','TimeZone','UTC');

if nargin > 0
    % Convert strings to char
    to_mail = convertStringsToChars(to_mail);

    % MATLAB Email Settings
    from_mail ='autonotify@strewnlab.com'; 
    setpref('Internet','SMTP_Server','mail.strewnlab.com');
    setpref('Internet','E_mail',from_mail);
    setpref('Internet','SMTP_Username',from_mail);
    setpref('Internet','SMTP_Password',getPrivate('strewnlab_emailpassword'));
    setpref('Internet','E_mail_Charset','UTF-8');
    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.starttls.enable','true');
    props.setProperty('mail.smtp.socketFactory.port','465');
    props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
    props.setProperty('transport.mail.ContentType','application/xml');
end

% StrewnLAB Email settings
emails_per_period = 40;
queue_period_hr = 1;
warn_size = 2 * emails_per_period;
log_size_cut = 2000;

% Load email queue
if isfile('email_queue.mat')
    load email_queue
    save('email_queue_backup.mat','db_email_*')
else
    db_email_lastsent_utc = datetime(1980,01,01,'TimeZone','UTC');
    db_email_log = table;
    db_email_queue = table;
end 
queue_size = size(db_email_queue,1);
log_size = size(db_email_log,1);
log_i = log_size + 1;
time_since_send_hrs = hours(nowtime_utc - db_email_lastsent_utc);

% If email log is full, cut it in half
if log_size > log_size_cut
    db_email_log = db_email_log((end-(log_size_cut/2)):end,:);
end

% Load message to the end of the queue
if nargin > 0
    email_i = queue_size + 1;
    db_email_queue.datetime_queued(email_i) = nowtime_utc;
    db_email_queue.message(email_i) = {message};
    db_email_queue.to_mail(email_i) = {to_mail};
    db_email_queue.subject(email_i) = {subject};
    db_email_queue.priority(email_i) = priority;
end

% Sort the queue
db_email_queue = sortrows(db_email_queue,'priority');

% If time since last send is greater than the queue period, send some emails
send_count = 0;
if time_since_send_hrs > queue_period_hr
    
    % Log the time of sending
    db_email_lastsent_utc = nowtime_utc;
    
    % If email queue is getting full, send a warning to the webmaster
    if queue_size > warn_size
        ErrorMsg = sprintf('Email queue contains more than %0.0f emails!',queue_size); 
        sendmail(getConfig('webmaster'), 'Email Queue Warning', ErrorMsg);
    end
    
    % Send the first messages in the queue
    while size(db_email_queue,1) > 0 && send_count < emails_per_period
        try
            % Send the email
            sendmail(db_email_queue.to_mail{1},db_email_queue.subject{1},db_email_queue.message{1})
            send_count = send_count + 1;
            logformat(['Email sent to ' db_email_queue.to_mail{1} '.'],'EMAIL')
            
            % Log the email
            db_email_log.sent_utc(log_i) = nowtime_utc;
            db_email_log.message(log_i) = db_email_queue.message(1);
            db_email_log.to_mail(log_i) = db_email_queue.to_mail(1);
            db_email_log.subject(log_i) = db_email_queue.subject(1);
            log_i = log_i + 1;
            
            %Delete from queue
            db_email_queue(1,:) = [];           
            
        catch
            
            % Move the failed email to the end of the queue
            db_email_queue.priority(1) = inf;
            db_email_queue(end+1,:) = db_email_queue(1,:);
            db_email_queue(1,:) = [];
            
            % Email the webmaster
            ErrorMsg = sprintf('Failed to send email to %s.  Email moved to end of queue.',db_email_queue.to_mail{1}); 
            sendmail(getConfig('webmaster'), 'Email Failed to Send', ErrorMsg);
        end
        
    end
end

save('email_queue.mat','db_email_*')

