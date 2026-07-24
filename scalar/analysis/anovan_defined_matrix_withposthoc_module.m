function [output_fullspecification,Multi_Compare,name_table] = anovan_defined_matrix_withposthoc_module(...
    data_subtable,stats_test,name_table,nway_analysis_set,length_name_nointeraction_table)

% silly "tables are slow" optimization, just looking at the variable names
% is slow, so we pull it out ahead.
data_subtable_columns=data_subtable.Properties.VariableNames;

check_rob_sheet=sum(~cellfun(@isempty,regexpi(data_subtable_columns,'GN_Symbol')));

%% Where does the data exist in the array
data_cells=regexpi(data_subtable_columns,'(_mean|voxels|volume_mm3|volume_fraction)$');
data_idx=find(~cellfun(@isempty,data_cells)==1); %actual idx not in logical array format
data_name=data_subtable_columns(data_idx);

%% Now do the actual data processing
output=table;
Multi_Compare=table;

try
    for n=1:size(name_table,1)
        check(n,:)=sum(stats_test.matrix{1}==name_table.matrix{n},2)>=length_name_nointeraction_table;
    end
catch exception
    keyboard;
end

length_name_nointeraction_table=sum(and(sum(check,2),name_table.cross_number<=0)); %update the no_interaction length based on if we reduce the number of terms in the table.
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

% for "speed" convert data part of data_subtable to a struct.
data_substruct=table2struct(data_subtable(:,data_idx));
group_types_no_interaction=name_table.group_type(1:length_name_nointeraction_table);
if sum(name_table.cross_number<=0) ~= numel(nway_analysis_set)
    nway_analysis_set_temp=nway_analysis_set(name_table.idx{:});
    clear nway_analysis_set;
    nway_analysis_set=nway_analysis_set_temp;
end

% remove zeros in the model settting that are not appropriate anymore
if size(stats_test.matrix{1},2)> length_name_nointeraction_table
    temp_matrix=stats_test.matrix{1};
    clear stats_test.matrix{1};
    matrix_logical_idx=size(temp_matrix)>length_name_nointeraction_table; % this is what is too big so you have to NOT it to get what you want.
    stats_test.matrix{1}=temp_matrix(~matrix_logical_idx);
end

cont_logical_idx=((name_table.continous==1)')&(name_table.cross_number<=0); %need the non interaction terms for continuous terms
cont_positional_idx=find(cont_logical_idx==1);

random_logical_idx=~cellfun(@isempty,regexp(name_table.effect_type,'[Rr]andom'))&(name_table.cross_number<=0); %need the non interaction terms for random terms
random_positional_idx=find(random_logical_idx==1);

num_lines_to_add=size(stats_test.matrix{1},1) + 2;
harmonic_puller=logical(ones(size(name_table,1),1));

for d_idx=1:numel(data_idx)
    multi_compare_single_contrast(1)=multi_compare_template;
    multi_compare_single_contrast(1)=[];
    length_output=(height(name_table)+2)*(d_idx-1);
    output_lines=length_output+(1:num_lines_to_add);

    % Checking if there are holes in the data that is one or sets of
    % specimen have NaN within it.
    if sum(~isnan(data_subtable.(data_name{d_idx})))>0
        %The everything interaction!
        %harmonic_puller=logical(ones(size(name_table,1),1));
        %interaction number is number of crosses for the entry in the table so a 4 way
        %interaction has 3 crosses therefore 3... just the main factor is called a 0
        %interaction in my table for this reason (no crosses) while in reality it is 1 as consider by matlab.
        %that means to get the N way correctly based on our entries we actually start out with N+1

        data_vector=[ data_substruct.(data_name{d_idx}) ];
        [p, tbl,stats] = anovan(data_vector, ...
            nway_analysis_set,...
            'model', stats_test.matrix{1}, ...
            'varnames', group_types_no_interaction,...
            'continuous', cont_positional_idx,...
            'random', random_positional_idx,...
            'display','off');

        positional_idx=find(cell2mat(tbl(2:end,4)))+1;
        singular_terms=tbl(positional_idx,1);

        assert(nnz(cell2mat(tbl(2:end,4))==1)==0,sprintf('Model is not Full Rank for terms: %s. You cannot run the model as specified! Likely variability too low for one term you added or data groupings are too sparse to model properly! Use crosstab(grouping terms) to check sparsity, remove least dense source-dimension, and try again.',strjoin(singular_terms,', ')));

            % WE do the default here which is a type 3 -- type 3 means
            % calculate all SS in a iterative series 3
            %Type III sum of squares. The reduction in residual sum of squares
            % obtained by adding that term to a model containing all other terms,
            % but with their effects constrained to obey the usual "sigma restrictions"
            % that make models estimable.
            % NEED TO ADD IN SS Total because not nessisarily SSE + SSModel
            % = SST 

        if numel(nway_analysis_set{1})==numel(data_vector)

            % slow line (2.3) OR slow lines, and maybe we should change how we
            % handle data interanlly(maybe a struct?, or a cell array we
            % concatenate at the very end?)
            %Grabbing first element for entry in the data subtable
            %because they should all be the same region
            %num_lines_to_add=numel(p)+1;

            output.ROI(output_lines)=data_subtable.ROI(1);
            output.contrast(output_lines)=data_name(d_idx);
            output.study_model(output_lines)={strjoin(strrep(tbl(2:end-2,1),'*',':'),'+')};
            output.statistical_test(output_lines)={'N-Way ANOVA'};
            output.source_of_variation(output_lines)=strrep(tbl(2:end,1),'*',':');
            output.sum_of_squares(output_lines)=[tbl{2:end,2}];
            output.df(output_lines)=[tbl{2:end,3}];
            output.F_Statistic(output_lines)=[tbl{2:end-2,6},NaN, NaN]; %The Error and Total term has not F_statistic

            output.pval(length_output+(1:numel(p)))=p;

            for n=1:numel(p)
                output.eta2(length_output+n)=tbl{1+n,2}/tbl{end,2}; % use the SS ttotal here!
                %       Eta2 = SSeffect / SStotal, where:
                %SSeffect is the sums of squares for the effect you are studying.
                %SStotal is the total sums of squares for all effects, errors and interactions in the ANOVA study.
                % You might also see the formula written, equivalently, as: Eta2 = SSbetween / SStotal
                %https://www.statisticshowto.com/eta-squared/

                %OURS IS A FULL HERE IT IS THE VARIATION UNIQUELY ACCOUNTED
                %BY THE TERM!

                % Partial eta squared (\(\eta _{p}^{2}\)) is an effect size measure in ANOVA ...
                % that calculates the proportion of variance in a dependent variable uniquely ...
                % explained by a specific independent variable, while partialing out (ignoring) ...
                % the variance accounted for by other variables and
                % interactions in the model ep^2 = SSEeffect/(SSeffect +
                % SSerror)
            end

            inf_locations = find(output.F_Statistic==Inf);
           
            if inf_locations
                keyboard;
                % MAybe we want to do these but I put this back within just
                % in case for now.
                output.df(inf_locations)=0;
                output.F_Statistic(inf_locations)=NaN;
                output.pval(inf_locations)=NaN;
                output.eta2(inf_locations)=NaN;
            end

            output.cohenF(length_output+(1:numel(p)))=sqrt(output.eta2(length_output+(1:numel(p)))./(1-output.eta2(length_output+(1:numel(p)))));

            %% Do Error and Total on the End

            %Error term entries tacked onto the end. makes it easier for us
            %to repair if there is a processing problem.
            output.pval(length_output+((numel(p)+1):num_lines_to_add))=NaN;
            output.eta2(length_output+((numel(p)+1):num_lines_to_add))=NaN;
            output.cohenF(length_output+((numel(p)+1):num_lines_to_add))=NaN;

        else
            %Bookkeeping if our N drops because a specimen doesn't have the
            %region keep for bookkepping but make all data NaN.
            output.ROI(output_lines)=data_subtable.ROI(1);
            output.contrast(output_lines)=data_name(d_idx);

            output.study_model(output_lines)={strjoin(strrep(name_table.group_type(1:end),'*',':'),'+')};
            output.statistical_test(output_lines)={'N-Way ANOVA'};
            output.source_of_variation(output_lines)={name_table.group_type{1:end},'Error','Total'};
            output.sum_of_squares(output_lines)=NaN;
            output.df(output_lines)=NaN;
            output.F_Statistic(output_lines)=NaN;

            output.pval(output_lines)=NaN;
            output.eta2(output_lines)=NaN;
            output.cohenF(output_lines)=NaN;
        end


        %% Checking For PostHoc
        %Pull only the data we are currently working in not the whole sheet!
        check_raw_sig=output.pval(length_output+(1:num_lines_to_add-1))<stats_test.pval_threshold;

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
                    [comparison,~,~,gnames] = multcompare(stats,'Dimension',sig_name_table_subset.idx{m},'ctype','tukey-kramer','Display','off');
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
                    [multi_compare_single_contrast(insertion_idx).source_of_variation]=deal(strrep(sig_name_table_subset.group_type(m),'*',':'));
                    [multi_compare_single_contrast(insertion_idx).Initial_Study_Model]=deal(strjoin(strrep(tbl(2:end-2,1),'*',':'),'+'));
                    [multi_compare_single_contrast(insertion_idx).Initial_Statistical_Test]=deal('N-Way ANOVA');

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
                        Multi_Compare.source_of_variation(length_multicompare+(1:size(comparison,1)))=strrep(sig_name_table_subset.group_type(m),'*',':');
                        Multi_Compare.Initial_Study_Model(length_multicompare+(1:size(comparison,1)))={strjoin(strrep(tbl(2:end-2,1),'*',':'),'+')};
                        Multi_Compare.Initial_Statistical_Test(length_multicompare+(1:size(comparison,1)))={'N-Way ANOVA'};

                        Multi_Compare.Group_A(length_multicompare+(1:size(comparison,1)))=cleaned_gnames(comparison(:,1));
                        Multi_Compare.Group_B(length_multicompare+(1:size(comparison,1)))=cleaned_gnames(comparison(:,2));
                        Multi_Compare.Pval(length_multicompare+(1:size(comparison,1)))=comparison(:,end);
                    end

                    length_multicompare=length_multicompare+nchoosek(number_of_group_separators(m),2);

                end
            end
        end
    else
        %In the case the contrast data doesn't exist in the subset, then we
        %fill in this.

        output.ROI(output_lines)=data_subtable.ROI(1);
        output.contrast(output_lines)=data_name(d_idx);
        output.study_model(output_lines)={'unavailable. no data'};
        output.statistical_test(output_lines)={'N-Way ANOVA'};

        for i=1:height(name_table)
            output.source_of_variation{output_lines(i)}=name_table.group_type{i};
        end
        output.source_of_variation{output_lines(i+1)}='Error';
        output.source_of_variation{output_lines(i+2)}='Total';

        keep_cols=column_find(output,'ROI|contrast|study_model|statistical_test|source_of_variation',1);
        output(output_lines,~keep_cols)=array2table(nan(numel(output_lines),nnz(~keep_cols)));
    end

    %Now I need to put any multi comparison of the data in a way that I can
    % use again.
    multi_compare_struct_arrays{d_idx}=multi_compare_single_contrast;
    clear sig_name_table_subset multi_compare_single_contrast
end

try
    Multi_Compare=struct2table( horzcat(multi_compare_struct_arrays{:}) );
catch
    keyboard;
end

%% Get bookkeeping information
if check_rob_sheet==1
    Bookkeeping_group_summary_list={'ROI','Structure','hemisphere_assignment','GN_Symbol','ARA_abbrev','id64_fSABI','id32_fSABI','Structure_id','GroupCount'};
elseif check_rob_sheet==0
    Bookkeeping_group_summary_list={'ROI','Structure','hemisphere_assignment','acronym','name','id64','id32','Structure_id','GroupCount'};

end
data_grouping_regex=strcat('^(',strjoin(Bookkeeping_group_summary_list,'|'),')$');
Information_idx=regexpi(data_subtable_columns,data_grouping_regex);
Information_positional_idx=~cellfun(@isempty,Information_idx);
InformationSet=unique(data_subtable(:,Information_positional_idx),'rows');

%% Add the Number of Groupings Per Source of variation Back in
Number_of_Groupings=table;
Number_of_Groupings.source_of_variation=name_table.group_type;
Number_of_Groupings.Number_of_Groupings=cellfun(@numel,name_table.N);
Number_of_Groupings.Number_of_Groupings(~harmonic_puller)=0;
offset=height(Number_of_Groupings);
Number_of_Groupings.source_of_variation(offset+1)={'Error'};
Number_of_Groupings.Number_of_Groupings(offset+1)=NaN;
Number_of_Groupings.source_of_variation(offset+2)={'Total'};
Number_of_Groupings.Number_of_Groupings(offset+2)=NaN;

exists = ismember('Number_of_Groupings', output.Properties.VariableNames);
if ~exists
    output=join(output,Number_of_Groupings,'Key','source_of_variation');
else
    keyboard;
end

%% ADD Booking Information to full output
output_fullspecification=outerjoin(InformationSet,output,'MergeKeys',true);
end
