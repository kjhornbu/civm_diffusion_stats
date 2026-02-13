function Path_table = Generate_PairwiseSheet_Plotting(Path_table,pairwise_comparisons,pvalue_type,pval_threshold,Key_Grouping_Columns)
%Path_Table: Stats Analysis output paths
%pairwise_comparisons: control v. treatment comparisions we wish to
%investigate

assert(numel(pairwise_comparisons)==1,'We don''t currently support multiple stats test in 1 go -- for scalar stats. You need to call scalar processing main multiple times yourself --- connectomics can do stratified.');

if strcmp(pvalue_type,'pval_BH')
    fig_dir_name='figures';
elseif strcmp(pvalue_type,'pval')
    fig_dir_name='figures_withoutFDR';
else
    keyboard;
end

if ~istable(Path_table)
    Path_table=civm_read_table(Path_table);
end

last_table_loaded=cell(1,3);
for n=1:height(Path_table)
    % Figure out which stratifications are in play here and convert to
    % words (each hemisphere, each erode condition)
    try
        hemisphere=uncell(Path_table.hemisphere(n));
    catch merr
        warning(merr.identifier,'trouble grabing hemisphere: %s',merr.message);
        hemisphere=Path_table.hemisphere(n);
    end

    processed_stats_dir=fileparts(Path_table.StatsResults{n});
    figure_dir=fullfile(processed_stats_dir,fig_dir_name);
    out_file=fullfile(processed_stats_dir,strcat('Group_Statistical_Results_',strjoin(Key_Grouping_Columns{1},'_'),'.csv'));

    if file_time_check(out_file, 'newer', Path_table.GroupTable{n}) && exist(figure_dir,'dir')
        % we think our output is newer, so we can skip re-creating.
        Path_table.StatsResults{n}=out_file;
        continue;
    end

    % load
    if isempty(last_table_loaded{1}) || ~strcmp(last_table_loaded{1},Path_table.SubjectTable{n})
        %Only load the data if we have a change in the subject data table path
        %idx
        Full_SubjectTable=civm_read_table(Path_table.SubjectTable{n});
        last_table_loaded{1}=Path_table.SubjectTable{n};
    end

    % force important columns to text
    Full_SubjectTable=column2text(Full_SubjectTable,Key_Grouping_Columns);

    %Filter to just the single hemisphere we are on
    Subject_Table=Full_SubjectTable(Full_SubjectTable.hemisphere_assignment==hemisphere,:);

    % Filter out the missing ROIs
    [GN_names,~,GN_name_idx]=unique(Subject_Table.GN_Symbol);
    specimen=unique(Subject_Table.specimen);

    missing_ROI_logical_idx = sum(GN_name_idx==1:numel(GN_names))<numel(specimen);
    Name_Check=strcat('^(',GN_names(missing_ROI_logical_idx),')$');

    % Load Group_Table
    if isempty(last_table_loaded{2}) || ~strcmp(last_table_loaded{2},Path_table.GroupTable{n})
        Group_Table=civm_read_table(Path_table.GroupTable{n});
        Group_Table=column2text(Group_Table,Key_Grouping_Columns);

        last_table_loaded{2}=Path_table.GroupTable{n};
    end
    % Load Statistical_Results
    if isempty(last_table_loaded{3}) || ~strcmp(last_table_loaded{3},Path_table.StatsResults{n})
        Statistical_Results=civm_read_table(Path_table.StatsResults{n});
        last_table_loaded{3}=Path_table.StatsResults{n};
    end

    if isempty(Name_Check)
        % remove Error term which is not useful for plotting
        Non_ErrorTerms_idx=cellfun(@isempty,regexpi(Statistical_Results.source_of_variation,'Error'));
        Statistical_Results=Statistical_Results(Non_ErrorTerms_idx,:);

    else
        % if we're revoing indicies we'll need to reload tables
        last_table_loaded{1}={};
        last_table_loaded{2}={};
        last_table_loaded{3}={};

        % Remove from Subject Table
        remove_idx_SubjectTable=~cellfun(@isempty,regexpi(Subject_Table.GN_Symbol,Name_Check));
        Subject_Table(remove_idx_SubjectTable,:)=[];

        % Remove from Group_Table
        remove_idx_GroupTable=~cellfun(@isempty,regexpi(Group_Table.GN_Symbol,Name_Check));
        Group_Table(remove_idx_GroupTable,:)=[];

        % Remove from Statistical_Results

        %remove missing ROI
        remove_idx_Statistical_Results=~cellfun(@isempty,regexpi(Statistical_Results.GN_Symbol,Name_Check));
        Statistical_Results(remove_idx_Statistical_Results,:)=[];

        %remove Error term which is not useful for plotting
        Non_ErrorTerms_idx=cellfun(@isempty,regexpi(Statistical_Results.source_of_variation,'Error'));
        Statistical_Results=Statistical_Results(Non_ErrorTerms_idx,:);
    end
    %
    %     % EXPERIMENTAL DO-NOT REPEAT code
    %     % This makes it so I can't do the follow on Figure type
    %     if ~exist(out_file,'file')

    %each hemisphere, each erode condition
    mean_idx=column_find(Group_Table.Properties.VariableNames,'_group_mean');
    std_idx=column_find(Group_Table.Properties.VariableNames,'_group_std');

    Statistical_Results_wPairwise=cell(size(mean_idx));

    for m=1:numel(mean_idx)
        name_mean=Group_Table.Properties.VariableNames{mean_idx(m)};
        name_std=Group_Table.Properties.VariableNames{std_idx(m)};
        [Pairwise_Contrast] = find_pairwise_compare(Group_Table,pairwise_comparisons{1},name_mean,name_std);

        cleaned_contrast_name=strsplit(name_mean,'_group_mean');
        Pairwise_Contrast.contrast=repmat(cleaned_contrast_name(1),height(Pairwise_Contrast),1);
        cleaned_contrast_name{1} = strcat('^',cleaned_contrast_name{1},'$');
        idx=row_find(Statistical_Results,'contrast',cleaned_contrast_name{1});
        Filtered_Statistical_Results=Statistical_Results(idx,:);

        Bookkeeping_group_summary_list={'ROI','Structure','hemisphere_assignment','acronym','name','id64','id32','id64_fSABI','id32_fSABI','structure_id'};
        Bookkeeping_grouping_idx=regexpi(Pairwise_Contrast.Properties.VariableNames,strcat('^(',strjoin(Bookkeeping_group_summary_list,'|'),')$'));
        Bookkeeping_grouping_logical_idx=~cellfun(@isempty,Bookkeeping_grouping_idx);
        Bookkeeping_grouping_names=Pairwise_Contrast.Properties.VariableNames(Bookkeeping_grouping_logical_idx);

        Statistical_Results_wPairwise{m}=join(Filtered_Statistical_Results,Pairwise_Contrast,'Keys',{'ROI','contrast'},'KeepOneCopy',Bookkeeping_grouping_names);
    end

    Statistical_Results_wPairwise_FullTable=vertcat(Statistical_Results_wPairwise{:});

    thresholds=[0.001, 0.01, 0.05, 0.1 1];
    symbols={'***','**','*','.' ,'ns'};

    for threshold=numel(thresholds):-1:1
        Statistical_Results_wPairwise_FullTable.Pval_BH_Symbol(Statistical_Results_wPairwise_FullTable.pval_BH<thresholds(threshold))=symbols(threshold);
    end
    for threshold = numel(thresholds):-1:1
        Statistical_Results_wPairwise_FullTable.Pval_Symbol(Statistical_Results_wPairwise_FullTable.pval<thresholds(threshold))=symbols(threshold);
    end

    %     thresholds=[0.05, 0.1, 0.2, 0.5 1];
    %     symbols={'1','2','3','4','0'};
    %
    %     for threshold=numel(thresholds):-1:1
    %         Statistical_Results_wPairwise_FullTable.Pval_BH_Threshold(Statistical_Results_wPairwise_FullTable.pval_BH<thresholds(threshold))=symbols(threshold);
    %     end
    %     for threshold = numel(thresholds):-1:1
    %         Statistical_Results_wPairwise_FullTable.Pval_Threshold(Statistical_Results_wPairwise_FullTable.pval<thresholds(threshold))=symbols(threshold);
    %     end

    % deferring save to the end to allow it to act as simple flag for
    % completion
    civm_write_table(Statistical_Results_wPairwise_FullTable,out_file);
    Path_table.StatsResults{n}=out_file;

    %     else
    %         warning('Not reprocessing %s',out_file);
    %         Statistical_Results_wPairwise_FullTable=civm_read_table(out_file);
    %         %continue;
    %     end
    % *** cleverly *** sort table based on the pairwise comparison we're
    % doing, this helps print things in desireable and constant
    % order(provided we dont accidentally re-sort data). 2026-02-05 Is this
    % what is blowing us up here???
    Subject_Table=sort_table_by_pairwise(Subject_Table,pairwise_comparisons{1});
    Group_Table=sort_table_by_pairwise(Group_Table,pairwise_comparisons{1});


    generate_figures(figure_dir, ...
        Subject_Table,Group_Table,Statistical_Results_wPairwise_FullTable, ...
        pvalue_type,pval_threshold,Key_Grouping_Columns{1});
end
end

function [s_tab]=sort_table_by_pairwise(s_tab,pairwise_comparisons)
s_tab.pairwise_sorting=zeros(height(s_tab),1);
for n=1:size(pairwise_comparisons,2)
    [A_idx,B_idx,~]=select_AB(s_tab,pairwise_comparisons(:,n));
    sort_val_A=100^-(n);
    sort_val_B=100^-(n-1);
    s_tab.pairwise_sorting(A_idx)=s_tab.pairwise_sorting(A_idx)+sort_val_A;
    s_tab.pairwise_sorting(B_idx)=s_tab.pairwise_sorting(B_idx)+sort_val_B;
end
s_tab=sortrows(s_tab,'pairwise_sorting');
s_tab.pairwise_sorting=[];
end
