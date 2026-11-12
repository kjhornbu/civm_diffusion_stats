function [configuration] = assignmodelmatrix_ui(configuration_table)
%% Preliminaries

% Setup configuration
configuration.test_criteria=configuration_table;
configuration.scalar_name='anovan_defined_matrix';
configuration.manova_name='omnimanova_defined_matrix';
configuration.zscore='none';
configuration.stratification='none';

%different model types that are possible
scalar_stat_models={'anovan_defined_matrix, anovan_no_interaction, anovan_pairwise_interaction, anovan_full_interaction,\nanova_1way, kruskalwallis. Only in MATLAB 2023+: manova_nway_fullinteraction, manova_nway_no_interaction'};
manova_stat_models={'omnimanova_full_interactions, omnimanova_defined_matrix'};

GROUP_logical_idx=~cellfun(@isempty,configuration_table.GROUP);
GROUP_positional_idx=find(GROUP_logical_idx);
[valGROUP,~,idxGROUP]=unique(configuration_table.GROUP(GROUP_positional_idx));

SUBGROUP_logical_idx=~cellfun(@isempty,configuration_table.SUBGROUP);
SUBGROUP_positional_idx=find(SUBGROUP_logical_idx);
[valSUBGROUP,~,idxSUBGROUP]=unique(configuration_table.SUBGROUP(SUBGROUP_positional_idx));

%set up model clickable table and nesting clickable table
only_interesting_col_names=vertcat(configuration_table.Column_Names(GROUP_positional_idx(idxGROUP)),configuration_table.Column_Names(SUBGROUP_positional_idx(idxSUBGROUP))); 

model_table=table('Size',[1 numel(only_interesting_col_names)],'VariableTypes',repmat({'logical'},[numel(only_interesting_col_names),1]),'VariableNames',only_interesting_col_names);
model_table.Properties.RowNames=strsplit(num2str(1))';
blank_table=model_table;

nest_table=table('Size',[1 1]*numel(only_interesting_col_names),'VariableTypes',repmat({'logical'},[numel(only_interesting_col_names) 1]),'VariableNames',only_interesting_col_names);
nest_table.Properties.RowNames=only_interesting_col_names;
blank_nest_table=nest_table;

%% Start GUI Interface
fig=uifigure('Position',[100 100 2150 550]);
main_grid = uigridlayout(fig,[1,2]);
main_grid.ColumnWidth = {'1x','1x'};
main_grid.RowHeight = {'1x'};

uipanel(main_grid, ...
    "Title",'Statistical Model Setting', ...
    "BackgroundColor","white");

%LEFT Side
data_grid_L = uigridlayout(main_grid,[6,1]);
data_grid_L.ColumnWidth = {'1x'};
data_grid_L.RowHeight = {'1x','1x','1x',65,'1x',65};

model_options_S = uigridlayout(data_grid_L,[2,1]);
model_options_S.ColumnWidth = {'1x'};
model_options_S.RowHeight = {'1x','1x'};

uilabel(model_options_S,'text',sprintf(strcat('Scalar Statistical Model\nOptions:',32,scalar_stat_models{:})));
uitext_S=uieditfield(model_options_S,'text','Value','anovan_defined_matrix');
uitext_S.ValueChangedFcn=@(src,event) text_model(src,event,'scalar');

model_options_C = uigridlayout(data_grid_L,[2,1]);
model_options_C.ColumnWidth = {'1x'};
model_options_C.RowHeight = {'1x','1x'};

uilabel(model_options_C,'text',sprintf(strcat('Connectome Statistical Model\nOptions:',32,manova_stat_models{:})));
uitext_C=uieditfield(model_options_C,'text','Value','omnimanova_defined_matrix');
uitext_C.ValueChangedFcn=@(src,event) text_model(src,event,'manova');

uilabel(data_grid_L,'text',sprintf('Click to populate matrix model representation for both regression models. Multiple entries in a row indicate interactions between clicked terms\nClick "Main Effect Model" or "Full Interaction Model" to populate the matrix automatically.\nClick "Add Nested Terms" to indicate what terms included in the model are children delineations of another term.\nClick "Clear Matrix Model" to clear out the current matrix. Click the  + to add new rows.'));

button_grid = uigridlayout(data_grid_L,[1,4]);
button_grid.ColumnWidth = {'1x','1x','1x','1x'};
button_grid.RowHeight = {'1x'};

main_effect_button = uibutton(button_grid,'Text','Main Effect Model');
main_effect_button.ButtonPushedFcn=@main_effect_pushed;

full_interaction_button = uibutton(button_grid,'Text','Full Interaction Model');
full_interaction_button.ButtonPushedFcn=@full_interaction_pushed;

nested_model_button = uibutton(button_grid,'Text','Add Nested Terms');
nested_model_button.ButtonPushedFcn=@create_nested_terms;

clear_matrix_button = uibutton(button_grid,'Text','Clear Matrix Model');
clear_matrix_button.ButtonPushedFcn=@clear_matrix_button_pushed;

uit=uitable(data_grid_L);
uit.Data=model_table;

temp=size(model_table);
uit.ColumnEditable=repmat(true,[1,temp(2)]);
uit.DisplayDataChangedFcn=@track_changes;

add_row_button = uibutton(data_grid_L,'Text','+');
add_row_button.ButtonPushedFcn=@add_row_button_pushed;

% Right Side
data_grid_R = uigridlayout(main_grid,[3,1]);
data_grid_R.ColumnWidth = {'1x'};
data_grid_R.RowHeight = {'1x','1x',65};

normalization_input = uigridlayout(data_grid_R,[2,1]);
normalization_input.ColumnWidth = {'1x'};
normalization_input.RowHeight = {'1x',65};
uilabel(normalization_input,'text',sprintf(strcat('Column Name for Z-Score Normalization\n\nOptions:',32,strjoin(only_interesting_col_names,', '))));
uitext_normalization=uieditfield(normalization_input,'text','Value','No Z-Scoring');
uitext_normalization.ValueChangedFcn=@(src,event) text_check_col(src,event,'zscore');

stratification_input = uigridlayout(data_grid_R,[2,1]);
stratification_input.ColumnWidth = {'1x'};
stratification_input.RowHeight = {'1x',65};

uilabel(stratification_input,'text', sprintf(strcat('Column Name (ONLY 1) for Stratification\n\nOptions:',32,strjoin(only_interesting_col_names,', '))));
uitext_stratification=uieditfield(stratification_input,'text','Value','No Stratification');
uitext_stratification.ValueChangedFcn=@(src,event) text_check_col(src,event,'stratification');

next_button = uibutton(data_grid_R,'Text','NEXT');
next_button.ButtonPushedFcn=@next_button_pressed;
waitfor(next_button,'ButtonPushedFcn');

%% All Internal Functions
    function main_effect_pushed(src,event)
        clear_matrix_button_pushed(src,event)
        terms=width(model_table);
        check_mark_counter=dec2bin(2.^([0:terms-1]),terms);

        for n=1:terms
            if n>1
                add_row_button_pushed(src, event)
            end
            for m=1:terms
                uit.Data{n,m}=str2num(check_mark_counter(n,m));
            end
        end
        model_table=uit.Data;
    end

    function full_interaction_pushed(src,event)
        clear_matrix_button_pushed(src,event)

        terms=width(model_table);
        check_mark_counter=dec2bin(1:(2^terms-1),terms);

        for n=1:(2^(terms)-1)
            if n>1
                add_row_button_pushed(src, event)
            end
            for m=1:terms
                uit.Data{n,m}=str2num(check_mark_counter(n,m));
            end
        end
        model_table=uit.Data;
    end

    function create_nested_terms(src,event)
        nest_main_grid=uifigure('Position',[100 100 2150 550]);

        nest_grid = uigridlayout(nest_main_grid,[3,1]);
        nest_grid.ColumnWidth = {'1x'};
        nest_grid.RowHeight = {'1x',65,'1x'};

        uilabel(nest_grid,'text',sprintf('Statistical Model - Nested Groupings \n \n Row and column headings are all the allocated groupings in the dataset. Rows nest into Columns.... For example if Group 2 is nested in Group 1, you would select the checkbox on Row-Group 2, Column-Group 1. \n Click "Clear Matrix Model" to clear out the current nesting entries.\n Click "Return to Model" to save and return to the main statistical model setting page.'));

        nest_button_grid=uigridlayout(nest_grid,[1,2]);
        nest_button_grid.ColumnWidth = {'1x','1x'};
        nest_button_grid.RowHeight = {'1x'};

        clear_nest_button = uibutton(nest_button_grid,'Text','Clear Matrix Model');
        clear_nest_button.ButtonPushedFcn=@clear_nest_model;

        return_2_model_button = uibutton(nest_button_grid,'Text','Return to Model');
        return_2_model_button.ButtonPushedFcn=@return_to_model_pressed;

        uit_nest=uitable(nest_grid);
        uit_nest.Data=nest_table;
        temp_nest=size(nest_table);
        uit_nest.ColumnEditable=repmat(true,[1, temp_nest(2)]);
        uit_nest.DisplayDataChangedFcn=@track_nest_changes;

        % internal to nesting functions
        function clear_nest_model(src,event)
            %replace the model table and the saving table with an empty table
            nest_table=blank_nest_table;
            uit_nest.Data=blank_nest_table;
        end
        function return_to_model_pressed(src,event)
            %combine model with config
            nest_table=uit_nest.Data; %final make sure we have all the data
            configuration.nest_model=uit_nest;
            close(nest_main_grid);
            return
        end
        function track_nest_changes(src,event)
            nest_table=uit_nest.Data; %make sure current data is in the saving table
        end
    end

    function clear_matrix_button_pushed(src,event)
        %replace the model table and the saving table with an empty table
        model_table=blank_table;
        uit.Data=blank_table;
    end

    function track_changes(src,event)
        model_table=uit.Data; %make sure current data is in the saving table
    end
    function add_row_button_pushed(src, event)
        %Make sure when we are adding rows that stuff got putt into the
        %model_table correctly.
        size_data=size(uit.Data);
        model_table=uit.Data; %make sure current data is in the saving table
        uit.Data=[uit.Data;repmat({false},[1,size_data(2)])];
        uit.Data.Properties.RowNames=strsplit(num2str(1:size_data(1)+1))';
    end

    function text_model(src,event,entry)
        if strcmp(entry,'scalar')
            %logical_data_idx=strcmp(src.Value,scalar_stat_models);
            logical_data_idx=~cellfun(@isempty,regexpi(scalar_stat_models,src.Value));
        elseif strcmp(entry,'manova')
            %logical_data_idx=strcmp(src.Value,manova_stat_models);
            logical_data_idx=~cellfun(@isempty,regexpi(manova_stat_models,src.Value));
        end
        if sum(logical_data_idx)==0
            src.Value = 'Does Not Match Any Option Above. Try Again.';
        else
            configuration.(strcat(entry,'_name'))=src.Value;
        end
    end

    function text_check_col(src,event,entry)
        if strcmp(entry,'stratification') && numel(list2cell(src.Value))>1
            src.Value = 'We DO NOT support stratifying across multiple sources of variation. Hint: create study column in dataframe.';
        else
            logical_data_idx = reg_match(only_interesting_col_names,strjoin(list2cell(src.Value),'|'));
            logical_none_idx=reg_match('none',strjoin(list2cell(src.Value),'|'));
            if nnz(logical_data_idx)==0 && nnz(logical_none_idx) == 0
                src.Value = 'Does Not Match Any Option Above. Try Again.';
            elseif nnz(logical_data_idx)==0 && nnz(logical_none_idx) > 0
                configuration.(entry)='none';
            else
                % the last case which is that we have a match with 1 or more of
                % the interesting columns in our dataset
                configuration.(entry)=only_interesting_col_names(logical_data_idx);
            end
        end
    end
    function next_button_pressed(src,event)
        %combine model with config
        model_table=uit.Data; %final make sure we have all the data
        configuration.model_table=model_table;

        % if we didn't assign a nst table before, we need to go make one
        % now. 
        if nnz(~cellfun(@isempty,regexpi(fieldnames(configuration),'nest_table')))==0
            configuration.nest_model=nest_table;
        end

        close(fig);
        return
    end
end