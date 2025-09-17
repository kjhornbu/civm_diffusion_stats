function [summary_criteria,pairwise_criteria] = pairwise_compare_ui(configuration_struct,input_doc)

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

%% Start the ui for figure generation
fig=uifigure('Position',[100 100 2150 1100]);
main_grid = uigridlayout(fig,[2,1]); % Have two grids one with all the info in it and another which holds the next button
main_grid.ColumnWidth = {'1x'};
main_grid.RowHeight = {'1x',65};

secondary_grid = uigridlayout(main_grid,[2,1]);
secondary_grid.ColumnWidth = {'1x'};
secondary_grid.RowHeight = {'1x','1x'};

%% Begin with any Reasonable Group Pairwise Comparison (those from the james algorithm)
Categorical_Entries=struct;
[~,algorithm_Output] = james_to_study_inDataFrameEntry(dataFrame);
%only_interesting_col_names=algorithm_Output.Properties.VariableNames;
for n=1:numel(only_interesting_col_names)
    logical_idx_lut=~cellfun(@isempty,algorithm_Output.(only_interesting_col_names{n}));
    Column_Entries{n} = cellstr({'None',algorithm_Output.(only_interesting_col_names{n}){logical_idx_lut}});
    Categorical_Entries.(only_interesting_col_names{n})=categorical({'None'},Column_Entries{n}','Ordinal',true,'Protected', true);
end

uip_1 = uipanel(secondary_grid, ...
    "Title",'"Any Reasonable Group" Pairwise Comparison', ...
    "BackgroundColor","white");

%applytosummary_ppt=table('Size',[1 1],'VariableTypes',repmat({'logical'},[1,1]),'VariableNames',{'Apply to "Simplifying Within Summary PPT"'});

holding_add_button = uigridlayout(uip_1,[2,1]);
holding_add_button.RowHeight = {'1x',65};
holding_add_button.ColumnWidth = {'1x'};

teriary_grid = uigridlayout(holding_add_button,[1,2]);
teriary_grid.RowHeight = {'1x'};
teriary_grid.ColumnWidth = {'1x','1x'};

% teriary_grid = uigridlayout(holding_add_button,[1,2]);
% teriary_grid.RowHeight = {'1x'};
% teriary_grid.ColumnWidth = {'0.5x','1x','1x'};
% 
% uit_applytosummaryppt=uitable(teriary_grid,'ColumnEditable',true);
% uit_applytosummaryppt.Data=applytosummary_ppt;
% uit_applytosummaryppt.Data.Properties.RowNames=strsplit(num2str(1))';
% uit_applytosummaryppt.DisplayDataChangedFcn=@(src,event)update_text(src,event,'applydata');

L_teriary_grid= uigridlayout(teriary_grid,[2,1]);
L_teriary_grid.ColumnWidth = {'1x'};
L_teriary_grid.RowHeight = {65,'1x'};
uil=uilabel(L_teriary_grid,'Text','Basis');
uit_controlpw=uitable(L_teriary_grid,'ColumnEditable',true);
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

add_row_button = uibutton(holding_add_button,'Text','+');
add_row_button.ButtonPushedFcn=@add_row_button_pushedA;

%% Only things in model ... for Simplifying the Summary Powerpoint
uip_2 = uipanel(secondary_grid, ...
    "Title","For Simplifying Within Summary Powerpoint", ...
    "BackgroundColor","white");

GROUP_logical_idx=~cellfun(@isempty,configuration_struct.test_criteria.GROUP);
GROUP_positional_idx=find(GROUP_logical_idx);
[valGROUP,~,idxGROUP]=unique(configuration_struct.test_criteria.GROUP(GROUP_positional_idx));

SUBGROUP_logical_idx=~cellfun(@isempty,configuration_struct.test_criteria.SUBGROUP);
SUBGROUP_positional_idx=find(SUBGROUP_logical_idx);
[valSUBGROUP,~,idxSUBGROUP]=unique(configuration_struct.test_criteria.SUBGROUP(SUBGROUP_positional_idx));

only_interesting_col_names=vertcat(configuration_struct.test_criteria.Column_Names(GROUP_positional_idx(idxGROUP)),configuration_struct.test_criteria.Column_Names(SUBGROUP_positional_idx(idxSUBGROUP))); 
Categorical_Entries_sppt=struct;
full_name_list=fieldnames(Categorical_Entries);
Categorical_Entries_sppt=Categorical_Entries;
%In casess where we don't have the column because it wasn't selected by
%group or subgroup then remove it. 
for n=1:numel(full_name_list)
    logical_idx_lut=~cellfun(@isempty,regexpi(only_interesting_col_names,strcat('^(',full_name_list(n),')$')));
    if sum(logical_idx_lut)==0
        Categorical_Entries_sppt = rmfield(Categorical_Entries_sppt,full_name_list(n));
    end
end

case_name=table('Size',[1 1],'VariableTypes',repmat({'string'},[1,1]),'VariableNames',{'Case_Name'});
sov_categorical=struct;
sov_categorical.Source_of_Variation=categorical({'Select'},{'Select',studymodel{:}},'Ordinal',true,'Protected', true);

holding_add_button = uigridlayout(uip_2,[2,1]);
holding_add_button.RowHeight = {'1x',65};
holding_add_button.ColumnWidth = {'1x'};

teriary_grid = uigridlayout(holding_add_button,[4,1]);
teriary_grid.RowHeight = {'1x'};
teriary_grid.ColumnWidth = {'0.25x','0.25x','1x','1x'};

uit_case=uitable(teriary_grid,'ColumnEditable',true);
uit_case.Data=case_name;
uit_case.Data.Properties.RowNames=strsplit(num2str(1))';
uit_case.DisplayDataChangedFcn=@(src,event)update_text(src,event,'case');

uit_sov=uitable(teriary_grid,'ColumnEditable',true);
uit_sov.Data=struct2table(sov_categorical); 
uit_sov.Data.Properties.RowNames=strsplit(num2str(1))';
uit_sov.DisplayDataChangedFcn=@(src,event)update_text(src,event,'sov');

L_teriary_grid= uigridlayout(teriary_grid,[2,1]);
L_teriary_grid.ColumnWidth = {'1x'};
L_teriary_grid.RowHeight = {65,'1x'};
uil=uilabel(L_teriary_grid,'Text','Basis');
uit_control=uitable(L_teriary_grid,'ColumnEditable',true);
uit_control.Data=struct2table(Categorical_Entries_sppt);
uit_control.Data.Properties.RowNames=strsplit(num2str(1))';
uit_control.DisplayDataChangedFcn=@(src,event)update_text(src,event,'controls');

R_teriary_grid = uigridlayout(teriary_grid,[2,1]);
R_teriary_grid.ColumnWidth = {'1x'};
R_teriary_grid.RowHeight = {65,'1x'};
uil=uilabel(R_teriary_grid,'Text','Condition Under Test');
uit_treated=uitable(R_teriary_grid,'ColumnEditable',true);
uit_treated.Data=struct2table(Categorical_Entries_sppt);
uit_treated.Data.Properties.RowNames=strsplit(num2str(1))';
uit_treated.DisplayDataChangedFcn=@(src,event)update_text(src,event,'treatments');

controls = uit_control.Data;
controls.case = uit_case.Data.Case_Name(1:end);
controls.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);

treatments = uit_treated.Data;
treatments.case = uit_case.Data.Case_Name(1:end);
treatments.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);

add_row_button = uibutton(holding_add_button,'Text','+');
add_row_button.ButtonPushedFcn=@add_row_button_pushedB;


next_button = uibutton(main_grid,'Text','NEXT');
next_button.ButtonPushedFcn=@next_button_pressed;
waitfor(next_button,'ButtonPushedFcn');

%internal actions
    function update_text(src,event,entry)
        if ~isempty(regexpi(entry,'^(control)'))
            [control]=update_text_control(src,event,entry);
            if strcmp(entry,'(pw)$')
                controlpw=control;
            elseif strcmp(entry,'(s)$')
                controls=control;
            end
        end
        if ~isempty(regexpi(entry,'^(treatment)'))
            [treatment]=update_text_treatment(src,event,entry);
            if strcmp(entry,'(pw)$')
                treatmentpw=treatment;
            elseif strcmp(entry,'(s)$')
                treatments=treatment;
            end
        end

        if ~isempty(regexpi(entry,'^(sov|case)$'))
            [controls, treatments]=update_text_sov_case(src,event,entry);
        end
    end
        function add_row_button_pushedA(src,event)
        %Make sure when we are adding rows that stuff got putt into the
        %model_table correctly.
        size_data_set=size(uit_treatedpw.Data);

        controlpw = uit_controlpw.Data;
        treatmentpw = uit_treatedpw.Data;

        uit_controlpw.Data=[uit_controlpw.Data;struct2cell(Categorical_Entries)'];
        uit_treatedpw.Data=[uit_treatedpw.Data;struct2cell(Categorical_Entries)'];

        uit_controlpw.Data.Properties.RowNames=strsplit(num2str(1:size_data_set(1)+1))';
        uit_treatedpw.Data.Properties.RowNames=strsplit(num2str(1:size_data_set(1)+1))';
    end


    function add_row_button_pushedB(src,event)
        %Make sure when we are adding rows that stuff got putt into the
        %model_table correctly.
        size_case_data=size(uit_case.Data);
        size_data_set=size(uit_treated.Data);

        controls = uit_control.Data;
        controls.case = uit_case.Data.Case_Name(1:end);
        controls.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);

        treatments = uit_treated.Data;
        treatments.case = uit_case.Data.Case_Name(1:end);
        treatments.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);

        uit_case.Data=[uit_case.Data;repmat({string},[1, size_case_data(2)])];
        uit_sov.Data=[uit_sov.Data;repmat({string},[1, size_case_data(2)])];
        uit_control.Data=[uit_control.Data;struct2cell(Categorical_Entries_sppt)'];
        uit_treated.Data=[uit_treated.Data;struct2cell(Categorical_Entries_sppt)'];

        uit_case.Data.Properties.RowNames=strsplit(num2str(1:size_case_data(1)+1))';
        uit_sov.Data.Properties.RowNames=strsplit(num2str(1:size_case_data(1)+1))';
        uit_control.Data.Properties.RowNames=strsplit(num2str(1:size_data_set(1)+1))';
        uit_treated.Data.Properties.RowNames=strsplit(num2str(1:size_data_set(1)+1))';
    end

    function next_button_pressed(src, event)
        controlpw = uit_controlpw.Data;
        treatmentpw = uit_treatedpw.Data;

        pairwise_criteria.control=controlpw;
        pairwise_criteria.treatment=treatmentpw;

        controls = uit_control.Data;
        controls.case = uit_case.Data.Case_Name(1:end);
        controls.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);

        treatments = uit_treated.Data;
        treatments.case = uit_case.Data.Case_Name(1:end);
        treatments.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);

        summary_criteria.control=controls;
        summary_criteria.treatment=treatments;

        close(fig);
        return
    end
    function [control] = update_text_control(src,event,entry)
        if ~isempty(regexpi(entry,'(pw)$'))
            control = uit_controlpw.Data;
        elseif ~isempty(regexpi(entry,'(s)$'))
            control = uit_control.Data;
            control.case = uit_case.Data.Case_Name(1:end);
            control.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);
        end
    end

    function [treatment] = update_text_treatment(src,event,entry)
        if ~isempty(regexpi(entry,'(pw)$'))
            treatment= uit_treatedpw.Data;
        elseif ~isempty(regexpi(entry,'(s)$'))
            treatment = uit_treated.Data;
            treatment.case = uit_case.Data.Case_Name(1:end);
            treatment.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);
        end
    end
    function [controls, treatments]=update_text_sov_case(src,event,entry)
        if ~isempty(regexpi(entry,'^(sov)$'))
            controls.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);
            treatments.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);
        elseif ~isempty(regexpi(entry,'^(case)$'))
            controls.case = uit_case.Data.Case_Name(1:end);
            treatments.case = uit_case.Data.Case_Name(1:end);
        end
    end
end

