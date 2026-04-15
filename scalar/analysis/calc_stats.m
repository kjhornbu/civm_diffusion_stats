function [output_table,multicompare_table,group_output_summary] = calc_stats(data_table,test_grouping,stats_test)
%% This is the main Calculation Script to use for calculation of statistics 


check_rob_sheet=sum(~cellfun(@isempty,regexpi(data_table.Properties.VariableNames,'GN_Symbol')));

if check_rob_sheet==1
    Bookkeeping_group_summary_list={'ROI','Structure','hemisphere_assignment','GN_Symbol','ARA_abbrev','id64_fSABI','id32_fSABI','structure_id','GroupCount'};
elseif check_rob_sheet==0
    Bookkeeping_group_summary_list={'ROI','Structure','hemisphere_assignment','acronym','name','id64','id32','structure_id','GroupCount'};

end

data_grouping_regex=strcat('^(',strjoin(Bookkeeping_group_summary_list,'|'),'|',strjoin(cellsimplify(test_grouping),'|'),')$'); 

%preliminary table setup
output_table=table;
multicompare_table=table;

if ~isfield(stats_test,'pval_threshold')
    %set automatic pvalue if not already set outside
    stats_test.pval_threshold=0.05;
end

%we do the statistical test one roi at a time so get list to work over 
[ROI_list,~]=unique(data_table.ROI);

%% Getting group summary statistics

%get the data columns in the dataset
data_cells=regexpi(data_table.Properties.VariableNames,'(_mean|voxels|volume_mm3|volume_fraction)$');
data_idx=find(~cellfun(@isempty,data_cells)==1); %actual idx not in logical array format
data_name=data_table.Properties.VariableNames(:,data_idx);

%all the data we want to group on
[group_mean,group_std,group_median,group_IQR] = group_summary_statistics(data_table,data_name,test_grouping);

group_data_grouping_idx=regexpi(group_mean.Properties.VariableNames,data_grouping_regex);
group_data_grouping_logical_idx=cellfun(@isempty,group_data_grouping_idx);
group_data_grouping_names=group_mean.Properties.VariableNames(group_data_grouping_logical_idx);

%put type of group data to each table which makes better for saving output result table  
temp_data_name=strcat(group_data_grouping_names,'_group_mean');
group_mean.Properties.VariableNames(group_data_grouping_logical_idx)=temp_data_name;

temp_data_name=strcat(group_data_grouping_names,'_group_std');
group_std.Properties.VariableNames(group_data_grouping_logical_idx)=temp_data_name;

temp_data_name=strcat(group_data_grouping_names,'_group_median');
group_median.Properties.VariableNames(group_data_grouping_logical_idx)=temp_data_name;

temp_data_name=strcat(group_data_grouping_names,'_group_IQR');
group_IQR.Properties.VariableNames(group_data_grouping_logical_idx)=temp_data_name;

%pulling all data entries back into a single output table
group_output_summary=join(group_mean,group_std);
group_output_summary=join(group_output_summary,group_median);
group_output_summary=join(group_output_summary,group_IQR);

% because its used the same for all rois, we create using the first one.
[name_table,length_name_nointeraction_table,nway_analysis_set]=build_anova_name_table(data_table(data_table.ROI==ROI_list(1),:),test_grouping,stats_test);

%% Statsitical analysis with Potential Posthoc Testing
for n_n=1:numel(ROI_list)

    length_output=size(output_table,1);
    length_multicompare=size(multicompare_table,1);

    roi_subtable=data_table(data_table.ROI==ROI_list(n_n),:);

    switch stats_test.name
        case 'anovan_no_interaction'
            % Parametric N-Way Anova with no interactions
            type='no_interaction';
            [stats_test.matrix{1}] = binary_interaction_generator(test_grouping,type);
            [output,multicompare] = anovan_defined_matrix_withposthoc_module(roi_subtable,stats_test,name_table,nway_analysis_set,length_name_nointeraction_table);
        case 'anovan_pairwise_interaction'
            % Parametric N-Way Anova with no interactions and pairwise
            % interactions.
            type='pairwise';
            [stats_test.matrix{1}] = binary_interaction_generator(test_grouping,type);
            [output,multicompare] = anovan_defined_matrix_withposthoc_module(roi_subtable,stats_test,name_table,nway_analysis_set,length_name_nointeraction_table);
        case 'anovan_full_interaction'
            % Parametric N-Way Anova with no interactions and all possible interactions of cofactors.
            type='full';
            [stats_test.matrix{1}] = binary_interaction_generator(test_grouping,type);
            [output,multicompare] = anovan_defined_matrix_withposthoc_module(roi_subtable,stats_test,name_table,nway_analysis_set,length_name_nointeraction_table);
        case 'anovan_stepdown_integer_interaction'
            %Parametric N-Way Anova Steps down by level more correctly instead of all combinations to just
            %pairwise
            error('You should use the defined matrix form of anovan instead of expecting a program to figure out valid interactions for you'); 
            %[output,multicompare] = anovan_stepdown_integer_interaction_withposthoc_module(roi_subtable,test_grouping,stats_test);
        case 'anovan_defined_matrix'
            %Specific equation based form of entry of terms into the
            %anovan
            [output,multicompare] = anovan_defined_matrix_withposthoc_module(roi_subtable,stats_test,name_table,nway_analysis_set,length_name_nointeraction_table);
        case 'friedman'
            % A non-parametric N Ways Anova: NOTE cannot use groups of
            % different N in this
             %NOT CURRENTLY ACTIVE -- Need to fix effect sizes and Coeff of
             %variation
            %[output,multicompare] = friedman_withposthoc_module(roi_subtable,test_grouping,stats_test);
            error('friedman is not active yet');
        case 'anova_1way'
            % A 1 Way anonva
            %check test grouping lenght is 1.
            assert(numel(test_grouping)==1,'You can''t do a 1 way anova with multiple covariates');
            stats_test.matrix{1}=1;
            [output,multicompare] = anovan_defined_matrix_withposthoc_module(roi_subtable,stats_test,name_table,nway_analysis_set,length_name_nointeraction_table);

            %[output,multicompare] = anova1_withposthoc_module(roi_subtable,test_grouping,stats_test); %Really don't need this can use anovan for it
        case 'kruskalwallis'
            % A non parametric anova
            assert(numel(test_grouping)==1,'You can''t do a 1 way anova with multiple covariates');
            stats_test.matrix{1}=1;

            [output,multicompare] = kruskal_wallis_anova_withposthoc_modulev2(roi_subtable,stats_test,name_table,nway_analysis_set,length_name_nointeraction_table);
        case 'ttest'
            % The standard 2 sample t test
             %NOT CURRENTLY ACTIVE -- Need to fix effect sizes and Coeff of
             %variation
             %THERE IS NO POSTHOC HERE BECAUSE YOU CAN ONLY USE t tests
             %with 2 groupings
            %[output] = ttest_module(roi_subtable,test_grouping);
            error('t-test is not active yet');
        case 'mannwhitney'
            % Non parametric 2 sample t test -- Called Typically some
            % combination of Mann, Whitney, Wilcoxon and U Test  in
            % literature : https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test

             %currently using default option of two tailed
             %NOT CURRENTLY ACTIVE -- Need to fix effect sizes and Coeff of
             %variation
             %THERE IS NO POSTHOC HERE BECAUSE YOU CAN ONLY USE t tests
             %with 2 groupings
            %[output] =
            %mannwhitney_module(roi_subtable,test_grouping);
            error('mann whitney is not active yet');
        case 'manova_nway_fullinteraction'
            % A Parametric N-Way MANOVA -- Using Matlabs updated Manova
            % Object... Will only work in matlab >2023 

            %note this posthoc is only with the non-interaction terms! 

            [output,multicompare] = manova_nway_fullinteraction_withsimpleposthoc_module(roi_subtable,test_grouping,stats_test);
        case 'manova_nway_stepdown_interaction'
            %Need to code in the stepdown in a way that makes sense
            %currently just the full interaction mode  Will only work in matlab >2023 
            %[output,multicompare] = manova_nway_stepdown_withsimpleposthoc_module(roi_subtable,test_grouping,stats_test);
            error('You should use the defined matrix form of manovan instead of expecting a program to figure out valid interactions for you');

        case 'manova_nway_no_interaction'
            %Need to code in the stepdown in a way that makes sense
            %currently just the full interaction mode  Will only work in matlab >2023 
            [output,multicompare] = manova_nway_no_interaction_withsimpleposthoc_module(roi_subtable,test_grouping,stats_test);

        case 'manova_nway_defined_matrix' 
            error('manova_nway_defined_matrix is not active yet');
            
    end

    logical_idx=cellfun(@ischar,output.contrast);
    if ~all(logical_idx)
        keyboard;
        %todo: smartly fix the whole brain bilateral condition
    end

    % write what you have for the output and then "correct" it later by not writing
    %out the full matrix -- just filling out the output_table for what you
    %have

    if width(output_table) ~= width(output)
        if width(output_table) < width(output) 
            %Width of output table is less than output
            
            % main table is not yet initialized (it is empty)
            columns_to_add=setdiff(output.Properties.VariableNames,output_table.Properties.VariableNames);
            if numel(columns_to_add) == width(output)
                % then output_table is totally empty (just add all the entries in the output) 
                % ---  make it exactly the same which will give us our column names as well
                output_table=output;
            else
                %--- iterate to add columns in the dataset
                for col=columns_to_add
                    output_table.(col{1}) = nan(height(output_table),1);
                end
                keyboard;
            end
        else
            % if width of output table is more than the output from stats
            % we need to 
            columns_to_add=setdiff(output_table.Properties.VariableNames,output.Properties.VariableNames);
            % add columns to output table
            for col=columns_to_add
                %By putting these in here we aren't clearing out what we are missing 
                output.(col{1}) = nan(height(output),1);
            end
            % current roi table is incomplete. initialize with nans
            %keyboard;
        end
    end

    
    try 
    %only put data in the output table that we have data for... 
    % correct assumption that data is always in the correct spot because it
    % is consistent across all? 

    output_table(length_output+(1:size(output,1)),1:size(output,2))=output;
    catch exception
        keyboard;
    end
    
%    if length_output==0
%        output_table.Properties.VariableNames=output.Properties.VariableNames;
%    end

%The pairwise multicomparision is breaking with 5xFAD because too many parameters getting forced in -- removed for the time being
%2025-08-25

try
    if height(multicompare)>0
        %exist('multicompare','var')
        multicompare_table(length_multicompare+(1:size(multicompare,1)),1:size(multicompare,2))=multicompare;
        if length_multicompare==0
            multicompare_table.Properties.VariableNames=multicompare.Properties.VariableNames;
        end
    end
catch
    warning('Multi Compare Fail probably due to sources of variation dropping out and the inital stat test triggering the anova not being fully correct (adds extra space into the table which we cannot deal with?)')
end
end

end