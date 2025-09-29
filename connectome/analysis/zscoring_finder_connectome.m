function [varargout] = zscoring_finder_connectome(data_table,zscore_group,varargin)
%% Preliminary Setups
zscore_grouping=zscore_group{1};
specimen_zscore=table;
count=1;

data_cells=regexpi(data_table.Properties.VariableNames,'^(X[0-9])$');
data_idx=find(~cellfun(@isempty,data_cells)==1); %actual idx not in logical array format
data_name=data_table.Properties.VariableNames(:,data_idx);

%% standarize the data using z-score to remove undesired effects if have covariates you want to remove
if numel(varargin)>0

    data_standardized=data_table;
    fieldNames_inData=fieldnames(data_standardized);

    if sum(~cellfun(@isempty,regexpi(fieldNames_inData,'vertex')))==1

        [vertex_value,~,vertex_idx]=unique(data_standardized.vertex);
        data_standardized=sortrows(data_standardized,'vertex');

        fulldata_cells=regexpi(data_standardized.Properties.VariableNames,'^(X[0-9])$'); % we actually don't want voxelss because it follows same math of all other
        fulldata_idx=find(~cellfun(@isempty,fulldata_cells)==1); %actual idx not in logical array format
        fulldata_name=data_standardized.Properties.VariableNames(~cellfun(@isempty,fulldata_cells));

        %Get mean and Standard deviation
        for n=1:numel(varargin)
            groups_to_remove{n}=varargin{n};
        end

        [remove_group_mean,remove_group_std] = group_summary_statistics_connectome(data_table,data_name,groups_to_remove);

        standarization_grouping_idx=regexpi(remove_group_mean.Properties.VariableNames,strcat('^(',strjoin(groups_to_remove,'|'),')$'));
        standarization_grouping_positional_idx=find(~cellfun(@isempty,standarization_grouping_idx)==1);
        [remove_data_type,~,remove_data_type_idx]=unique(remove_group_mean(:,standarization_grouping_positional_idx));

        zscore_remove_fulldata_idx=regexpi(data_table.Properties.VariableNames,strcat('^(',strjoin(groups_to_remove,'|'),')$'));
        zscore_remove_fulldata_positional_idx=find(~cellfun(@isempty,zscore_remove_fulldata_idx)==1);
        [full_data_remove_type,~,full_data_remove_type_idx]=unique(data_table(:,zscore_remove_fulldata_positional_idx));

        %% Making some assumptions about the ordering.
        for m=1:size(full_data_remove_type,1)
            %All specimen of one data type

            full_remove_test=sortrows(data_table(full_data_remove_type_idx==m,:),'vertex');
            removemean_test=sortrows(remove_group_mean(remove_data_type_idx==m,:),'vertex');
            removestd_test=sortrows(remove_group_std(remove_data_type_idx==m,:),'vertex');

            data_removemean_cells=regexpi(removemean_test.Properties.VariableNames,'^(X[0-9])$'); % we actually don't want voxelss because it follows same math of all other
            data_removemean_idx=find(~cellfun(@isempty,data_removemean_cells)==1); %actual idx not in logical array format
            data_removemean_name=removemean_test.Properties.VariableNames(~cellfun(@isempty,data_removemean_cells));

            [specimen_name_list,~,specimen_name_idx]=unique(full_remove_test.CIVM_Scan_ID,'stable');

            for o=1:size(specimen_name_list,1)
                %Checking the vertex values to the same set of vertex -- This sorts
                %on vertex
                mean_data=innerjoin(full_remove_test(specimen_name_idx==o,:),removemean_test,'Keys','vertex','LeftVariables','vertex');
                std_data=innerjoin(full_remove_test(specimen_name_idx==o,:),removestd_test,'Keys','vertex','LeftVariables','vertex');
                specimen_data=innerjoin(removemean_test,full_remove_test(specimen_name_idx==o,:),'Keys','vertex','LeftVariables','vertex');

                assert(height(mean_data)==height(specimen_data),'Datas are not the same length: check vertex -- to mean table')
                assert((numel(data_standardized.vertex)/numel(unique(data_standardized.CIVM_Scan_ID)))==height(specimen_data),'Datas are not the same length: check vertex -- to main table')

                data=array2table((table2array(specimen_data(:,data_idx)) ...
                    -table2array(mean_data(:,data_removemean_idx)))./table2array(std_data(:,data_removemean_idx)));

                select_correct_specimen_cells=regexpi(data_standardized.CIVM_Scan_ID,specimen_name_list{o});
                select_correct_specimen_idx=find(~cellfun(@isempty,select_correct_specimen_cells)==1);

                for p=1:numel(data_removemean_name)
                    %The problem is the sorting... this is not getting put bac
                    %into the data correctly.

                    data_standardized(select_correct_specimen_idx,fulldata_idx(~cellfun(@isempty,regexpi(fulldata_name,data_removemean_name(p)))))=data(:,p);
                end
            end
        end
    else

        fulldata_cells=regexpi(data_standardized.Properties.VariableNames,'^(X[0-9])$'); % we actually don't want voxelss because it follows same math of all other
        fulldata_idx=find(~cellfun(@isempty,fulldata_cells)==1); %actual idx not in logical array format
        fulldata_name=data_standardized.Properties.VariableNames(~cellfun(@isempty,fulldata_cells));

        %Get mean and Standard deviation
        for n=1:numel(varargin)
            groups_to_remove{n}=varargin{n};
        end

        [remove_group_mean,remove_group_std] = group_summary_statistics_connectome(data_table,data_name,groups_to_remove);

        standarization_grouping_idx=regexpi(remove_group_mean.Properties.VariableNames,strcat('^(',strjoin(groups_to_remove,'|'),')$'));
        standarization_grouping_positional_idx=find(~cellfun(@isempty,standarization_grouping_idx)==1);
        [remove_data_type,~,remove_data_type_idx]=unique(remove_group_mean(:,standarization_grouping_positional_idx));

        zscore_remove_fulldata_idx=regexpi(data_table.Properties.VariableNames,strcat('^(',strjoin(groups_to_remove,'|'),')$'));
        zscore_remove_fulldata_positional_idx=find(~cellfun(@isempty,zscore_remove_fulldata_idx)==1);
        [full_data_remove_type,~,full_data_remove_type_idx]=unique(data_table(:,zscore_remove_fulldata_positional_idx));

        %% Making some assumptions about the ordering.
        for m=1:size(full_data_remove_type,1)
            %All specimen of one data type

            data_removemean_cells=regexpi(remove_group_mean.Properties.VariableNames,'^(X[0-9])$'); % we actually don't want voxelss because it follows same math of all other
            data_removemean_idx=find(~cellfun(@isempty,data_removemean_cells)==1); %actual idx not in logical array format
            data_removemean_name=remove_group_mean.Properties.VariableNames(~cellfun(@isempty,data_removemean_cells));

            [specimen_name_list,~,specimen_name_idx]=unique(data_table.CIVM_Scan_ID,'stable');

            for o=1:size(specimen_name_list,1)
                %Checking the vertex values to the same set of vertex -- This sorts
                %on vertex
                mean_data=innerjoin(data_table(specimen_name_idx==o,:),remove_group_mean,'Keys',groups_to_remove,'LeftVariables',groups_to_remove);
                std_data=innerjoin(data_table(specimen_name_idx==o,:),remove_group_std,'Keys',groups_to_remove,'LeftVariables',groups_to_remove);
                specimen_data=innerjoin(remove_group_mean,data_table(specimen_name_idx==o,:),'Keys',groups_to_remove,'LeftVariables',groups_to_remove);

                data=array2table((table2array(specimen_data(:,data_idx)) ...
                    -table2array(mean_data(:,data_removemean_idx)))./table2array(std_data(:,data_removemean_idx)));

                select_correct_specimen_cells=regexpi(data_standardized.CIVM_Scan_ID,specimen_name_list{o});
                select_correct_specimen_idx=find(~cellfun(@isempty,select_correct_specimen_cells)==1);

                for p=1:numel(data_removemean_name)
                    %The problem is the sorting... this is not getting put bac
                    %into the data correctly.

                    data_standardized(select_correct_specimen_idx,fulldata_idx(~cellfun(@isempty,regexpi(fulldata_name,data_removemean_name(p)))))=data(:,p);
                end
            end
        end


    end

    varargout{1}=data_standardized;
end
end