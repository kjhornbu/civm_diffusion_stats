function [df] = clean_df_to_general_entries(group,subgroup,df)
%% assign group titles in order specified to dataframe
% Puts the original name as a description for ease of use
if size(group,2)>1

    nums=transpose(1:numel(group));
    numNumberColumns=ceil(numel(group)/10);
    format_specifier=sprintf('group%%0%ii ',numNumberColumns);
    indexed_group_names=list2cell(sprintf(format_specifier, nums));

    %indexed_group_names=char(strcat(repmat({'group'},size(group,2),1),num2str(transpose(1:size(group,2)))));
    for n=1:size(group,2)
        idx=regexpi(df.Properties.VariableNames,strcat('^(',group{n},')$'));
        idx_logical=~cellfun(@isempty,idx);
        position_idx=find(idx_logical==1);
        if numel(position_idx)
            df.Properties.VariableNames{position_idx(1)}=indexed_group_names{n};
            df.Properties.VariableDescriptions{position_idx(1)}=group{n};
            if iscell(df.(indexed_group_names{n}))
                df.(indexed_group_names{n})=regexprep(df.(indexed_group_names{n}),'[/\\]',''); %clean data so don't use reserved character
            end
        end
    end
else
    idx=regexpi(df.Properties.VariableNames,strcat('^(',strjoin(group,'|'),')$'));
    % *was* trying to maintain support for single group without number
    % input, BUT james broke it... we don't need this anymore we don't do
    % it in modern dataframes
    warning('James adjusted this code to return group1 in the case of one grouping variable. this may cause error');
    col_name='group1';
    df.Properties.VariableNames(~cellfun(@isempty,idx))={col_name}; 
    df.Properties.VariableDescriptions(~cellfun(@isempty,idx))=group;
    %df.(col_name)=regexprep(df.(col_name),'[/\\]','');
end

%% assign subgroup titles in order specified to dataframe

nums=transpose(1:numel(subgroup));
numNumberColumns=ceil(numel(subgroup)/10);
format_specifier=sprintf('subgroup%%0%ii ',numNumberColumns);
indexed_subgroup_names=list2cell(sprintf(format_specifier, nums));

%indexed_subgroup_names=char(strcat(repmat({'subgroup'},size(subgroup,2),1),num2str(transpose(1:size(subgroup,2)))));
for n=1:size(subgroup,2)
    idx=regexpi(df.Properties.VariableNames,strcat('^(',subgroup{n},')$'));
    idx_logical=~cellfun(@isempty,idx);
    position_idx=find(idx_logical==1);
    if numel(position_idx)
        df.Properties.VariableNames{position_idx(1)}=indexed_subgroup_names{n};
        df.Properties.VariableDescriptions{position_idx(1)}=subgroup{n};
        if iscell(df.(indexed_subgroup_names{n}))
            df.(indexed_subgroup_names{n})=regexprep(df.(indexed_subgroup_names{n}),'[/\\]',''); %clean data so don't use reserved character
        end

    end

end