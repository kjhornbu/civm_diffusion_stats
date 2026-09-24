function log_save(fid,f_map,value_type)

kys=f_map.keys();
if strcmp(value_type,'output')
    char='->';
elseif strcmp(value_type,'input')
    char='<-';
else
    warning('failure');
    keyboard;
end
for k=kys
    mf=f_map(uncell(k));
    fprintf(fid,'%s\n',uncell(k));
    if 1 == numel(mf)
        fprintf(fid,'\t%s  %s\n', char, strjoin(mf,'\n\t'));
    else
        fprintf(fid,'\t%s ERR extra %s:\n', char, value_type);
        fprintf('\t  %s\n',strjoin(mf,'\n\t'));
    end
end
end