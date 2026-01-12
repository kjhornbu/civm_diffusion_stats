function [pairwise_criteria] = pairwise_compare_ui_apply2summary(configuration_struct,input_doc)

if istable(input_doc)
    dataFrame=input_doc;
else
    dataFrame=civm_read_table(input_doc);
end

model_array=table2array(configuration_struct.model_table);
for n=1:size(model_array,1)
    studymodel{n}=strjoin(configuration_struct.model_table.Properties.VariableNames(model_array(n,:)),':');
end

%% Pulling Interesting columns (we need those because the other columns are not useful stuff)
GROUP_logical_idx=~cellfun(@isempty,configuration_struct.test_criteria.GROUP);
GROUP_positional_idx=find(GROUP_logical_idx);
[valGROUP,~,idxGROUP]=unique(configuration_struct.test_criteria.GROUP(GROUP_positional_idx));

SUBGROUP_logical_idx=~cellfun(@isempty,configuration_struct.test_criteria.SUBGROUP);
SUBGROUP_positional_idx=find(SUBGROUP_logical_idx);
[valSUBGROUP,~,idxSUBGROUP]=unique(configuration_struct.test_criteria.SUBGROUP(SUBGROUP_positional_idx));

only_interesting_col_names=vertcat(configuration_struct.test_criteria.Column_Names(GROUP_positional_idx(idxGROUP)),configuration_struct.test_criteria.Column_Names(SUBGROUP_positional_idx(idxSUBGROUP)));

%Check and remove things in the zscoring or stratification entries --- Does
%not work together because none is not and effective name with the string
%join  -- REMEMBER ONLY 1 column can stratify or zscore on
    
if any(~strcmp(configuration_struct.zscore,'none') | ~strcmp(configuration_struct.stratification,'none'))
    idx_zscore=reg_match(only_interesting_col_names, configuration_struct.zscore);
    idx_strat=reg_match(only_interesting_col_names,configuration_struct.stratification);
    idx = idx_zscore | idx_strat;
    only_interesting_col_names(idx)=[];
end

%% Start the ui for figure generation
fig=uifigure('Position',[100 100 2150 1100]);
main_grid = uigridlayout(fig,[2,1]); % Have two grids one with all the info in it and another which holds the next button
main_grid.ColumnWidth = {'1x'};
main_grid.RowHeight = {'1x',65};

%% Begin with any Reasonable Group Pairwise Comparison (those from the james algorithm)
Categorical_Entries=struct;
[~,algorithm_Output] = james_to_study_inDataFrameEntry(dataFrame);
%only_interesting_col_names=algorithm_Output.Properties.VariableNames;
for n=1:numel(only_interesting_col_names)
    logical_idx_lut=~cellfun(@isempty,algorithm_Output.(only_interesting_col_names{n}));
    Column_Entries{n} = cellstr({'None',algorithm_Output.(only_interesting_col_names{n}){logical_idx_lut}});
    Categorical_Entries.(only_interesting_col_names{n})=categorical({'None'},Column_Entries{n}','Ordinal',true,'Protected', true);
end

uip_1 = uipanel(main_grid, ...
    "Title",'"Any Reasonable Group" Pairwise Comparison', ...
    "BackgroundColor","white");

applytosummary_ppt=table('Size',[1 1],'VariableTypes',repmat({'logical'},[1,1]),'VariableNames',{'Apply to "Simplify Summary PPT"'});

case_name=table('Size',[1 1],'VariableTypes',repmat({'string'},[1,1]),'VariableNames',{'Case_Name'});

sov_categorical=struct;
sov_categorical.Source_of_Variation=categorical({'None'},{'None',studymodel{:}},'Ordinal',true,'Protected', true);

holding_add_button = uigridlayout(uip_1,[2,1]);
holding_add_button.RowHeight = {'1x',65};
holding_add_button.ColumnWidth = {'1x'};

teriary_grid = uigridlayout(holding_add_button,[5,1]);
teriary_grid.RowHeight = {'1x'};
teriary_grid.ColumnWidth = {'0.5x','0.25x','0.25x','1x','1x'};

Left_1_teriary_grid= uigridlayout(teriary_grid,[2,1]);
Left_1_teriary_grid.ColumnWidth = {'1x'};
Left_1_teriary_grid.RowHeight = {65,'1x'};
uil=uilabel(Left_1_teriary_grid,'Text','');
uit_applytosummaryppt=uitable(Left_1_teriary_grid,'ColumnEditable',true);
uit_applytosummaryppt.Data=applytosummary_ppt;
uit_applytosummaryppt.Data.Properties.RowNames=strsplit(num2str(1))';
uit_applytosummaryppt.DisplayDataChangedFcn=@(src,event)update_text(src,event,'checkbox');

Left_2_teriary_grid= uigridlayout(teriary_grid,[2,1]);
Left_2_teriary_grid.ColumnWidth = {'1x'};
Left_2_teriary_grid.RowHeight = {65,'1x'};
uil=uilabel(Left_2_teriary_grid,'Text','');
uit_case=uitable(Left_2_teriary_grid,'ColumnEditable',true);
uit_case.Data=case_name;
uit_case.Data.Properties.RowNames=strsplit(num2str(1))';
uit_case.DisplayDataChangedFcn=@(src,event)update_text(src,event,'case');

Left3_teriary_grid= uigridlayout(teriary_grid,[2,1]);
Left3_teriary_grid.ColumnWidth = {'1x'};
Left3_teriary_grid.RowHeight = {65,'1x'};
uil=uilabel(Left3_teriary_grid,'Text','');
uit_sov=uitable(Left3_teriary_grid,'ColumnEditable',true);
uit_sov.Data=struct2table(sov_categorical);
uit_sov.Data.Properties.RowNames=strsplit(num2str(1))';
uit_sov.DisplayDataChangedFcn=@(src,event)update_text(src,event,'sov');

mid_teriary_grid= uigridlayout(teriary_grid,[2,1]);
mid_teriary_grid.ColumnWidth = {'1x'};
mid_teriary_grid.RowHeight = {65,'1x'};
uil=uilabel(mid_teriary_grid,'Text','Basis');
uit_controlpw=uitable(mid_teriary_grid,'ColumnEditable',true);
uit_controlpw.Data=struct2table(Categorical_Entries);
uit_controlpw.Data.Properties.RowNames=strsplit(num2str(1))';
uit_controlpw.DisplayDataChangedFcn=@(src,event)update_text(src,event,'controlpw');

R_teriary_grid = uigridlayout(teriary_grid,[2,1]);
R_teriary_grid.ColumnWidth = {'1x'};
R_teriary_grid.RowHeight = {65,'1x'};
uil=uilabel(R_teriary_grid,'Text','Condition Under Test');
uit_treatedpw=uitable(R_teriary_grid,'ColumnEditable',true);
uit_treatedpw.Data=struct2table(Categorical_Entries);
uit_treatedpw.Data.Properties.RowNames=strsplit(num2str(1))';
uit_treatedpw.DisplayDataChangedFcn=@(src,event)update_text(src,event,'treatmentpw');

controlpw = uit_controlpw.Data;
treatmentpw = uit_treatedpw.Data;

holding_add_sub_button = uigridlayout(holding_add_button,[1,2]);
holding_add_sub_button.RowHeight = {45};
holding_add_sub_button.ColumnWidth = {'1x','1x'};

add_row_button = uibutton(holding_add_sub_button,'Text','+');
add_row_button.ButtonPushedFcn=@add_row_button_pushed;

remove_row_button = uibutton(holding_add_sub_button,'Text','-');
remove_row_button.ButtonPushedFcn=@remove_row_button_pushed;

next_button = uibutton(main_grid,'Text','NEXT');
next_button.ButtonPushedFcn=@next_button_pressed;
waitfor(next_button,'ButtonPushedFcn');

%internal actions
    function update_text(src,event,entry)
        if ~isempty(regexpi(entry,'^(control)'))
            [controlpw]=update_text_control(src,event,entry);
        end
        if ~isempty(regexpi(entry,'^(treatment)'))
            [treatmentpw]=update_text_treatment(src,event,entry);
        end
        if ~isempty(regexpi(entry,'^(sov|case|checkbox)$'))
            [controlpw, treatmentpw]=update_text_sov_case_checkbox(src,event,entry);
        end
    end
    function save_prior_state(src,event)
        controlpw = uit_controlpw.Data;
        treatmentpw = uit_treatedpw.Data;

        controlpw = uit_controlpw.Data;
        controlpw.applytosummary=uit_applytosummaryppt.Data.('Apply to "Simplify Summary PPT"')(1:end);
        controlpw.case = uit_case.Data.Case_Name(1:end);
        controlpw.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);

        treatmentpw = uit_treatedpw.Data;
        treatmentpw.applytosummary=uit_applytosummaryppt.Data.('Apply to "Simplify Summary PPT"')(1:end);
        treatmentpw.case = uit_case.Data.Case_Name(1:end);
        treatmentpw.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);
    end
    function remove_row_button_pushed (src,event)
        size_data_set=size(uit_controlpw.Data);

        % save prior state
        save_prior_state(src,event)

        if size_data_set(1)==1
            return;
        end

        controlpw(size_data_set(1),:)=[];
        treatmentpw(size_data_set(1),:)=[];

        uit_controlpw.Data=controlpw(:,1:size_data_set(2));
        uit_treatedpw.Data=treatmentpw(:,1:size_data_set(2));
    
        uit_applytosummaryppt.Data(size_data_set(1),:)=[];
        uit_applytosummaryppt.Data.('Apply to "Simplify Summary PPT"')=controlpw.applytosummary;
        uit_case.Data(size_data_set(1),:)=[];
        uit_case.Data.Case_Name=controlpw.case;
        uit_sov.Data(size_data_set(1),:)=[];
        uit_sov.Data.Source_of_Variation=controlpw.source_of_variation;
    end
    function add_row_button_pushed(src,event)
        %Make sure when we are adding rows that stuff got putt into the
        %model_table correctly.
        size_data_set=size(uit_treatedpw.Data);
        size_case_data=size(uit_case.Data);

        %Save prior state
        save_prior_state(src,event)

        % increment the GUI tables for additional entry

        uit_applytosummaryppt.Data = [uit_applytosummaryppt.Data;repmat({false},[1,size_case_data(2)])];
        uit_case.Data=[uit_case.Data;repmat({string},[1,size_case_data(2)])];
        uit_sov.Data=[uit_sov.Data;repmat({string},[1,size_case_data(2)])];
        uit_controlpw.Data=[uit_controlpw.Data;struct2cell(Categorical_Entries)'];
        uit_treatedpw.Data=[uit_treatedpw.Data;struct2cell(Categorical_Entries)'];

        uit_applytosummaryppt.Data.Properties.RowNames=strsplit(num2str(1:size_case_data(1)+1))';
        uit_case.Data.Properties.RowNames=strsplit(num2str(1:size_case_data(1)+1))';
        uit_sov.Data.Properties.RowNames=strsplit(num2str(1:size_case_data(1)+1))';
        uit_controlpw.Data.Properties.RowNames=strsplit(num2str(1:size_data_set(1)+1))';
        uit_treatedpw.Data.Properties.RowNames=strsplit(num2str(1:size_data_set(1)+1))';
    end
    function next_button_pressed(src, event)
        %Save all state
        save_prior_state(src,event)

        pairwise_criteria.control=controlpw;
        pairwise_criteria.treatment=treatmentpw;

        close(fig);
        return
    end
    function [control] = update_text_control(src,event,entry)
        control = uit_controlpw.Data;
        control.case = uit_case.Data.Case_Name(1:end);
        control.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);
    end

    function [treatment] = update_text_treatment(src,event,entry)
        treatment= uit_treatedpw.Data;
        treatment.case = uit_case.Data.Case_Name(1:end);
        treatment.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);
    end
    function [control, treatment]=update_text_sov_case_checkbox(src,event,entry)
        if ~isempty(regexpi(entry,'^(sov)$'))
            control.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);
            treatment.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);
        elseif ~isempty(regexpi(entry,'^(case)$'))
            control.case = uit_case.Data.Case_Name(1:end);
            treatment.case = uit_case.Data.Case_Name(1:end);
        elseif ~isempty(regexpi(entry,'^(checkbox)$'))
            control.applytosummary = uit_applytosummaryppt.Data.('Apply to "Simplify Summary PPT"')(1:end);
            treatment.applytosummary = uit_applytosummaryppt.Data.('Apply to "Simplify Summary PPT"')(1:end);
        end
    end
end

