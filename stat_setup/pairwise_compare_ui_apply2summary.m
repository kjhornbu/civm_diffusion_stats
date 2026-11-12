function [configuration_struct] = pairwise_compare_ui_apply2summary(configuration_struct,input_doc)

%% Preliminaries
if istable(input_doc)
    dataFrame=input_doc;
else
    dataFrame=civm_read_table(input_doc);
end

model_array=table2array(configuration_struct.model_table);

%% PULLING INTERESTING COLUMNS OUT OF THE FULL MODEL
GROUP_logical_idx=~cellfun(@isempty,configuration_struct.test_criteria.GROUP);
GROUP_positional_idx=find(GROUP_logical_idx);
[valGROUP,~,idxGROUP]=unique(configuration_struct.test_criteria.GROUP(GROUP_positional_idx));

SUBGROUP_logical_idx=~cellfun(@isempty,configuration_struct.test_criteria.SUBGROUP);
SUBGROUP_positional_idx=find(SUBGROUP_logical_idx);
[valSUBGROUP,~,idxSUBGROUP]=unique(configuration_struct.test_criteria.SUBGROUP(SUBGROUP_positional_idx));

only_interesting_col_names=vertcat(configuration_struct.test_criteria.Column_Names(GROUP_positional_idx(idxGROUP)),configuration_struct.test_criteria.Column_Names(SUBGROUP_positional_idx(idxSUBGROUP)));

%Check and remove things in the zscoring or stratification entries --- Does
%not work together because none is not and effective name with the string
%join  -- REMEMBER ONLY 1 column can stratify

if any(~strcmp(configuration_struct.zscore,'none'))
    idx_zscore=reg_match(only_interesting_col_names, strcat('^(',strjoin(configuration_struct.zscore,'|'),')$')); % we allow multiple zscore columns now
else
    idx_zscore=logical(zeros(height(only_interesting_col_names),1));
end

if any(~strcmp(configuration_struct.stratification,'none'))
    idx_strat=reg_match(only_interesting_col_names,configuration_struct.stratification);
else
    idx_strat=logical(zeros(height(only_interesting_col_names),1));
end

% don't put in pairwise compare if you don't actually include this
% factor in the model.
not_using_cofactor_idx=sum(model_array)'==0;

idx = idx_zscore | idx_strat | not_using_cofactor_idx;
only_interesting_col_names(idx)=[];

for n=1:size(model_array,1)
    studymodel{n}=strjoin(configuration_struct.model_table.Properties.VariableNames(model_array(n,:)),':');
end

%% Begin with any Reasonable Group Pairwise Comparison
Categorical_Entries=struct;
[algorithm_Output] = AnyColumn_Final_Viability(dataFrame);

%only_interesting_col_names=algorithm_Output.Properties.VariableNames;
for n=1:numel(only_interesting_col_names)
    logical_idx_lut=~cellfun(@isempty,algorithm_Output.(only_interesting_col_names{n}));
    Column_Entries{n} = cellstr({'None',algorithm_Output.(only_interesting_col_names{n}){logical_idx_lut}});
    Categorical_Entries.(only_interesting_col_names{n})=categorical({'None'},Column_Entries{n}','Ordinal',true,'Protected', true);
end

%% START THE GUI INTERFACE
fig=uifigure('Position',[100 100 2150 1100]);
main_grid = uigridlayout(fig,[2,1]); % Have two grids one with all the info in it and another which holds the next button
main_grid.ColumnWidth = {'1x'};
main_grid.RowHeight = {'1x',65};

% check box items for table
applyto_ppt=table('Size',[1 1],'VariableTypes',repmat({'logical'},[1,1]),'VariableNames',{'Put in PPT'});
make_image=table('Size',[1 1],'VariableTypes',repmat({'logical'},[1,1]),'VariableNames',{'Make Image'});
case_name=table('Size',[1 1],'VariableTypes',repmat({'string'},[1,1]),'VariableNames',{'Case_Name'});
sov=struct;
sov.Source_of_Variation=categorical({'None'},{'None',studymodel{:}},'Ordinal',true,'Protected', true);

uip_1 = uipanel(main_grid, ...
    "Title",'"Any Reasonable Group" Pairwise Comparison', ...
    "BackgroundColor","white");

overall_hold = uigridlayout(uip_1,[3,1]);
overall_hold.RowHeight = {65,'1x',65};
overall_hold.ColumnWidth = {'1x'};

% Prior Pairwise Loader --- Will not work if different comparision terms
load_prior = uigridlayout(overall_hold,[1,3]);
load_prior.RowHeight = {45};
load_prior.ColumnWidth = {'0.5x','1x','0.25x'};
uilabel(load_prior,'Text','Load Prior Pairwise Comparisons by Entering Path and Pressing "LOAD":');
prior_pairwise = uieditfield(load_prior,'text','Value','');
load_data_button = uibutton(load_prior,'Text','LOAD');
load_data_button.ButtonPushedFcn=@(src,event)load_prior_state(src,event,prior_pairwise.Value);

% start of Main entry frame
main_input = uigridlayout(overall_hold,[6,1]);
main_input.RowHeight = {'1x'};
main_input.ColumnWidth = {'0.25x','0.25x','0.25x','0.5x','1x','1x'};

% 1st from left - Make Image Check Box
data_grid= uigridlayout(main_input,[2,1]);
data_grid.ColumnWidth = {'1x'};
data_grid.RowHeight = {65,'1x'};
uilabel(data_grid,'Text','');

uit_make_image=uitable(data_grid,'ColumnEditable',true);
uit_make_image.Data=make_image;
uit_make_image.Data.Properties.RowNames=strsplit(num2str(1))';
uit_make_image.DisplayDataChangedFcn=@(src,event)update_text(src,event,'img_checkbox');

% 2nd from left - Add to PPT Check Box
data_grid= uigridlayout(main_input,[2,1]);
data_grid.ColumnWidth = {'1x'};
data_grid.RowHeight = {65,'1x'};
uilabel(data_grid,'Text','');

uit_applyto_ppt=uitable(data_grid,'ColumnEditable',true);
uit_applyto_ppt.Data=applyto_ppt;
uit_applyto_ppt.Data.Properties.RowNames=strsplit(num2str(1))';
uit_applyto_ppt.DisplayDataChangedFcn=@(src,event)update_text(src,event,'ppt_checkbox');

% 3rd from left - Case Name Text Input
data_grid= uigridlayout(main_input,[2,1]);
data_grid.ColumnWidth = {'1x'};
data_grid.RowHeight = {65,'1x'};
uilabel(data_grid,'Text','');

uit_case=uitable(data_grid,'ColumnEditable',true);
uit_case.Data=case_name;
uit_case.Data.Properties.RowNames=strsplit(num2str(1))';
uit_case.DisplayDataChangedFcn=@(src,event)update_text(src,event,'case');

% 4rd from left - SoV Drop Down
data_grid= uigridlayout(main_input,[2,1]);
data_grid.ColumnWidth = {'1x'};
data_grid.RowHeight = {65,'1x'};
uilabel(data_grid,'Text','');

uit_sov=uitable(data_grid,'ColumnEditable',true);
uit_sov.Data=struct2table(sov);
uit_sov.Data.Properties.RowNames=strsplit(num2str(1))';
uit_sov.DisplayDataChangedFcn=@(src,event)update_text(src,event,'sov');

% 5th From Left - Control Terms as Dropdown 
data_grid= uigridlayout(main_input,[2,1]);
data_grid.ColumnWidth = {'1x'};
data_grid.RowHeight = {65,'1x'};
uilabel(data_grid,'Text','Basis');

uit_controlpw=uitable(data_grid,'ColumnEditable',true);
uit_controlpw.Data=struct2table(Categorical_Entries);
uit_controlpw.Data.Properties.RowNames=strsplit(num2str(1))';
uit_controlpw.DisplayDataChangedFcn=@(src,event)update_text(src,event,'controlpw');

% 6th From Left - Treated Terms as Dropdown 
data_grid = uigridlayout(main_input,[2,1]);
data_grid.ColumnWidth = {'1x'};
data_grid.RowHeight = {65,'1x'};
uilabel(data_grid,'Text','Condition Under Test');

uit_treatedpw=uitable(data_grid,'ColumnEditable',true);
uit_treatedpw.Data=struct2table(Categorical_Entries);
uit_treatedpw.Data.Properties.RowNames=strsplit(num2str(1))';
uit_treatedpw.DisplayDataChangedFcn=@(src,event)update_text(src,event,'treatmentpw');

controlpw = uit_controlpw.Data;
treatmentpw = uit_treatedpw.Data;

% Holding for add/subtract rows buttons
holding_add_sub_button = uigridlayout(overall_hold,[1,2]);
holding_add_sub_button.RowHeight = {45};
holding_add_sub_button.ColumnWidth = {'1x','1x'};

add_row_button = uibutton(holding_add_sub_button,'Text','+');
add_row_button.ButtonPushedFcn=@add_row_button_pushed;

remove_row_button = uibutton(holding_add_sub_button,'Text','-');
remove_row_button.ButtonPushedFcn=@remove_row_button_pushed;

% big next button at bottom
next_button = uibutton(main_grid,'Text','NEXT');
next_button.ButtonPushedFcn=@next_button_pressed;
waitfor(next_button,'ButtonPushedFcn');

%% ALL INTERNAL FUNCTIONS
    function load_prior_state(src,event,entry)

        temp_entry=strsplit(entry,{'"'});
        temp_entry_idx=~cellfun(@isempty,temp_entry);
        entry=temp_entry(temp_entry_idx);
        entry=entry{:};

        if ~isempty(entry)
            data=load(entry);
            pairwise=data.pairwise_criteria;

            col_names_con=pairwise.control.Properties.VariableNames;
            col_names_treat=pairwise.treatment.Properties.VariableNames;

            current_col_names=uit_controlpw.Data.Properties.VariableNames;

            if isequal(col_names_con,col_names_treat)

                controlpw=pairwise.control;
                treatmentpw=pairwise.treatment;

                col_idx=1:find(reg_match(col_names_con,'applytoppt'))-1;

                if isequal(current_col_names,col_names_con(col_idx))
                    uit_controlpw.Data=pairwise.control(:,col_idx);
                    uit_treatedpw.Data=pairwise.treatment(:,col_idx);
                else
                    error('The Factors in your current analysis do not match your loaded in Pairwise Analysis! Try Again!')
                end

                if isequal(pairwise.control.makeimage,pairwise.treatment.makeimage)
                    uit_make_image.Data.('Make Image')(1:height(pairwise.control.applytoppt))=pairwise.control.makeimage;
                    uit_make_image.Data.Properties.RowNames=strsplit(num2str(1:height(pairwise.control.makeimage)))';
                else
                    uit_make_image.Data.('Make Image')(1:height(pairwise.control))=repmat({false},[1,height(pairwise.control)]);
                    uit_make_image.Data.Properties.RowNames=strsplit(num2str(1:height(pairwise.control)))';
                end

                if isequal(pairwise.control.applytoppt,pairwise.treatment.applytoppt)
                    uit_applyto_ppt.Data.('Put in PPT')(1:height(pairwise.control.applytoppt))=pairwise.control.applytoppt;
                    uit_applyto_ppt.Data.Properties.RowNames=strsplit(num2str(1:height(pairwise.control.applytoppt)))';
                else
                    uit_applyto_ppt.Data.('Put in PPT')(1:height(pairwise.control))=repmat({false},[1,height(pairwise.control)]);
                    uit_applyto_ppt.Data.Properties.RowNames=strsplit(num2str(1:height(pairwise.control)))';
                end

                if isequal(pairwise.control.case,pairwise.treatment.case)
                    uit_case.Data.Case_Name(1:height(pairwise.control.case))=pairwise.control.case;
                    uit_case.Data.Properties.RowNames=strsplit(num2str(1:height(pairwise.control.case)))';
                else
                    uit_case.Data.Case_Name(1:height(pairwise.control))=repmat({string},[1,height(pairwise.control)]);
                    uit_case.Data.Properties.RowNames=strsplit(num2str(1:height(pairwise.control)))';
                end

                if isequal(pairwise.control.source_of_variation,pairwise.treatment.source_of_variation)
                    uit_sov.Data.Source_of_Variation(1:height(pairwise.control.source_of_variation))=pairwise.control.source_of_variation;
                    uit_sov.Data.Properties.RowNames=strsplit(num2str(1:height(pairwise.control.source_of_variation)))';
                else
                    uit_sov.Data.Source_of_Variation(1:height(pairwise.control))=repmat({string},[1,height(pairwise.control)]);
                    uit_sov.Data.Properties.RowNames=strsplit(num2str(1:height(pairwise.control)))';
                end
            else
                error('Control and Treatment Pairwise Comparision Files Must Have Same Column Headings!')
            end
        end
    end

    function update_text(src,event,entry)
        if ~isempty(regexpi(entry,'^(control)'))
            [controlpw]=update_text_control(src,event,entry);
        end
        if ~isempty(regexpi(entry,'^(treatment)'))
            [treatmentpw]=update_text_treatment(src,event,entry);
        end
        if ~isempty(regexpi(entry,'^(sov|case|img_checkbox|ppt_checkbox)$'))
            [controlpw, treatmentpw]=update_text_sov_case_checkbox(src,event,entry);
        end
    end

    function save_prior_state(src,event)
        controlpw = uit_controlpw.Data;
        treatmentpw = uit_treatedpw.Data;

        controlpw = uit_controlpw.Data;
        controlpw.makeimage=uit_make_image.Data.('Make Image')(1:end);
        controlpw.applytoppt=uit_applyto_ppt.Data.('Put in PPT')(1:end);
        controlpw.case = uit_case.Data.Case_Name(1:end);
        controlpw.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);

        treatmentpw = uit_treatedpw.Data;
        treatmentpw.makeimage=uit_make_image.Data.('Make Image')(1:end);
        treatmentpw.applytoppt=uit_applyto_ppt.Data.('Put in PPT')(1:end);
        treatmentpw.case = uit_case.Data.Case_Name(1:end);
        treatmentpw.source_of_variation = uit_sov.Data.Source_of_Variation(1:end);
    end

    function remove_row_button_pushed (src,event)
        size_data_set=size(uit_controlpw.Data);

        % save prior state
        save_prior_state(src,event)

        if size_data_set(1)==1
            return;
            % if there is only one row you do not delete more rows.
        end

        controlpw(size_data_set(1),:)=[];
        treatmentpw(size_data_set(1),:)=[];

        uit_controlpw.Data=controlpw(:,1:size_data_set(2));
        uit_treatedpw.Data=treatmentpw(:,1:size_data_set(2));

        uit_make_image.Data(size_data_set(1),:)=[];
        uit_make_image.Data.('Make Image')=controlpw.makeimage;
        uit_applyto_ppt.Data(size_data_set(1),:)=[];
        uit_applyto_ppt.Data.('Put in PPT')=controlpw.applytoppt;

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
        uit_make_image.Data=[uit_make_image.Data;repmat({false},[1,size_case_data(2)])];
        uit_applyto_ppt.Data = [uit_applyto_ppt.Data;repmat({false},[1,size_case_data(2)])];
        uit_case.Data=[uit_case.Data;repmat({string},[1,size_case_data(2)])];
        uit_sov.Data=[uit_sov.Data;repmat({string},[1,size_case_data(2)])];
        uit_controlpw.Data=[uit_controlpw.Data;struct2cell(Categorical_Entries)'];
        uit_treatedpw.Data=[uit_treatedpw.Data;struct2cell(Categorical_Entries)'];

        uit_make_image.Data.Properties.RowNames=strsplit(num2str(1:size_case_data(1)+1))';
        uit_applyto_ppt.Data.Properties.RowNames=strsplit(num2str(1:size_case_data(1)+1))';
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

        configuration_struct.pairwise_criteria=pairwise_criteria; 

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
        elseif ~isempty(regexpi(entry,'^(ppt_checkbox)$'))
            control.applytoppt = uit_applyto_ppt.Data.('Put in PPT')(1:end);
            treatment.applytoppt = uit_applyto_ppt.Data.('Put in PPT')(1:end);
        elseif ~isempty(regexpi(entry,'^(img_checkbox)$'))
            control.makeimage = uit_make_image.Data.('Make Image')(1:end);
            treatment.makeimage = uit_make_image.Data.('Make Image')(1:end);
        end
    end
end

