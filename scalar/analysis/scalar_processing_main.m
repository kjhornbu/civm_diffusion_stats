function [output_path_table] = scalar_processing_main(dataframe,save_location,group,subgroup,test_conditions,remove_zscore_grouping,stats_test,opts)
%bilat_result_table,left_result_table,right_result_table,bilat_result_table_BHFDR,left_result_table_BHFDR,right_result_table_BHFDR,bilat_multi_compare_table,left_multi_compare_table,right_multi_compare_table
%% The meat of the script that generates the scalar analysis of the data set

%% process each stat type
if exist('opts','var')
    for n=1: numel(opts.scalarContrastMetrics)
        voxel_wise{n} =opts.scalarContrastMetrics(n).Name{:};
        voxel_wise_keys{n} =opts.scalarContrastMetrics(n).Column{:};
        all_ideal_contrast_list{n}=opts.scalarContrastMetrics(n).List(:);
    end
end

% voxel_wise={'Non_Erode','Erode'}
% voxel_wise_keys={'stat_path','stat_path_erode'}

%% check if erode stats are part of data frame, and skip with warning if not
if isempty( column_find(dataframe,'^stat_path_erode$') )
    warning('There are NO Erode Stat Paths Specified -- NO Erode Region Data Summaries will be Generated');
    pause(3);
    idx=reg_match(voxel_wise,'^(Erode)$');
    pos_idx=find(idx);

    voxel_wise{pos_idx}=[];
    voxel_wise_keys{pos_idx}=[];
    all_ideal_contrast_list{pos_idx}=[];

    voxel_wise = voxel_wise(~cellfun('isempty',voxel_wise)) ;
    voxel_wise_keys = voxel_wise_keys(~cellfun('isempty',voxel_wise_keys)) ;
    all_ideal_contrast_list = all_ideal_contrast_list(~cellfun('isempty',all_ideal_contrast_list)) ;
end

%% Check if too many input groupings
if numel(test_conditions)>1 && ~ischar(test_conditions{1})
    error('We don''t currently support multiple stats models (like Sex+Strain then doing Sex+Strain+Sex:Strain with single call) in 1 go. You need to call scalar processing main multiple times yourself.');
    %This was actually for the  case that had you pushing like 5 stats
    %models in one go... rather than stratification... the stratification
    %being broken was a "happy accident".
    %error('Scalar Processing doesn''t currently support stratification. Connectomics does. If you need stratification in scalar, please improve this.');
end
%Defining output path table
output_path_table=table;
output_path_table.hemisphere={};
output_path_table.voxel_wise={};
output_path_table.stratification={}; %Add Stratfication field
output_path_table.StatsResults={};
output_path_table.Posthoc={};
output_path_table.GroupTable={};
output_path_table.SubjectTable={};



for o=1:numel(voxel_wise)
    if o==1
        keep_save_location=save_location;
    end
    save_location=fullfile(keep_save_location,voxel_wise{o});
    if isempty(dir(save_location))
        mkdir(save_location);
    end
    %% data frame curation
    % in theory this should be done when building the data frame.
    %% Use lowercase column names
    dataframe.Properties.VariableNames=lower(dataframe.Properties.VariableNames);
    %% Adjust Gender V Sex Subgrouping column heading to consistent sex
    idx=reg_match(dataframe.Properties.VariableNames,'^(gender|sex)$');
    if nnz(idx)==1
        %If there is only zeroes in the array for 'sex-type' entry then don't try to convert
        dataframe.Properties.VariableNames{idx}='sex';
    elseif nnz(idx)>1
        error('There is more than one thing selected');
    end
    clear idx;

    %% Adjust specimen V runno Subgrouping column heading to consistent specimen
    idx=column_find(dataframe,'^specimen$',1);
    if ~nnz(idx)
        % IF there is not an exact specimen column, try harder -- this is
        % some unique identifier across all the data entries.
        idx=reg_match(dataframe.Properties.VariableNames,'^(civm_scan_id|CIVM_ID|specimen|runno|scan|civm_specimen_id)$');
    end
    %create an iteration to find the unique across all the properties
    %specimen name
    pos_idx=find(idx,nnz(idx));
    for n=1:nnz(idx)
        terms=unique(dataframe.(pos_idx(n)));
        if height(dataframe)==numel(terms)
            idx=false(size(idx));
            idx(pos_idx(n))=true;
            break;
        end
    end
    if nnz(idx)==1
        %accept 1
        dataframe.Properties.VariableNames{idx}='specimen';
    elseif nnz(idx)>1
        error('There is more than one thing selected');
    elseif nnz(idx)==0
        error('Missing Specimen Identifier');
    end
    clear idx;

    %% assign group/subgroup specified to dataframe, and convert the columns that might accidently be non-strings to strings
    [dataframe] = clean_df_to_general_entries(group,subgroup,dataframe);

    %% Pull Data from Stat Files
    try
        [big_table, User_Defined_big_table]=build_study_table(dataframe,voxel_wise_keys{o});
    catch
        keyboard;
    end
    %Fix the uint64 issue here just in case for doing the further
    %processing.
    big_table.voxels=double(big_table.voxels);
    User_Defined_big_table.voxels=double(User_Defined_big_table.voxels);

    %% Add in the Normalized Volume to the Data tables
    [big_table] = add_norm_vol_2_data_table(big_table);
    [User_Defined_big_table] = add_norm_vol_2_data_table(User_Defined_big_table);

    %% Big Table with the useful names as defined by the user added back in.
    civm_write_table(User_Defined_big_table,fullfile(save_location,'Subject_Data_Table.csv'));
    subject_data_table_path=fullfile(save_location,'Subject_Data_Table.csv');

    %% Refilter the Subject data table to Just "interesting" contrasts

    ideal_contrast_list=all_ideal_contrast_list{o};
    all_contrast_list='(_mean|voxels|volume_mm3|volume_fraction)$';

    %Finding contrast columns to keep
    keep_user_defined_idx=column_find(User_Defined_big_table.Properties.VariableNames,strcat('^(',strjoin(ideal_contrast_list,'|'),')$'),1);
    keep_idx=column_find(big_table.Properties.VariableNames,strcat('^(',strjoin(ideal_contrast_list,'|'),')$'),1);

    %find all contrast columns
    all_contrast_user_defined_idx=column_find(User_Defined_big_table.Properties.VariableNames,all_contrast_list,1);
    all_contrast_idx=column_find(big_table.Properties.VariableNames,all_contrast_list,1);

    % find bad means
    bad_contrast_user_defined_idx=and(all_contrast_user_defined_idx,~keep_user_defined_idx);
    bad_contrast_idx=and(all_contrast_idx,~keep_idx);

    % find names of bad means
    bad_contrast_user_defined_names=User_Defined_big_table.Properties.VariableNames(bad_contrast_user_defined_idx);
    bad_contrast_names=big_table.Properties.VariableNames(bad_contrast_idx);

    bad_contrast_user_defined_names=strrep(bad_contrast_user_defined_names,'_mean','_');
    bad_contrast_names=strrep(bad_contrast_names,'_mean','_');

    %all bad contrasts
    bad_contrast_user_defined_idx=column_find(User_Defined_big_table.Properties.VariableNames,strcat('^(',strjoin(bad_contrast_user_defined_names,'|'),')'),1);
    bad_contrast_idx=column_find(big_table.Properties.VariableNames,strcat('^(',strjoin(bad_contrast_names,'|'),')'),1);

    User_Defined_big_table=User_Defined_big_table(:,~bad_contrast_user_defined_idx);
    big_table=big_table(:,~bad_contrast_idx);

    % force important columns to text
    big_table=column2text(big_table,test_conditions);

    %% Make Bilateral case if doesn't exist
    % This should not apply anymore to the datasets! all data with the
    % modern labels should have this built in... should this be put in a
    % function so we can skip and not hhave be nasty.
    hemifind=regexpi(big_table.Properties.VariableNames,'hemisphere_assignment');

    if sum(~cellfun(@isempty,hemifind))==0

        idx_R=big_table.ROI>1000;
        idx_L=big_table.ROI<1000;

        big_table.hemisphere_assignment(idx_R)=1;
        big_table.hemisphere_assignment(idx_L)=-1;

        %Remove Exterior
        big_table(big_table.ROI==0,:)=[];

        left_table=big_table(big_table.hemisphere_assignment==-1,:);
        right_table=big_table(big_table.hemisphere_assignment==1,:);

        [left_name,~,left_idx]=unique(left_table.specimen,'stable');
        [right_name,~,right_idx]=unique(right_table.specimen,'stable');

        volume_list=list2cell("voxels volume_mm3 volume_fraction");
        contrast_list=list2cell("fa_mean ad_mean md_mean rd_mean dwi_mean gfa_mean nqa_mean qa_mean iso_mean");

        left_table_logical=~cellfun(@isempty,regexpi(left_table.Properties.VariableNames,strcat('ROI|structure|hemisphere_assignment|group|specimen|',strjoin(contrast_list,'|'),'|',strjoin(volume_list,'|'))));
        right_table_logical=~cellfun(@isempty,regexpi(right_table.Properties.VariableNames,strcat('ROI|structure|hemisphere_assignment|group|specimen|',strjoin(contrast_list,'|'),'|',strjoin(volume_list,'|'))));

        left_table=left_table(:,left_table_logical);
        right_table=right_table(:,right_table_logical);

        bilat_table=table;
        for i_testcondition=1:numel(left_name)

            if strcmp(left_name(i_testcondition),right_name(i_testcondition)) ~= 1
                error('The specimen do not match')
            else

                bilat_length=size(bilat_table,1);

                temp_bilat_ROI=left_table.ROI(left_idx==i_testcondition);
                bilat_table.ROI(bilat_length+[1:numel(temp_bilat_ROI)])=temp_bilat_ROI;

                bilat_table.structure(bilat_length+[1:numel(temp_bilat_ROI)])=left_table.structure(left_idx==i_testcondition);


                for m=1:numel(volume_list)

                    temp_bilat_vol=left_table.(volume_list(m))(left_idx==i_testcondition)+right_table.(volume_list(m))(right_idx==i_testcondition);
                    bilat_table.(volume_list(m))(bilat_length+[1:numel(temp_bilat_ROI)])=temp_bilat_vol;

                end

                for m=1:numel(contrast_list)

                    temp_bilat_con=((left_table.(contrast_list(m))(left_idx==i_testcondition).*left_table.(volume_list(1))(left_idx==i_testcondition))+(right_table.(contrast_list(m))(right_idx==i_testcondition).*right_table.(volume_list(1))(right_idx==i_testcondition)))./(left_table.(volume_list(1))(left_idx==i_testcondition)+right_table.(volume_list(1))(right_idx==i_testcondition));
                    bilat_table.(contrast_list(m))(bilat_length+[1:numel(temp_bilat_ROI)])=temp_bilat_con;

                end

                group_logical_idx=~cellfun(@isempty,regexpi(left_table.Properties.VariableNames,'group'));
                group_positional_idx=find(group_logical_idx==1);
                group_setting_name=left_table.Properties.VariableNames(group_positional_idx);

                for m=1:numel(group_setting_name)
                    bilat_table.(group_setting_name{m})(bilat_length+[1:numel(temp_bilat_ROI)])=left_table.(group_setting_name{m})(left_idx==i_testcondition);
                end

                bilat_table.specimen(bilat_length+[1:numel(temp_bilat_ROI)])=left_table.specimen(left_idx==i_testcondition);

                bilat_table.hemisphere_assignment(bilat_length+[1:numel(temp_bilat_ROI)])=0;

            end
        end

        big_table=vertcat(left_table,right_table,bilat_table);

        civm_write_table(big_table,fullfile(save_location,'Subject_Data_Table_Regenerated_Bilateral.csv'));

    else
        %% Do check for CoV noise
        [cov_table] = cov_generation(big_table);
        civm_write_table(cov_table,fullfile(save_location,'Subject_CoV_Table.csv'));

        [mean_CoV_specimen_table,mean_CoV_ROI_table] = cov_noise_analysis(cov_table);

        civm_write_table(mean_CoV_specimen_table,fullfile(save_location,'Subject_Average_CoV_Table.csv'));
        civm_write_table(mean_CoV_ROI_table,fullfile(save_location,'ROI_Average_CoV_Table.csv'));
    end

    %%  Now do actual formulation on each of the data groupings
    %Loop over test conditions --- the models in the system (we only allow
    %one model at a time now  and have a check condition to disappear at
    %this point so don't allow the looping. 


    % thought for later make the bilateral L/R a loop rather than doing
    % things 3 times (would definately make cleaner)
    i_testcondition=1;
    % test conditions builds along second dimension not first in the structure.
    % That is if the multi test conditions existed and was able to be used we would iterate through that but for now this forces 1
   
    %removed the grabbing loop because we only have 1 condition in the
    %stats_test layout... don't make it more complex

    % Form of data within the single test condition: {'STRATIFICATION'};{{'GROUPING'}}
    if size(test_conditions,1)==2 && ischar(test_conditions{1})
        %% This starts stratificaiton
        [~,group_names,group_name_idx] = find_group_information_from_groupingcriteria(big_table,test_conditions(1));
        strat_column_idx=column_find(big_table.Properties.VariableNames,strcat('^(',test_conditions{1},')$'));
        %Grab the model grouping separate from the stratification condition
        model_GROUPING=test_conditions{2}{i_testcondition}; % We now wrap the grouping conditions with a cell so its a cell within a cell just remove that to put together.
        for m=1:numel(group_names)
            %filter by the test_conditions{i_sz}{1} prior to running
            %analysis
            shifted_big_table=big_table(group_name_idx==m,:);

            left_table=shifted_big_table(shifted_big_table.hemisphere_assignment==-1,:);
            bilat_table=shifted_big_table(shifted_big_table.hemisphere_assignment==0,:);
            right_table=shifted_big_table(shifted_big_table.hemisphere_assignment==1,:);

            try
                if isempty(remove_zscore_grouping{i_testcondition})
                    [bilat_specimen_zscore] = zscoring_finder(bilat_table,model_GROUPING);
                    [left_specimen_zscore] = zscoring_finder(left_table,model_GROUPING);
                    [right_specimen_zscore] = zscoring_finder(right_table,model_GROUPING);
                else
                    [bilat_table_standardized,bilat_specimen_zscore] = zscoring_finder(bilat_table,model_GROUPING,remove_zscore_grouping{i_testcondition}{:});
                    [left_table_standardized,left_specimen_zscore] = zscoring_finder(left_table,model_GROUPING,remove_zscore_grouping{i_testcondition}{:});
                    [right_table_standardized,right_specimen_zscore] = zscoring_finder(right_table,model_GROUPING,remove_zscore_grouping{i_testcondition}{:});

                    civm_write_table(bilat_table_standardized,fullfile(save_location,strcat(group_names{m},'_Bilat_Subject_Data_Table_ZScore_Standardized_by_',strjoin(remove_zscore_grouping{i_testcondition},'_'),'.csv')));
                    civm_write_table(left_table_standardized,fullfile(save_location,strcat(group_names{m},'_Left_Subject_Data_Table_ZScore_Standardized_by_',strjoin(remove_zscore_grouping{i_testcondition},'_'),'.csv')));
                    civm_write_table(right_table_standardized,fullfile(save_location,strcat(group_names{m},'_Right_Subject_Data_Table_ZScore_Standardized_by_',strjoin(remove_zscore_grouping{i_testcondition},'_'),'.csv')));

                end
            catch
                %if it doesn't work we aren't trying to hard right now --
                %typically it is a string related issued with non
                %categorical terms
                bilat_specimen_zscore=table;
                left_specimen_zscore=table;
                right_specimen_zscore=table;
            end

            if isempty(remove_zscore_grouping{i_testcondition})
                [bilat_result_table,bilat_multi_compare_table,bilat_group_summary_stats] = calc_stats(bilat_table,model_GROUPING,stats_test);
                [left_result_table,left_multi_compare_table,left_group_summary_stats] = calc_stats(left_table,model_GROUPING,stats_test);
                [right_result_table,right_multi_compare_table,right_group_summary_stats] = calc_stats(right_table,model_GROUPING,stats_test);
            else
                [bilat_result_table,bilat_multi_compare_table,bilat_group_summary_stats] = calc_stats(bilat_table_standardized,model_GROUPING,stats_test);
                [left_result_table,left_multi_compare_table,left_group_summary_stats] = calc_stats(left_table_standardized,model_GROUPING,stats_test);
                [right_result_table,right_multi_compare_table,right_group_summary_stats] = calc_stats(right_table_standardized,model_GROUPING,stats_test);
            end

            %Defining the Stratificaiton into the result tables
            %that isadding in empties so we keep the main group naming.
            strat_record=strcat(big_table.Properties.VariableDescriptions{strat_column_idx},'=',group_names{m});
            bilat_strat_full=strcat('hemisphere=bilateral',32,strat_record);
            left_strat_full=strcat('hemisphere=left',32,strat_record);
            right_strat_full=strcat('hemisphere=right',32,strat_record);

            bilat_group_summary_stats.stratification=repmat({bilat_strat_full},size(bilat_group_summary_stats,1),1);
            left_group_summary_stats.stratification=repmat({left_strat_full},size(left_group_summary_stats,1),1);
            right_group_summary_stats.stratification=repmat({right_strat_full},size(right_group_summary_stats,1),1);

            bilat_result_table.stratification=repmat({bilat_strat_full},size(bilat_result_table,1),1);
            left_result_table.stratification=repmat({left_strat_full},size(left_result_table,1),1);
            right_result_table.stratification=repmat({right_strat_full},size(right_result_table,1),1);

            if size(bilat_multi_compare_table,1)>0
                bilat_multi_compare_table.stratification=repmat({bilat_strat_full},size(bilat_multi_compare_table,1),1);
                left_multi_compare_table.stratification=repmat({left_strat_full},size(left_multi_compare_table,1),1);
                right_multi_compare_table.stratification=repmat({right_strat_full},size(right_multi_compare_table,1),1);
            end

            %This needs to go on the smallest most useful unit for multicomparison otherwise we
            %can't get the BH calculated correctly -- ie don't to L/R/BI together

            bilat_result_table_BHFDR=calculate_BHFDR(bilat_result_table);
            left_result_table_BHFDR=calculate_BHFDR(left_result_table);
            right_result_table_BHFDR=calculate_BHFDR(right_result_table);

            %shift the saving location so it is in respect to the given filtering groups in the directory.
            output_paths_bilat=save_output_from_scalar_analysis(save_location,'Bilateral',group_names{m},group,subgroup,model_GROUPING,bilat_group_summary_stats,bilat_specimen_zscore,bilat_result_table_BHFDR,bilat_multi_compare_table);
            output_paths_left=save_output_from_scalar_analysis(save_location,'Left',group_names{m},group,subgroup,model_GROUPING,left_group_summary_stats,left_specimen_zscore,left_result_table_BHFDR,left_multi_compare_table);
            output_paths_right=save_output_from_scalar_analysis(save_location,'Right',group_names{m},group,subgroup,model_GROUPING,right_group_summary_stats,right_specimen_zscore,right_result_table_BHFDR,right_multi_compare_table);

            %% attempt to asssign all paths in one shot to output table
            height_paths_table=height(output_path_table);
            hemisphere=0;
            output_path_table(1+height_paths_table,:)={{hemisphere},{voxel_wise{o}},{strat_record},{output_paths_bilat.StatsResults}, {output_paths_bilat.Posthoc}, {output_paths_bilat.GroupTable}, {subject_data_table_path}};
            hemisphere=-1;
            output_path_table(2+height_paths_table,:)={{hemisphere},{voxel_wise{o}},{strat_record},{output_paths_left.StatsResults}, {output_paths_left.Posthoc}, {output_paths_left.GroupTable}, {subject_data_table_path}};
            hemisphere=1;
            output_path_table(3+height_paths_table,:)={{hemisphere},{voxel_wise{o}},{strat_record},{output_paths_right.StatsResults}, {output_paths_right.Posthoc}, {output_paths_right.GroupTable}, {subject_data_table_path}};
        end
    else

        left_table=big_table(big_table.hemisphere_assignment==-1,:);
        bilat_table=big_table(big_table.hemisphere_assignment==0,:);
        right_table=big_table(big_table.hemisphere_assignment==1,:);

        try
            if isempty(remove_zscore_grouping{i_testcondition})
                [bilat_specimen_zscore] = zscoring_finder(bilat_table,test_conditions{i_testcondition});
                [left_specimen_zscore] = zscoring_finder(left_table,test_conditions{i_testcondition});
                [right_specimen_zscore] = zscoring_finder(right_table,test_conditions{i_testcondition});
            else
                [bilat_table_standardized,bilat_specimen_zscore] = zscoring_finder(bilat_table,test_conditions{i_testcondition},remove_zscore_grouping{i_testcondition}{:});
                [left_table_standardized,left_specimen_zscore] = zscoring_finder(left_table,test_conditions{i_testcondition},remove_zscore_grouping{i_testcondition}{:});
                [right_table_standardized,right_specimen_zscore] = zscoring_finder(right_table,test_conditions{i_testcondition},remove_zscore_grouping{i_testcondition}{:});

                civm_write_table(bilat_table_standardized,fullfile(save_location,strcat('Bilat_Subject_Data_Table_ZScore_Standardized_by_',strjoin(remove_zscore_grouping{i_testcondition},'_'),'.csv')));
                civm_write_table(left_table_standardized,fullfile(save_location,strcat('Left_Subject_Data_Table_ZScore_Standardized_by_',strjoin(remove_zscore_grouping{i_testcondition},'_'),'.csv')));
                civm_write_table(right_table_standardized,fullfile(save_location,strcat('Right_Subject_Data_Table_ZScore_Standardized_by_',strjoin(remove_zscore_grouping{i_testcondition},'_'),'.csv')));

            end
        catch merr
            warning(merr.identifier,'zscoring_finder incomplete: %s',merr.message);
            %if it doesn't work we aren't trying to hard right now --
            %typically it is a string related issued with non
            %categorical terms

            bilat_specimen_zscore=table;
            left_specimen_zscore=table;
            right_specimen_zscore=table;
        end

        %Bilat, Left, and Right
        try
            if isempty(remove_zscore_grouping{i_testcondition})
                [bilat_result_table,bilat_multi_compare_table,bilat_group_summary_stats] = calc_stats(bilat_table,test_conditions{i_testcondition},stats_test);
                [left_result_table,left_multi_compare_table,left_group_summary_stats] = calc_stats(left_table,test_conditions{i_testcondition},stats_test);
                [right_result_table,right_multi_compare_table,right_group_summary_stats] = calc_stats(right_table,test_conditions{i_testcondition},stats_test);
            else
                [bilat_result_table,bilat_multi_compare_table,bilat_group_summary_stats] = calc_stats(bilat_table_standardized,test_conditions{i_testcondition},stats_test);
                [left_result_table,left_multi_compare_table,left_group_summary_stats] = calc_stats(left_table_standardized,test_conditions{i_testcondition},stats_test);
                [right_result_table,right_multi_compare_table,right_group_summary_stats] = calc_stats(right_table_standardized,test_conditions{i_testcondition},stats_test);

            end
        catch merr
            db_inplace(mfilename,'Error in calc stats');
        end

        bilat_strat_full='hemisphere=bilateral';
        left_strat_full='hemisphere=left';
        right_strat_full='hemisphere=right';

        %Defining the Stratificaiton into the result tables
        %that isadding in empties so we keep the main group naming.
        bilat_group_summary_stats.stratification=repmat({bilat_strat_full},size(bilat_group_summary_stats,1),1);
        left_group_summary_stats.stratification=repmat({left_strat_full},size(left_group_summary_stats,1),1);
        right_group_summary_stats.stratification=repmat({right_strat_full},size(right_group_summary_stats,1),1);

        bilat_result_table.stratification=repmat({bilat_strat_full},size(bilat_result_table,1),1);
        left_result_table.stratification=repmat({left_strat_full},size(left_result_table,1),1);
        right_result_table.stratification=repmat({right_strat_full},size(right_result_table,1),1);

        if size(bilat_multi_compare_table,1)>0
            bilat_multi_compare_table.stratification=repmat({bilat_strat_full},size(bilat_multi_compare_table,1),1);
            left_multi_compare_table.stratification=repmat({left_strat_full},size(left_multi_compare_table,1),1);
            right_multi_compare_table.stratification=repmat({right_strat_full},size(right_multi_compare_table,1),1);
        end

        %This needs to go on the smallest most useful unit for multicomparison otherwise we
        %can't get the BH calculated correctly -- ie don't to L/R/BI together
        bilat_result_table_BHFDR=calculate_BHFDR(bilat_result_table);
        left_result_table_BHFDR=calculate_BHFDR(left_result_table);
        right_result_table_BHFDR=calculate_BHFDR(right_result_table);

        output_paths_bilat=save_output_from_scalar_analysis(save_location,'Bilateral',[],group,subgroup,test_conditions{i_testcondition},bilat_group_summary_stats,bilat_specimen_zscore,bilat_result_table_BHFDR,bilat_multi_compare_table);
        output_paths_left=save_output_from_scalar_analysis(save_location,'Left',[],group,subgroup,test_conditions{i_testcondition},left_group_summary_stats,left_specimen_zscore,left_result_table_BHFDR,left_multi_compare_table);
        output_paths_right=save_output_from_scalar_analysis(save_location,'Right',[],group,subgroup,test_conditions{i_testcondition},right_group_summary_stats,right_specimen_zscore,right_result_table_BHFDR,right_multi_compare_table);

        %% attempt to assign all paths in one shot to output table
        height_paths_table=height(output_path_table);
        hemisphere=0;
        output_path_table(1+height_paths_table,:)={{hemisphere},{voxel_wise{o}},{'-'},{output_paths_bilat.StatsResults}, {output_paths_bilat.Posthoc}, {output_paths_bilat.GroupTable}, {subject_data_table_path}};
        hemisphere=-1;
        output_path_table(2+height_paths_table,:)={{hemisphere},{voxel_wise{o}},{'-'},{output_paths_left.StatsResults}, {output_paths_left.Posthoc}, {output_paths_left.GroupTable}, {subject_data_table_path}};
        hemisphere=1;
        output_path_table(3+height_paths_table,:)={{hemisphere},{voxel_wise{o}},{'-'},{output_paths_right.StatsResults}, {output_paths_right.Posthoc}, {output_paths_right.GroupTable}, {subject_data_table_path}};
    end
end
end
