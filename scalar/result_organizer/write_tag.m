function write_tag(fid, indent, tag, attrib, content)

fprintf(fid,'%s<%s\n', indent,tag);
%if ~exist('content','var')
%else
%    fprintf(fid,'%s<%s>\n', indent,tag);
%end
atr_indent='  ';
for atr=fieldnames(attrib)'
    atr=uncell(atr);
    fprintf(fid,'%s%s%s="%s"\n', indent, atr_indent, atr, attrib.(atr));
end
if ~exist('content','var')
    fprintf(fid,'%s/>\n',indent);
else
    fprintf(fid,'%s>', indent);
    fprintf(fid,'%s', content);
    fprintf(fid,'</%s>\n', tag);
end

