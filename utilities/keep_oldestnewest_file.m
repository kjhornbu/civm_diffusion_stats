function [file_keepOLD,file_keepNEW] = keep_oldestnewest_file(file1)
% Finds the oldest and newest files from a list of file names for date of
% execution checking.

% Get information from all files
temp_info=cellfun(@dir, file1,'UniformOutput',false);
info_test=vertcat(temp_info{:});

if isempty(info_test)
    warning('You have passed a list of files where none of them exist... are you sure you want to do that');
    %keyboard;
else
    first_entry_path=fullfile(info_test(1).folder,info_test(1).name);

    info_keepOLD=dir(first_entry_path);
    info_keepNEW=dir(first_entry_path);

    file_keepOLD=fullfile(info_keepOLD.folder,info_keepOLD.name);
    file_keepNEW=fullfile(info_keepNEW.folder,info_keepNEW.name);
end

for current_info_test=info_test
    %OLDEST file
    if ~isempty(current_info_test) && ~isempty(info_keepOLD) && (current_info_test.datenum < info_keepOLD.datenum)
        file_keepOLD=fullfile(current_info_test.folder,current_info_test.name);
        info_keepOLD=current_info_test;
    end

    %NEWEST file
    if ~isempty(current_info_test) && ~isempty(info_keepNEW) && (current_info_test.datenum > info_keepNEW.datenum)
        file_keepNEW=fullfile(current_info_test.folder,current_info_test.name);
        info_keepNEW=current_info_test;
    end

end
end