function [OUT] = find_pairwise_compare(Data,pair_comparisons,name_mean,name_std)
% The Data input is the group scalar data
% Double check no accidential different Structure IDs via looking at the
% ROI#

%% Preliminary Setups
OUT=table;

%% Do Actual math of Percent Change and put into the output table
for n=1:size(pair_comparisons,2)
    [Data_select_control,Data_select_treatment,string_test_conditions] = select_AB(Data,pair_comparisons(:,n));

    Treat_Temp=Data(Data_select_treatment,:);
    Control_Temp=Data(Data_select_control,:);

    %Check for Group count
    idx_groupcount=regexp(Control_Temp.Properties.VariableNames,strcat( 'GroupCount$'));
    logical_idx_groupcount=~cellfun(@isempty,idx_groupcount);

    if sum(logical_idx_groupcount)==0

        idx_specimen=regexp(Control_Temp.Properties.VariableNames,strcat( 'specimen$'));
        logical_idx_specimen=~cellfun(@isempty,idx_specimen);

        if sum(logical_idx_specimen)>0
            % If we don't have column data and still have specimen it means
            % we need to create group summary stats
            % This is too gross right now
            %[group_mean,group_std,group_median,group_IQR] = group_summary_statistics(data_table,data_name,zscore_grouping)

            [Treat] = mean_from_indiv_forReporting(Treat_Temp);
            [Control] = mean_from_indiv_forReporting(Control_Temp);
        end

    else
        %If we have the GroupCount Already we just combine the columns of
        %data based on what we have THE STD IS JUST AN ESTIMATE HERE SO THE
        %COHEN D WILL NOT BE AS ACCURACTE --- If you don't completely
        %define all the group parts then this will try to combine together
        %all of them together. 

        [Treat] = combine_mean_std_from_groups(Treat_Temp);
        [Control] = combine_mean_std_from_groups(Control_Temp);
    end

    %% Calculate CohenD, Percent Change, RAW Difference
    [single_Testcondition_output] = calculate_cohenD_percentChange_RawDifference(Control,Treat,name_mean,name_std);

    if ~isempty(OUT)
        %if there is an OUT just join
        data_column_idx=column_find(single_Testcondition_output.Properties.VariableNames,'^(cohenD|percent_change|absolute_error)$',1);
        Key_names=single_Testcondition_output.Properties.VariableNames(~data_column_idx);

        OUT=outerjoin(OUT,single_Testcondition_output,'Key',Key_names,'MergeKeys',true);

        OUT=column_rename(OUT,'^(cohenD)$',strcat('cohenD_',string_test_conditions{1,1},'_',string_test_conditions{2,1}));
        OUT=column_rename(OUT,'^(percent_change)$',strcat('percent_change_',string_test_conditions{1,1},'_',string_test_conditions{2,1}));
        OUT=column_rename(OUT,'^(absolute_error)$',strcat('absolute_error_',string_test_conditions{1,1},'_',string_test_conditions{2,1}));
    else
        % if there is not an out make the single test condition the output.
        % change names as needed
        single_Testcondition_output=column_rename(single_Testcondition_output,'cohenD',strcat('cohenD_',string_test_conditions{1,1},'_',string_test_conditions{2,1}));
        single_Testcondition_output=column_rename(single_Testcondition_output,'percent_change',strcat('percent_change_',string_test_conditions{1,1},'_',string_test_conditions{2,1}));
        single_Testcondition_output=column_rename(single_Testcondition_output,'absolute_error',strcat('absolute_error_',string_test_conditions{1,1},'_',string_test_conditions{2,1}));

        OUT=single_Testcondition_output;
    end
end

percentChange_columns_idx=column_find(OUT,'percent_change');
cohenD_columns_idx=column_find(OUT,'cohenD');
abserror_columns_idx=column_find(OUT,'absolute_error');

OUT.('Mean_PercentChange_AcrossKeyGroupings')=mean(table2array(OUT(:,percentChange_columns_idx)),2,'omitnan');
OUT.('Sum_ABS_PercentChange_AcrossKeyGroupings')=sum(abs(table2array(OUT(:,percentChange_columns_idx))),2,'omitnan');

data_column_idx=column_find(single_Testcondition_output.Properties.VariableNames,'^(cohenD|percent_change|absolute_error)',1);
data_column_positional_idx=find(~data_column_idx==1);        

OUT=OUT(:,[data_column_positional_idx,cohenD_columns_idx,abserror_columns_idx,percentChange_columns_idx,end-1,end]);

end

