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

% Cyrillic letters that look like Latin letters
% (not all Cyrillic letters supported!)
s = regexprep(s,char(1040),'A');
s = regexprep(s,char(1042),'B');
s = regexprep(s,char(1057),'C');
s = regexprep(s,char(1053),'H');
s = regexprep(s,char(1032),'J');
s = regexprep(s,char(1050),'K');
s = regexprep(s,char(1052),'M');
s = regexprep(s,char(1054),'O');
s = regexprep(s,char(1056),'P');
s = regexprep(s,char(1029),'S');
s = regexprep(s,char(1058),'T');
s = regexprep(s,char(1061),'X');
s = regexprep(s,char(1072),'a');
s = regexprep(s,char(1089),'c');
s = regexprep(s,char(1077),'e');
s = regexprep(s,char(1086),'o');
s = regexprep(s,char(1088),'p');
s = regexprep(s,char(1093),'x');
s = regexprep(s,char(1091),'y');

% return cleaned string
clean_s = s;
end

