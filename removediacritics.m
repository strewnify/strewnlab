function [clean_s] = removediacritics(s)
%REMOVEDIACRITICS Removes diacritics from text.
%   This function removes many common diacritics from strings, such as
%     á - the acute accent
%     à - the grave accent
%     â - the circumflex accent
%     ü - the diaeresis, or trema, or umlaut
%     ñ - the tilde
%     ç - the cedilla
%     å - the ring, or bolle
%     ø - the slash, or solidus, or virgule

% uppercase
s = regexprep(s,'(?:Á|À|Â|Ã|Ä|Å)','A');
s = regexprep(s,'(?:Æ)','AE');
s = regexprep(s,'(?:ß)','ss');
s = regexprep(s,'(?:Ç)','C');
s = regexprep(s,'(?:Ð)','D');
s = regexprep(s,'(?:É|È|Ê|Ë)','E');
s = regexprep(s,'(?:Í|Ì|Î|Ï)','I');
s = regexprep(s,'(?:Ñ)','N');
s = regexprep(s,'(?:Ó|Ò|Ô|Ö|Õ|Ø)','O');
s = regexprep(s,'(?:Œ)','OE');
s = regexprep(s,'(?:Ú|Ù|Û|Ü)','U');
s = regexprep(s,'(?:Ý|Ÿ)','Y');

% lowercase
s = regexprep(s,'(?:á|à|â|ä|ã|å)','a');
s = regexprep(s,'(?:æ)','ae');
s = regexprep(s,'(?:ç|?)','c');
s = regexprep(s,'(?:ð)','d');
s = regexprep(s,'(?:é|è|ê|ë)','e');
s = regexprep(s,'(?:?)','g');
s = regexprep(s,'(?:í|ì|î|ï)','i');
s = regexprep(s,'(?:?)','k');
s = regexprep(s,'(?:?)','l');
s = regexprep(s,'(?:ñ|?)','n');
s = regexprep(s,'(?:ó|ò|ô|ö|õ|ø)','o');
s = regexprep(s,'(?:œ)','oe');
s = regexprep(s,'(?:š)','s');
s = regexprep(s,'(?:ú|ù|ü|û)','u');
s = regexprep(s,'(?:ý|ÿ)','y');
s = regexprep(s,'(?:ž)','z');

% return cleaned string
clean_s = s;
end

