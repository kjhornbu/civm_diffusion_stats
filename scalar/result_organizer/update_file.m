function update_file(current,file_dest,log_inkey,log_outkey)
%% add entries to mapping error detection logs.
log_entry(current,file_dest,log_inkey,log_outkey);

%% check if done, and copy if not.
if file_time_check(file_dest,'new',current)
    % data ready, do nothing, even though this
    % empty looks funny this is on purpose for
    % branch prediction. (historical testing showed
    % this was a useful optimization, not validated on current matlab version.)
    fprintf('');
else
    % i think file_time_check is ... dumb,
    % The SECOND file must exist! This makes some logic non-obvious.
    % I should adjust it to better handle files
    % which should be present and files which should
    % not.
    %
    copyfile(current,file_dest);
end
end