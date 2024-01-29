function strewnmail(message,to_mail,attachment)
% STREWNMAIL

% Convert strings to char
to_mail = convertStringsToChars(to_mail);

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

switch nargin
    case 2
        sendmail(to_mail,'Strewnify Automated Meteor Report',message)
        logformat(['Email sent to ' to_mail '.'],'EMAIL')
    case 3
        sendmail(to_mail,'Strewnify Automated Meteor Report',message,attachment)
        logformat(['Email sent to ' to_mail ', with attachment.'],'EMAIL')
    otherwise
        logformat(['Unexpected arguments in call to STREWNMAIL.'],'ERROR')
        error('Unexpected arguments!')
end
        
        
