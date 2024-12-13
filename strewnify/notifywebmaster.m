function notifywebmaster(yourMsg)
% Notify the webmaster of important information, via email
% Be careful modifying this function, as it could cause an infinite loop of
% emails, if LOGFORMAT is used and contains PREVENTABUSE, for example

% need to add protection for loop and excessive emails

    strewnmail(yourMsg,getConfig('webmaster'),'StrewnLAB Error',1)
