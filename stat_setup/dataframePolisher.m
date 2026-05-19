function [outputArg1,outputArg2] = dataframePolisher(inputArg1,inputArg2)

if found_stats
    missing_erode_stats_idx=false(height(dataFrame),1);
    % Because polishing is slow, we use parfor.
    % Due to limits of parfor, must pull out the relevant columns before
    % the loop.
    df_connectome_obj=dataFrame.connectome_obj;
    df_stat_path=dataFrame.stat_path;
    if found_e1stats
        df_stat_path_erode=dataFrame.stat_path_erode;
    else
        df_stat_path_erode=cell(size(df_stat_path));
    end

    stats_polisher_bulk(df_stat_path,df_stat_path_erode,df_connectome_obj)

    %% Validate polishing worked.
    for n=1:height(dataFrame)
        temp_connectome_data=dataFrame.connectome_obj{n};
        polished_stats=dataFrame.stat_path{n};
        % Have to use the newer check because if the file does not exist we
        % return false.
        have_stats_been_polished = ~isempty(temp_connectome_data) && file_time_check(polished_stats, 'newer', temp_connectome_data.stats );
        if ~found_e1stats
            stat_ready=have_stats_been_polished;
        else
            polished_e1stats=dataFrame.stat_path_erode{n};
            if ~isempty(temp_connectome_data) && ~isempty(temp_connectome_data.e1_stats)
                have_e1stats_polished = file_time_check(polished_e1stats, 'newer', temp_connectome_data.e1_stats );
            else
                missing_erode_stats_idx(n)=1;
                have_e1stats_polished=true; %just so we can pass through the check condition
            end
            stat_ready=(have_stats_been_polished+have_e1stats_polished)/2;
        end
        failures=failures+(1-stat_ready);
        if stat_ready < 1
            continue;
        end
        % if any labels were found, its presumed we're supposed to have
        % labels.
        if found_labels
            dataFrame.label_path{n}=temp_connectome_data.labels;
        end
    end
end

% remove connectome_obj from dataframe as it cannot be saved to spreadsheet.
dataFrame.connectome_obj=[];


%% drop data frame entries which were not populated,
% For the data cols, we will require all data files for any entry included.
% This loop marks which specimen are missing one of their data files.
data_cols=column_find(dataFrame,'^(stat_path|connectome_file)$',1);
missing_data_idx=zeros(height(dataFrame),1,'logical');
for col_name = dataFrame.Properties.VariableNames(data_cols)
    missing_data_idx=missing_data_idx|cellfun(@isempty,dataFrame.(uncell(col_name)));
end
% Remove all eroded stats if any are not found.
if found_e1stats && nnz(missing_erode_stats_idx)>0
    dataFrame=removevars(dataFrame,'stat_path_erode');
end
% If any data had labels, expect that all should have had labels.
% This marks specimen that are missing labelsd.
if found_labels
    missing_labels_idx=cellfun(@isempty,dataFrame.label_path);
    missing_data_idx=missing_data_idx|missing_labels_idx;
end
% Save the missing entries to the "missing" data fram to record clearly
% they were excluded for misisng data, then remove them.
[p,n,e]=fileparts(opts.dataframePath);
missing_path = fullfile(p,sprintf('MISSING_%s%s', n, e));
missing_frame=dataFrame(missing_data_idx,:);
if nnz(missing_data_idx) && opts.allowMissing==0
    warning('Not all entries found');
    disp(missing_frame);
    civm_write_table(missing_frame, missing_path);
    error('Not all entries found. Terminating Execution due to Missing Specimen. If you wish to continue with Missing Specimen, add optional input "allowMissing" as true');
elseif nnz(missing_data_idx) && opts.allowMissing==1
    warning('Not all entries found');
    disp(missing_frame);
    civm_write_table(missing_frame, missing_path);
    warning('Not all entries found, see above. Proceeding with Analysis!');
    pause(3);
elseif exist(missing_path,'file')
    delete(missing_path);
end
% fix any trailing issues with column headings, they MUST be struct field
% safe due to code choices made later.
dataFrame.Properties.VariableNames=matlab.lang.makeValidName(dataFrame.Properties.VariableNames);
% drop specimen which are missing data.
dataFrame=dataFrame(~missing_data_idx,:);

%% dataframe creation complete, save.
civm_write_table(dataFrame,opts.dataframePath);

end