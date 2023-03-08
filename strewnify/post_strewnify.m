function [response] = post_strewnify(body)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% Load API key
loadprivate

StrewnifyURL = 'https://www.strewnify.com/wp-json/wp/v2/posts';

response = webwrite(StrewnifyURL,'login','autopost','password',Strewnify_APIkey,'title','test title 1','body','test body text 1','status','draft');
%    logformat(sprintf('%s %s - %s added to Mailchimp mailing list',firstname, lastname, email),'EMAIL')
% catch
%     response = -1;
%     logformat(sprintf('Failed to add %s %s - %s to Mailchimp mailing list',firstname, lastname, email),'DEBUG')
% end

% $login = 'misha';
% $password = '1HEu PFKe dnqM lr4j xDJX My63';
% 
% wp_remote_post(
% 		'https://WEBSITE-DOMAIN/wp-json/wp/v2/posts',
% 		array(
% 			'headers' => array(
% 				'Authorization' => 'Basic ' . base64_encode( "$login:$password" )
% 			),
% 			'body' => array(
% 				'title'   => 'My test',
% 				'status'  => 'draft',
% 			)
% 		)
% );
end

