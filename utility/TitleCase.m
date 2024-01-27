function titleCaseString = TitleCase(inputString)
    % TOTITLECASE Convert a string to title case
    
    % Define a list of words to exclude from capitalization
    exclusionList = {'the' 'a' 'and' 'or' 'but' 'in' 'on' 'of' 'to' 'with' 'at' 'by' 'for' 'nor' 'is' ...
        'mg' 'g' 'kg' 'mi' 'm' 'cm' 'km' 'ml' 'l' 'mW' 'kW'};

    % Split the input string into words
    words = strsplit(inputString, ' ');

    % Always capitalize the first word
    words{1} = [upper(words{1}(1)), words{1}(2:end)];
    
    % For the rest of the string, capitalize the first letter of each word, excluding certain words
    for i = 2:length(words)
        % Preserve the case if the word is already capitalized
        if ~any(strcmp(words{i}, exclusionList))
            if ~isstrprop(words{i}(1), 'upper')  % Check if the first letter is not already uppercase
                words{i} = [upper(words{i}(1)), words{i}(2:end)];
            end
        else
            words{i} = lower(words{i});
        end
    end

    % Join the words back into a single string
    titleCaseString = strjoin(words, ' ');
end