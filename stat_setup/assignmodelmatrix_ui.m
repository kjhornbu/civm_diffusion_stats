function [configuration] = assignmodelmatrix_ui(configuration_table)
%settup struct of configuration
configuration.test_criteria=configuration_table;
configuration.scalar_name='anovan_defined_matrix';
configuration.manova_name='omnimanova_defined_matrix';
configuration.zscore='none';
configuration.stratification='none';

%different model types
scalar_stat_models={'anovan_defined_matrix, anovan_no_interaction, anovan_pairwise_interaction, anovan_full_interaction,\nanova_1way, kruskalwallis. Only in MATLAB 2023+: manova_nway_fullinteraction, manova_nway_no_interaction'};
manova_stat_models={'omnimanova_full_interactions, omnimanova_defined_matrix'};

GROUP_logical_idx=~cellfun(@isempty,configuration_table.GROUP);
GROUP_positional_idx=find(GROUP_logical_idx);
[valGROUP,~,idxGROUP]=unique(configuration_table.GROUP(GROUP_positional_idx));

SUBGROUP_logical_idx=~cellfun(@isempty,configuration_table.SUBGROUP);
SUBGROUP_positional_idx=find(SUBGROUP_logical_idx);
[valSUBGROUP,~,idxSUBGROUP]=unique(configuration_table.SUBGROUP(SUBGROUP_positional_idx));

only_interesting_col_names=vertcat(configuration_table.Column_Names(GROUP_positional_idx(idxGROUP)),configuration_table.Column_Names(SUBGROUP_positional_idx(idxSUBGROUP))); 
model_table=table('Size',[1 numel(only_interesting_col_names)],'VariableTypes',repmat({'logical'},[numel(only_interesting_col_names),1]),'VariableNames',only_interesting_col_names);
model_table.Properties.RowNames=strsplit(num2str(1))';

blank_table=model_table;

fig=uifigure('Position',[100 100 2150 550]);
main_grid = uigridlayout(fig,[1,2]);
main_grid.ColumnWidth = {'1x','1x'};
main_grid.RowHeight = {'1x'};

%LEFT Side
left_secondary_grid = uigridlayout(main_grid,[6,1]);
left_secondary_grid.ColumnWidth = {'1x'};
left_secondary_grid.RowHeight = {'1x','1x','1x',65,'1x',65};

left_top_tertiary_grid = uigridlayout(left_secondary_grid,[2,1]);
left_top_tertiary_grid.ColumnWidth = {'1x'};
left_top_tertiary_grid.RowHeight = {'1x','1x'};
uil_L1=uilabel(left_top_tertiary_grid,'text',sprintf(strcat('Scalar Statistical Model\nOptions:',32,scalar_stat_models{:})));
uitext_L1=uieditfield(left_top_tertiary_grid,'text','Value','anovan_defined_matrix');
uitext_L1.ValueChangedFcn=@(src,event) text_model(src,event,'scalar');

left_bottom_tertiary_grid = uigridlayout(left_secondary_grid,[2,1]);
left_bottom_tertiary_grid.ColumnWidth = {'1x'};
left_bottom_tertiary_grid.RowHeight = {'1x','1x'};
uil_L2=uilabel(left_bottom_tertiary_grid,'text',sprintf(strcat('Connectome Statistical Model\nOptions:',32,manova_stat_models{:})));
uitext_L2=uieditfield(left_bottom_tertiary_grid,'text','Value','omnimanova_defined_matrix');
uitext_L2.ValueChangedFcn=@(src,event) text_model(src,event,'manova');

ui_instruction=uilabel(left_secondary_grid,'text',sprintf('Click to populate matrix model representation for both regression models. Multiple entries in a row indicate interactions between clicked terms.\nClick "Main Effect Model" or "Full Interaction Model" to populate the matrix automatically. Click "Clear Matrix Model" to clear out the current matrix. Click the  + to add new rows.'));

left_extra_bottom_tertiary_grid = uigridlayout(left_secondary_grid,[1,3]);
left_extra_bottom_tertiary_grid.ColumnWidth = {'1x','1x','1x'};
left_extra_bottom_tertiary_grid.RowHeight = {'1x'};

main_effect_button = uibutton(left_extra_bottom_tertiary_grid,'Text','Main Effect Model');
main_effect_button.ButtonPushedFcn=@main_effect_pushed;

full_interaction_button = uibutton(left_extra_bottom_tertiary_grid,'Text','Full Interaction Model');
full_interaction_button.ButtonPushedFcn=@full_interaction_pushed;

clear_matrix_button = uibutton(left_extra_bottom_tertiary_grid,'Text','Clear Matrix Model');
clear_matrix_button.ButtonPushedFcn=@clear_matrix_button_pushed;

uit=uitable(left_secondary_grid);
uit.Data=model_table;

Data_size=size(model_table);
uit.ColumnEditable=repmat(true,[1,Data_size(2)]);
uit.DisplayDataChangedFcn=@track_changes;

add_row_button = uibutton(left_secondary_grid,'Text','+');
add_row_button.ButtonPushedFcn=@add_row_button_pushed;

% Right Side

right_secondary_grid = uigridlayout(main_grid,[3,1]);
right_secondary_grid.ColumnWidth = {'1x'};
right_secondary_grid.RowHeight = {'1x','1x',65};

top_tertiary_grid = uigridlayout(right_secondary_grid,[2,1]);
top_tertiary_grid.ColumnWidth = {'1x'};
top_tertiary_grid.RowHeight = {'1x',65};

uil_1=uilabel(top_tertiary_grid,'text',sprintf(strcat('Column Name for Z-Score Normalization\n\nOptions:',32,strjoin(only_interesting_col_names,', '))));
uitext_1=uieditfield(top_tertiary_grid,'text','Value','No Z-Scoring');
uitext_1.ValueChangedFcn=@(src,event) text_check_col(src,event,'zscore');

bottom_tertiary_grid = uigridlayout(right_secondary_grid,[2,1]);
bottom_tertiary_grid.ColumnWidth = {'1x'};
bottom_tertiary_grid.RowHeight = {'1x',65};

uil_2=uilabel(bottom_tertiary_grid,'text', sprintf(strcat('Column Name (ONLY 1) for Stratification\n\nOptions:',32,strjoin(only_interesting_col_names,', '))));
uitext_2=uieditfield(bottom_tertiary_grid,'text','Value','No Stratification');
uitext_2.ValueChangedFcn=@(src,event) text_check_col(src,event,'stratification');

next_button = uibutton(right_secondary_grid,'Text','NEXT');
next_button.ButtonPushedFcn=@next_button_pressed;
waitfor(next_button,'ButtonPushedFcn');

%internal actions
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
        close(fig);
        return
    end
end