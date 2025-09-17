function [CoV_output] = cov_generation(big_table)
%Pull Hemisphere Assignments we are interested in
idx=~cellfun(@isempty,regexpi(big_table.Properties.VariableNames,'hemisphere_assignment'));
%LEFT
idx_LEFT=table2array(big_table(:,idx))==-1;
%RIGHT
idx_RIGHT=table2array(big_table(:,idx))==1;

%Get the Data Columns to perform COV on
meanANDvol_idx=~cellfun(@isempty,regexpi(big_table.Properties.VariableNames,'_mean$|^vol|'));
meanANDvol_name=big_table.Properties.VariableNames(:,meanANDvol_idx);

check_for_rob_sheet=sum(~cellfun(@isempty,regexpi(big_table.Properties.VariableNames,'^GN_Symbol$'))); 

%If there is no entry with GN_Symbol in it then we go the RCCF original polish sheet names else use robs
if check_for_rob_sheet==1
    %Get common information columns
    idx=regexp(big_table.Properties.VariableNames,'^(specimen|ARA_name|ARA_abbrev|structure_id|group|subgroup[0-9])$');
elseif check_for_rob_sheet==0
    %Get common information columns
    idx=regexp(big_table.Properties.VariableNames,'^(specimen|acronym|name|structure_id|group|subgroup[0-9])$');
end


%The actual rows to use are specimen|name|
entry_names=big_table.Properties.VariableNames(~cellfun(@isempty,idx));

%funtionalized std and mean
do_std = @(x) std (x,'omitnan');
do_mean = @(x) mean (x,'omitnan');

%Find std and mean
%std result of each contrast and the std regional brain volume for each specimen
std_table_meanANDvol=varfun(do_std,big_table(logical(idx_LEFT+idx_RIGHT),:),'GroupingVariables',entry_names(:),'InputVariables',meanANDvol_name);
%mean result of each contrast and the mean regional brain volume for each specimen
mean_table_meanANDvol=varfun(do_mean,big_table(logical(idx_LEFT+idx_RIGHT),:),'GroupingVariables',entry_names(:),'InputVariables',meanANDvol_name);

%putting the mean and standard deviation across hemisphere data into output
%table
Data_table=outerjoin(mean_table_meanANDvol,std_table_meanANDvol,'Key',entry_names(:),'MergeKeys',true);

%Getting columns to do math on
fun_mean_idx=~cellfun(@isempty,regexp(Data_table.Properties.VariableNames,'_mean_table_meanANDvol'));
fun_std_idx=~cellfun(@isempty,regexp(Data_table.Properties.VariableNames,'_std_table_meanANDvol'));
fun_std_name=Data_table.Properties.VariableNames(:,fun_std_idx);

%doing actual math
CoV_temp_Math=table2array(Data_table(:,fun_std_idx))./ table2array(Data_table(:,fun_mean_idx));

CoV_name=strrep(fun_std_name,'std_table','CoV');
CoV_name=strrep(CoV_name,'_meanANDvol','');
CoV_name=strrep(CoV_name,'Fun_','');

%% load back into the CoV Table
CoV_output=table;

%If there is no entry with GN_Symbol in it then we go the RCCF original polish sheet names else use robs
if check_for_rob_sheet==1
    %Get common information columns
    idx=regexp(Data_table.Properties.VariableNames,'^(specimen|ARA_name|ARA_abbrev|structure_id|group|subgroup[0-9])$');
elseif check_for_rob_sheet==0
    %Get common information columns
    idx=regexp(Data_table.Properties.VariableNames,'^(specimen|acronym|name|structure_id|group|subgroup[0-9])$');
end

CoV_output=Data_table(:,~cellfun(@isempty,idx));

check_group_count=cellfun(@isempty,regexp(CoV_name,'^GroupCount'));
for n=1:numel(CoV_name)
    if check_group_count(n)
        CoV_output.(CoV_name{n})=CoV_temp_Math(:,n);
    end
end

end