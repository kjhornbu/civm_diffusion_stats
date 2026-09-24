function log_entry(in_filepath,out_filepath,log_inkey,log_outkey)
if ~ log_outkey.isKey(out_filepath)
    log_outkey(out_filepath)={in_filepath};
else
    C=log_outkey(out_filepath);
    if ~ ismember(in_filepath,C)
        C{end+1}=in_filepath;
        log_outkey(out_filepath)=C;
    end
end
if ~ log_inkey.isKey(in_filepath)
    log_inkey(in_filepath)={out_filepath};
else
    C=log_inkey(in_filepath);
    if ~ ismember(out_filepath,C)
        C{end+1}=out_filepath;
        log_inkey(in_filepath)=C;
    end
end
end