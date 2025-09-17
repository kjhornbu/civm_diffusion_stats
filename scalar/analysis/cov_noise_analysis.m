function [mean_CoV_specimen_table,mean_CoV_ROI_table] = cov_noise_analysis(CoV_table)
%% find the cells and names for the CoV variables we are working on
CoV_cells=regexpi(CoV_table.Properties.VariableNames,'_CoV');
CoV_idx=~cellfun(@isempty,CoV_cells);
CoV_name=CoV_table.Properties.VariableNames(:,CoV_idx);

%% create mean function for tables
omean = @(x) mean(x,'omitnan');

%% Same Specimen Average
mean_CoV_specimen_table=varfun(omean,CoV_table,'GroupingVariables',{'specimen'},'InputVariables',CoV_name); 
%mean result of each contrast and the mean regional brain volume for each specimen bilat
mean_CoV_specimen_table.Properties.VariableNames=strrep(mean_CoV_specimen_table.Properties.VariableNames(:),'Fun_','');

group_count_cells=regexpi(mean_CoV_specimen_table.Properties.VariableNames,'.*GroupCount(.*)');
NOT_group_count_idx=cellfun(@isempty,group_count_cells);

mean_CoV_specimen_table=mean_CoV_specimen_table(:,NOT_group_count_idx);

%% Same ROI Average

check_for_rob_sheet=sum(~cellfun(@isempty,regexpi(CoV_table.Properties.VariableNames,'^ARA_name$'))); 
%If there is no entry with ARA_name in it then we go the RCCF original polish sheet names else use robs
if check_for_rob_sheet==1
    %Get common information columns
    grouping_on='ARA_name';

elseif check_for_rob_sheet==0
    %Get common information columns
    grouping_on='name';
end

mean_CoV_ROI_table=varfun(omean,CoV_table,'GroupingVariables',{grouping_on},'InputVariables',CoV_name); 
%mean result of each contrast and the mean regional brain volume for each specimen bilat
mean_CoV_ROI_table.Properties.VariableNames=strrep(mean_CoV_ROI_table.Properties.VariableNames(:),'Fun_','');

group_count_cells=regexpi(mean_CoV_ROI_table.Properties.VariableNames,'.*GroupCount(.*)');
NOT_group_count_idx=cellfun(@isempty,group_count_cells);

mean_CoV_ROI_table=mean_CoV_ROI_table(:,NOT_group_count_idx);
end

