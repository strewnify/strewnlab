function devwarning( file )
% DEVWARNING   Issues a warning to flag temporary changes in code.  This
% is to prevent forgotten changes which could have unintended consequences.
message = ['Temporary code change in effect in ' file '!']; 
warning(message)
msgbox(message)