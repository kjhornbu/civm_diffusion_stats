function [output,output_user_defined] = build_study_table(df,stat_sheet_column)
% function [output,output_user_defined] = build_study_table(df,stat_sheet_column)
% input: 
%   df: df of the study
%   stat_sheet_column: the stat sheet column to use
%
% output: 
%   output - the whole study in 1 table for the containing stats for all
%     study members. Stats are limited to the those available for all
%     members, so if a stat is missing for any of the members it will be 
%     omitted. 
%   output_user_defined - output but with names how the user orignally
%   defined them in the dataframe.

%% big_table=column2text(big_table,test_conditions);

sheets=cell(height(df),1);
columns=cell(height(df),1);
stat_sheet_paths=df.(stat_sheet_column);
specimen_name=df.specimen;

parfor member_num=1:height(df)
    %get the path for the stat sheet
    indiv_stat_path=stat_sheet_paths{member_num};
    indiv_specimen_name=specimen_name{member_num};

    %load up the data and add the statpath to the single sheet
    single_sheet=civm_read_table(indiv_stat_path);
    single_sheet.specimen=repmat({indiv_specimen_name},[height(single_sheet),1]);

    %get directory data
    A=dir(indiv_stat_path); %directory a path is in

    %Get file last modified date
    file_last_modified_date{member_num}=A.date;

    sheets{member_num}=single_sheet;
    columns{member_num}=single_sheet.Properties.VariableNames;
end

%Repair dataframe to add stat type and the modification data of the file.
df.file_last_modified_date=file_last_modified_date';
df.stat_sheet_type=repmat(stat_sheet_column,size(df.(stat_sheet_column)));

%% collapse the group,sheet structure to a flat list of all the columns 
% Lets us find how often each column is used to validate these tables
% asking "are all the same?"
C=[columns{:}];
[column_names,~,column_idx]=unique(C,'stable');
column_counts=sum(column_idx==1:numel(column_names),1);
columns_to_keep=column_counts==max(column_counts);

%% trim sheets to common columns only
for member_num=1:height(df)
    cols=column_find( sheets{member_num}, [ '^' strjoin(column_names(columns_to_keep), '$|^') '$'], 1 );
    sheets{member_num}(:,~cols)=[];
end

%% combined loaded data
output=vertcat(sheets{:});
output=outerjoin(df,output,'Keys','specimen','MergeKeys',true);

%% Convert names into "REAL" human names -- what was in the data frame before we group/subgroup for stats
output_with_user_defined_names_positional_idx=column_find(output,'^(group)|^(subgroup)');
general_names=output.Properties.VariableNames(output_with_user_defined_names_positional_idx);
user_defined_names=output.Properties.VariableDescriptions(output_with_user_defined_names_positional_idx);

output_user_defined=output;

output_user_defined.Properties.VariableNames(output_with_user_defined_names_positional_idx)=user_defined_names;
output_user_defined.Properties.VariableDescriptions(output_with_user_defined_names_positional_idx)=general_names;
end