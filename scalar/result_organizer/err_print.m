function err_print(f_map,err_idx,value_type)
if strcmp(value_type,'output')
    char='->';
elseif strcmp(value_type,'input')
    char='<-';
else
    warning('failure');
    keyboard;
end
kys=f_map.keys();
kys=kys(err_idx);
for k=kys
    mf=f_map(uncell(k));
    fprintf('%s\n',uncell(k));
    if 1 < numel(mf)
        fprintf('\t%s ERR extra %s:\n\t', char, value_type);
        fprintf('  %s\n',strjoin(mf,'\n\t'));
    else
        fprintf('\t%s  %s\n', char, strjoin(mf,'\n\t'));
        % this is an error becuase i only expect to be printing error
        % conditions.
        error('error on error print, you muppet.');
    end
end
end