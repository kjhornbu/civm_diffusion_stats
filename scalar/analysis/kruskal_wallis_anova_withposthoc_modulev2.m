function [output_fullspecification,Multi_Compare,name_table] = kruskal_wallis_anova_withposthoc_modulev2(...
    data_subtable,stats_test,name_table,nway_analysis_set,length_name_nointeraction_table)

% silly "tables are slow" optimization, just looking at the variable names
% is slow, so we pull it out ahead.
data_subtable_columns=data_subtable.Properties.VariableNames;

check_rob_sheet=sum(~cellfun(@isempty,regexpi(data_subtable_columns,'GN_Symbol')));
%{
name_table=table;
%% individual Covaraiates 
for n=1:numel(zscore_grouping)
    if ischar(zscore_grouping{n})
        % Need to unwrap the names correctly for feeding into the system
        zscore_GROUPING=zscore_grouping(n);
        name_separate=strsplit(zscore_GROUPING{:},'group');
    else
        zscore_GROUPING=zscore_grouping{n};
        name_separate=strsplit(zscore_GROUPING,'group');
    end
    name_table.idx{n}=n;
    name_table.matrix{n}=zeros(1,numel(zscore_grouping));
    name_table.matrix{n}(n)=1;

    check_subgroup_1=(regexp(name_separate{1},'sub')==1)&(~isempty(name_separate{end}));
    if ~isempty(check_subgroup_1)&&check_subgroup_1==1
        name_table.group_type{n}=stats_test.subgroup_name{str2double(name_separate{end})};
    elseif (isempty(name_separate{1}))&(~isempty(name_separate{end}))
        name_table.group_type{n}=stats_test.group_name{str2double(name_separate{end})};
    elseif (isempty(name_separate{1}))&(isempty(name_separate{end}))
        %for group 1 we have the ability to not add the 1 after wards so
        %just pull it directly
        name_table.group_type{n}=stats_test.group_name{1};
    else
        keyboard;
        %groups are being weird you need to double check people are using the
        %correct subgroup[0-9] and group|group[0-9] terms
    end

    [group,group_name,group_name_idx]=find_group_information_from_groupingcriteria(data_subtable,zscore_GROUPING);

    nway_analysis_set{:,n}=group(:);
    name_table.group_separators{n}=group_name(:)';
    name_table.N{n}=sum(group_name_idx==1:size(group_name,1),1);

    %find variables that are continous which are things that aren't
    %strings/char (doubles are entries like age while "young" is a binary category)...
    %You might want to add it as an option in the stats_test on load...
    if iscell(group(1))
        name_table.continous(n)=false;
    else
        name_table.continous(n)=true;
    end

    %Set the Effect Type
    if (regexp(name_separate{1},'sub')==1)&(~isempty(name_separate{end}))
        name_table.effect_type{n}=stats_test.effect_type_subgroup{str2double(name_separate{end})};

    elseif (isempty(name_separate{1}))&(~isempty(name_separate{end}))
        name_table.effect_type{n}=stats_test.effect_type_group{str2double(name_separate{end})};

    elseif (isempty(name_separate{1}))&(isempty(name_separate{end}))
        %for group 1 we have the ability to not add the 1 after wards so
        %just pull it directly
        name_table.effect_type{n}=stats_test.effect_type_group{1};
    else
        keyboard;
        %groups are being weird you need to double check people are using the
        %correct subgroup[0-9] and group|group[0-9] terms
    end
end

length_name_nointeraction_table=size(name_table,1);

%% interaction component finder
if size(zscore_grouping,2)~=1
    %Full interaction setting
    for full_setting=1:size(zscore_grouping,2)-1
        length_name_table=size(name_table,1);
        interaction_set=nchoosek(1:size(zscore_grouping,2),1+full_setting);

        for n=1:size(interaction_set,1)
            test_interaction_set=zscore_grouping(interaction_set(n,:)); %pull the terms?
            % slow line (6.5s), do we need to clear this?
            clear temp_group_type
            for index_test_interaction=1:size(test_interaction_set,2)
                if ischar(test_interaction_set{index_test_interaction})
                    % Need to unwrap the names correctly for feeding into the system
                    zscore_GROUPING_1=test_interaction_set(index_test_interaction);
                    name_separate_1=strsplit(zscore_GROUPING_1{:},'group');
                else
                    zscore_GROUPING_1=test_interaction_set{index_test_interaction};
                    name_separate_1=strsplit(zscore_GROUPING_1,'group');
                end
                % slow line (12.4s), can we preallocate this?
                name_table.idx{length_name_table+n}=interaction_set(n,:);
                name_table.matrix{length_name_table+n}=zeros(1,numel(zscore_grouping));
                name_table.matrix{length_name_table+n}(interaction_set(n,:))=1;

                check_subgroup_1=(regexp(name_separate_1{1},'sub')==1)&(~isempty(name_separate_1{end}));
                if ~isempty(check_subgroup_1)&&check_subgroup_1==1
                    temp_group_type{index_test_interaction}=stats_test.subgroup_name{str2double(name_separate_1{end})};
                elseif (isempty(name_separate_1{1}))&(~isempty(name_separate_1{end}))
                    temp_group_type{index_test_interaction}=stats_test.group_name{str2double(name_separate_1{end})};
                elseif (isempty(name_separate_1{1}))&(isempty(name_separate_1{end}))
                    %for group 1 we have the ability to not add the 1 after wards so
                    %just pull it directly
                    temp_group_type{index_test_interaction}=stats_test.group_name{1};
                else
                    keyboard;
                    %groups are being weird you need to double check people are using the
                    %correct subgroup[0-9] and group|group[0-9] terms
                end
            end

            name_table.group_type{length_name_table+n}=strjoin(temp_group_type(:),'*'); %this will always indicate A+B+A:B which is useufl if the full iteraction is kept. 
            
            % slow line (20s,19.5s), Can this be cached?
            [group,group_name,group_name_idx]=find_group_information_from_groupingcriteria(data_subtable,test_interaction_set);

            name_table.group_separators{length_name_table+n}=group_name(:)';
            name_table.N{length_name_table+n}=sum(group_name_idx==1:size(group_name,1),1);

            for m=1:size(interaction_set(n,:),2)
                temp_effect_type{m}=name_table.effect_type{interaction_set(n,m)};
                temp_continous(m)=name_table.continous(interaction_set(n,m));
            end

            name_table.continous(length_name_table+n)=sum(temp_continous)>0;

            if sum(~cellfun(@isempty,regexpi(temp_effect_type,'random')))>0
                name_table.effect_type{length_name_table+n}='random';
            else
                name_table.effect_type{length_name_table+n}='fixed';
            end
        end
    end
end

%% The cross Calculation
% counts the occurance of the given character to know how many interactions
% are present in each one.
check_interaction=regexp(name_table.group_type,'*');
for n=1:size(name_table,1)
    name_table.cross_number(n)=numel(check_interaction{n});
end

%}
%% Where does the data exist in the array
data_cells=regexpi(data_subtable_columns,'(_mean|voxels|volume_mm3|volume_fraction)$');
data_idx=find(~cellfun(@isempty,data_cells)==1); %actual idx not in logical array format
data_name=data_subtable_columns(data_idx);

%% Now do the actual data processing
output=table;
Multi_Compare=table;

cont_logical_idx=((name_table.continous==1)')&(name_table.cross_number<=0); %need the non interaction terms
cont_positional_idx=find(cont_logical_idx==1);

random_logical_idx=~cellfun(@isempty,regexp(name_table.effect_type,'[Rr]andom'))&(name_table.cross_number<=0); %need the non interaction terms
random_positional_idx=find(random_logical_idx==1);

for n=1:size(name_table,1)
    harmonic_mean(n)=harmmean(name_table.N{n},2);
end

for n=1:size(name_table,1)
    check(n,:)=sum(stats_test.matrix{1}==name_table.matrix{n},2)>=length_name_nointeraction_table;
end

name_table=name_table(sum(check,2)>0,:);

% create cell to hold any multi-compare outputs
multi_compare_struct_arrays=cell(size(data_name));

multi_compare_template=struct;
multi_compare_template.Structure='';
multi_compare_template.ROI=nan;
multi_compare_template.contrast='';
multi_compare_template.source_of_variation='';
multi_compare_template.Initial_Study_Model='';
multi_compare_template.Initial_Statistical_Test='';
multi_compare_template.Group_A='';
multi_compare_template.Group_B='';
multi_compare_template.Pval=nan;



% for "speed" convert releveant part of table to struct
data_substruct=table2struct(data_subtable(:,data_idx));
group_types=name_table.group_type(1:length_name_nointeraction_table);
for d_idx=1:numel(data_idx)
    multi_compare_single_contrast(1)=multi_compare_template;
    multi_compare_single_contrast(1)=[];

    if sum(~isnan(data_subtable.(data_name{d_idx})))>0
        %The everything interaction!
        harmonic_puller=logical(ones(size(name_table,1),1));
        %interaction number is number of crosses for the entry in the table so a 4 way
        %interaction has 3 crosses therefore 3... just the main factor is called a 0
        %interaction in my table for this reason (no crosses) while in reality it is 1 as consider by matlab.
        %that means to get the N way correctly based on our entries we actually start out with N+1
        try
            % slow line (42.5s).
            % data_vector = table2array(data_subtable(:,data_idx(d_idx)))
            data_vector=[ data_substruct.(data_name{d_idx}) ];

             [p, tbl,stats] = kruskalwallis(data_vector,nway_analysis_set{1},'off');
             
        catch
            keyboard;
        end

        length_output=(height(name_table)+1)*(d_idx-1);
        
        % slow line (2.3) OR slow lines, and maybe we should change how we
        % handle data interanlly(maybe a struct?, or a cell array we
        % concatenate at the very end?)
        %Grabbing first element for entry in the data subtable
        %because they should all be the same region
        num_lines_to_add=numel(p)+1;
        %output.ROI(length_output+(1:num_lines_to_add))=repmat(data_subtable.ROI(1),num_lines_to_add,1);
        output.ROI(length_output+(1:num_lines_to_add))=data_subtable.ROI(1);
        %output.Structure(length_output+(1:num_lines_to_add))=repmat(data_subtable.Structure(1),num_lines_to_add,1);
        % slow line ... ? (5s,5.3s)
        output.contrast(length_output+(1:num_lines_to_add))=data_name(d_idx);
        %Any partial model or no interaction model just add terms
        %together
        output.study_model(length_output+(1:num_lines_to_add))=name_table.group_type{1};
        output.statistical_test(length_output+(1:num_lines_to_add))={'KruskalWallis: Non-parametric One-Way ANOVA on Ranks'};
        output.source_of_variation(length_output+(1:num_lines_to_add))=name_table.group_type{1};
        output.sum_of_squares(length_output+(1:num_lines_to_add))=tbl(2:end-1,2);
        output.df(length_output+(1:num_lines_to_add))=tbl(2:end-1,3);
        %output.Chi_Squared_Statistic(length_output+(1:num_lines_to_add))=tbl(2:end-1,5);

        Number_of_Groupings=cellfun(@numel,name_table.N);
        Number_of_Groupings(~harmonic_puller)=0;
        output.Number_of_Groupings(length_output+(1:num_lines_to_add))=[Number_of_Groupings;0];
        %{
        positional_harmonic_puller=find(harmonic_puller==1);
        for n=1:numel(positional_harmonic_puller)
            % while tehse two lines do take a bunch of time, in testing
            % that is because they're called MANY times(24948)! 
            % Can we somehow call them less? Can we cache this information?
            % slow line (4.4s)
            idx=~cellfun(@isempty,regexpi(strrep(name_table.group_type,'*',':'),strcat('^(',strrep(tbl{1+n,1},'*',':'),')$')));
            % slow line (6.7s)
            output.Number_of_Groupings(length_output+n)=numel(name_table.N{idx});
        end
        %}
        
        output.pval(length_output+(1:numel(p)))=p;
        
        %Make the harmonic mean the number you actually end up with
        harmonic_mean=harmonic_mean(harmonic_puller);

        for n=1:numel(p)
            output.eta2(length_output+n)=tbl{1+n,2}/tbl{end,2}; % use the SS ttotal here!

            %       Eta2 = SSeffect / SStotal, where:
            %SSeffect is the sums of squares for the effect you are studying.
            %SStotal is the total sums of squares for all effects, errors and interactions in the ANOVA study.
            % You might also see the formula written, equivalently, as: Eta2 = SSbetween / SStotal
            %https://www.statisticshowto.com/eta-squared/

            output.H2RI(length_output+n)=tbl{1+n,2}/(sum([tbl{2:end-2,2}])+(tbl{end-1,2}/harmonic_mean(n)));
            %output.H2RI(length_output+n)=%Va / (Va+(Ve/n)) Ve is error
            %term and Va is the effect but we want to sum up all effect but hte
            %errors only are edited by the harmonic mean (the equation is the
            %simple one from genenetwork for a 1 way anova--https://genenetwork.org/glossary/#h
        end
        output.cohenF(length_output+(1:numel(p)))=sqrt(output.eta2(length_output+(1:numel(p)))./(1-output.eta2(length_output+(1:numel(p)))));

        %Error term entries tacked onto the end.
        output.Number_of_Groupings(length_output+num_lines_to_add)=NaN;
        output.pval(length_output+num_lines_to_add)=NaN;
        output.eta2(length_output+num_lines_to_add)=NaN;
        output.H2RI(length_output+num_lines_to_add)=NaN;
        output.cohenF(length_output+num_lines_to_add)=NaN;

        %% Checking For PostHoc

        %Pull only the data we are currently working in not the whole sheet!
        check_raw_sig=output.pval(length_output+(1:numel(p)))<stats_test.pval_threshold;

        if any(check_raw_sig) %if any entry is non-zero -- that is significantly changed at threshold level, then do the multi-compare checking
            % slow line (2.7s,3s)
            sig_name_table_subset=name_table(check_raw_sig,:);
            %with IDX we can do Interaction and non interaction at the same
            %time.

            number_of_group_separators=cellfun(@numel,sig_name_table_subset.group_separators);

            % get the count of things we'll have for ouput
            multi_compare_entries=0;
            for m=1:size(sig_name_table_subset,1)
                if number_of_group_separators(m) > 2
                    % add to preallocation requirement
                    multi_compare_entries=multi_compare_entries+nchoosek(number_of_group_separators(m),2);
                end
            end
            
            if multi_compare_entries
                multi_compare_single_contrast(multi_compare_entries)=multi_compare_template;
            end
 
            length_multicompare=0;
            use_table_code=false;
            for m=1:size(sig_name_table_subset,1)
                % slow line (2.4s)
                if number_of_group_separators(m) > 2
                    %only add multi compare if there are more than two groups in the study and we don't have a nan pvalue
                    % slow line (14.3s)
                    [comparison,~,~,gnames] = multcompare(stats,'Dimension',sig_name_table_subset.idx{m},'ctype','dunn-sidak','Display','off');
                    %This is a fairly standard middle of the road multi comparision
                    %post hoc test that has medium conservativeness https://www.mathworks.com/help/stats/multiple-comparisons.html#bum7ue_-1

                    [matches,~]=regexp(gnames,'[^=,]+=([^=,]+)','tokens');

                    for match_length=1:numel(matches)
                        m_single=matches{match_length};
                        cleaned_gnames{match_length,1}=strjoin([m_single{:}],' ');
                    end

                    insertion_idx=length_multicompare+(1:size(comparison,1));
                    [multi_compare_single_contrast(insertion_idx).Structure]=deal(data_subtable.Structure{1});
                    [multi_compare_single_contrast(insertion_idx).ROI]=deal(data_subtable.ROI(1));
                    [multi_compare_single_contrast(insertion_idx).contrast]=deal(data_name(d_idx));
                    [multi_compare_single_contrast(insertion_idx).source_of_variation]=deal(name_table.group_type{1});
                    [multi_compare_single_contrast(insertion_idx).Initial_Study_Model]=deal(name_table.group_type{1});
                    [multi_compare_single_contrast(insertion_idx).Initial_Statistical_Test]=deal('KruskalWallis: Non-parametric One-Way ANOVA on Ranks');

                    [multi_compare_single_contrast(insertion_idx).Group_A]=cleaned_gnames{comparison(:,1)};
                    [multi_compare_single_contrast(insertion_idx).Group_B]=cleaned_gnames{comparison(:,2)};
                    tmp=num2cell(comparison(:,end));
                    [multi_compare_single_contrast(insertion_idx).Pval]=deal(tmp{:});

                    if use_table_code
                        length_multicompare=size(Multi_Compare,1);
                        % slow line (5s,4.9s), this slowness is probably due to
                        % preallocation, we should convert preallocate(like ouptut), and maybe convert to struct array
                        %Grabbing first element for entry in the data subtable
                        %because they should all be the same region
                        Multi_Compare.Structure(length_multicompare+(1:size(comparison,1)))=data_subtable.Structure(1);
                        Multi_Compare.ROI(length_multicompare+(1:size(comparison,1)))=data_subtable.ROI(1);
                        Multi_Compare.contrast(length_multicompare+(1:size(comparison,1)))=data_name(d_idx);
                        Multi_Compare.source_of_variation(length_multicompare+(1:size(comparison,1)))=name_table.group_type{1};
                        Multi_Compare.Initial_Study_Model(length_multicompare+(1:size(comparison,1)))=name_table.group_type{1};
                        Multi_Compare.Initial_Statistical_Test(length_multicompare+(1:size(comparison,1)))={'KruskalWallis: Non-parametric One-Way ANOVA on Ranks'};

                        Multi_Compare.Group_A(length_multicompare+(1:size(comparison,1)))=cleaned_gnames(comparison(:,1));
                        Multi_Compare.Group_B(length_multicompare+(1:size(comparison,1)))=cleaned_gnames(comparison(:,2));
                        Multi_Compare.Pval(length_multicompare+(1:size(comparison,1)))=comparison(:,end);
                    end

                    length_multicompare=length_multicompare+nchoosek(number_of_group_separators(m),2);

                end
            end
        end
  
    end
    % Check and allocate
    if d_idx==1
        % slow line (2.1s) hard to avoid without dramatic changes to
        % calling function.
        output.ROI((height(name_table)+1)*numel(data_name))=NaN;
    end

    %Now I need to put that information set onto the data in a way that is
    %understanble...
    multi_compare_struct_arrays{d_idx}=multi_compare_single_contrast;
    clear sig_name_table_subset multi_compare_single_contrast
end

try
    Multi_Compare=struct2table( horzcat(multi_compare_struct_arrays{:}) );
catch
    keyboard;
end
% Add bookkeeping information
if check_rob_sheet==1
    Bookkeeping_group_summary_list={'ROI','Structure','hemisphere_assignment','GN_Symbol','ARA_abbrev','id64_fSABI','id32_fSABI','Structure_id','GroupCount'};
elseif check_rob_sheet==0
    Bookkeeping_group_summary_list={'ROI','Structure','hemisphere_assignment','acronym','name','id64','id32','Structure_id','GroupCount'};

end

data_grouping_regex=strcat('^(',strjoin(Bookkeeping_group_summary_list,'|'),')$');

Information_idx=regexpi(data_subtable_columns,data_grouping_regex);
Information_positional_idx=~cellfun(@isempty,Information_idx);
% slow line (1.9s,2s)
InformationSet=unique(data_subtable(:,Information_positional_idx),'rows');

% slow line (6.8s,7.1s) dont think there is an easy way to avoid that.
output_fullspecification=outerjoin(InformationSet,output,'MergeKeys',true);
end