function abuse = preventAbuse(minTime_s, maxCallsAllowed)
    % preventAbuse - Prevent a function from being called repeatedly in a
    % loop.  Rate limiting is applied, if the time between calls is too short.
    %
    % Usage: Call this function inside any function you want to protect.
    % minTime_s:   minimum time in seconds, between calls, for rate limiting
    % maxCallsAllowed: max number of allowed calls in a session
    %
    % This function uses persistent variables and the call stack
    % to determine if the enclosing function is called too frequently.
    %
    % To reset this function, command 'clear preventAbuse'

    persistent lastCallTimes;
    persistent callCounts;
    abuse = false;
    
    if isempty(lastCallTimes)
        lastCallTimes = struct();
        callCounts = struct();
    end

    % Get the name of the calling function
    stack = dbstack(1); % 1 means get the caller of preventCost
    if isempty(stack)
        error('preventCost must be called from within a function.');
    end
    callerName = stack(1).name;

    % Initialize the caller's data if it does not exist
    if ~isfield(lastCallTimes, callerName)
        lastCallTimes.(callerName) = tic; % Start the timer
        callCounts.(callerName) = 0;      % Initialize call count
    else
        % Time since last call
        timeSinceLastCall = toc(lastCallTimes.(callerName));

        % Update the timestamp and increment call count
        lastCallTimes.(callerName) = tic; % Restart the timer
        callCounts.(callerName) = callCounts.(callerName) + 1;

        % Check if the function is being called too frequently
        if timeSinceLastCall < minTime_s
            
            % Pause until minimum time is met
            logformat(sprintf('%s rate limited to once every %i seconds', callerName, minTime_s),'INFO')
            countdown = ceil(minTime_s - timeSinceLastCall);
            
            % Display a countdown in the console
            if countdown > 5
                for t = countdown:-5:1
                    logformat(sprintf('Resuming in %d seconds...', t),'INFO');
                    pause(5);
                end
            else
                logformat(sprintf('Resuming in %d seconds...', countdown),'INFO');
                pause(countdown);
            end
                                    
        % If the max number of calls for the session occurred
        elseif callCounts.(callerName) > maxCallsAllowed
            if getSession('state','userpresent')
                continue_abuse = questdlg(sprintf('%s has exceeded abuse protection limits, continue?', callerName),'Abuse Prevention','Yes','No','No');
            else
                continue_abuse = 'No';
            end
            
            if strcmp(continue_abuse,'No')
                abuse = true;
                logformat(sprintf('%s has exceeded abuse protection limits', callerName),'ERROR');
            end            
        end
    end
end
