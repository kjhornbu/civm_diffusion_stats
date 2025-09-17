close all
clear all

%% The actual editable summary cloud notebook

%Notebook_info need to be a class??
BD='/Volumes/dusom_civm-kjh60/All_Staff';
HOME_DIR=BD;
studyID='24.niehs.01';
project_dir=fullfile(HOME_DIR,studyID);
google_doc=fullfile(project_dir,'google_sheet_caps', '24.niehs.01 - Phase I_2025-05-23.tsv');
cloud_notebook=civm_read_table(google_doc);

[notebook_info] = cloudnotebook_table_ui(cloud_notebook,project_dir);

function [notebook_info] = cloudnotebook_table_ui(cloud_notebook,project_dir)
%Makes the summary table form of the cloudnotebook
[notebook_info] = generate_cloudnotebook_summary_table(cloud_notebook);

%Plot/Visualize the Summary Table
fig=uifigure('Position',[100 100 2150 550]);
main_grid = uigridlayout(fig,[3,1]);
main_grid.ColumnWidth = {'1x'};
main_grid.RowHeight = {'1x',65,65};

uit=uitable(main_grid);
uit.Data=notebook_info.edit_table;

%should be able to edit the entire table
notebook_size=size(notebook_info.edit_table);
uit.ColumnEditable=repmat(true,[1,notebook_size(2)]);
uit.DisplayDataChangedFcn=@track_changes;

done_button = uibutton(main_grid,'Text','DONE');
done_button.ButtonPushedFcn=@done_button_pressed;

close_button = uibutton(main_grid,'Text','CLOSE');
close_button.ButtonPushedFcn=@close_button_pressed;

%internal actions
    function track_changes(src,event)
        %in theory src == uit
        if strcmp(event.InteractionVariable,'INCLUDE')|strcmp(event.InteractionVariable,'EXCLUDE')|strcmp(event.InteractionVariable,'DROP?')
            [notebook_info,colorupdaterequired] = filter_col_change_cloudnotebook_summary(src,notebook_info,event);
        else
            [notebook_info,colorupdaterequired] = spelling_update_cloudnotebook_summary(src,notebook_info,event);
        end
        if colorupdaterequired
            colorupdater(src,notebook_info,event)
        end
    end

    function done_button_pressed(src,event)
        finish_cloudnotebook_editing(uit,notebook_info,project_dir)
    end

    function close_button_pressed(src,event)
        close(fig)
    end

end

function [notebook_info,colorupdaterequired] = filter_col_change_cloudnotebook_summary(src,notebook_info,event)
current_val=src.Data{event.DisplaySelection(1),event.DisplaySelection(2)};

%check previous value isn't different
prior_val=notebook_info.edit_table{event.DisplaySelection(1),event.DisplaySelection(2)};

%if different set update detected (color update required)
if ~strcmp(current_val,prior_val)
    colorupdaterequired=1;
end

notebook_info.edit_table{event.DisplaySelection(1),event.DisplaySelection(2)}=current_val;
end

function [] = colorupdater(src,notebook_info,event)
ui_size=size(src.Data);

row_position = event.DisplaySelection(1);
remove_style_fcn(src,row_position)

%check for include entry on row
% INCLUDE
color = [0.6 1 0.6]; %green
col_positions_logical = ~cellfun(@isempty,regexpi(notebook_info.val{row_position}{:,1}, src.Data.("INCLUDE"){row_position}));
col_positions=find(col_positions_logical)+4;

if ~isempty(src.Data.("INCLUDE"){row_position})
    col_positions(end+1) = 2; %add in the column that is the include
end
for o=1:numel(col_positions)
    %only color the Include Critera that remains
    s = uistyle("BackgroundColor",color);
    addStyle(src,s,"cell",[row_position,col_positions(o)]);
end

%EXCLUDE
color = [1 0.6 0.6]; % red
%col_positions_logical = ~cellfun(@isempty,regexpi(notebook_info.val{event.DisplaySelection(1)}{:,1}, src.Data.("EXCLUDE"){event.DisplaySelection(1)}));
% SORRY, UNTESTED, reg_match certainly supporsts an input of cells you're
% matching, but this may not work.
col_positions_logical=reg_match(notebook_info.val{row_position}{:,1}, src.Data.("EXCLUDE"){row_position});
col_positions=find(col_positions_logical)+4;

if ~isempty(src.Data.("EXCLUDE"){row_position})
    col_positions(end+1) = 3; %add in the column that is the include
end
for o=1:numel(col_positions)
    %only color the Exclude Critera that remains
    s = uistyle("BackgroundColor",color);
    addStyle(src,s,"cell",[row_position,col_positions(o)]);
end

% Assorted Other Issues
if ~reg_match(event.InteractionVariable,'EXCLUDE|INCLUDE|DROP?')
    color = [1 1 0]; %yellow hey there is somethign going on here...
    % (probably adding something outside of scope) That isn't in one of our main update columns
    col_positions= event.DisplaySelection(2);

    for o=1:numel(col_positions)
        %only color the Include Critera that remains
        s = uistyle("BackgroundColor",color);
        addStyle(src,s,"cell",[row_position,col_positions(o)]);
    end
end

%DROP
drop_entry=str2num(src.Data.("DROP?"){row_position});

if drop_entry == 1
    color = [0.5 0 0]; %Maroon
    col_positions=1:ui_size(2);

    for o=1:numel(col_positions)
        %only color the Include Critera that remains
        s = uistyle("BackgroundColor",color);
        addStyle(src,s,"cell",[row_position,col_positions(o)]);
    end
end
end

function[] = remove_style_fcn(src,row_position)
%For a given row remove all the style
check_select=[];

for m=1:numel(src.StyleConfigurations.TargetIndex)
    temp_Position=src.StyleConfigurations.TargetIndex{m};
    check_select(m)=temp_Position(1)==row_position;
end

select_positions=find(check_select);
if ~isempty(select_positions)
    removeStyle(src,select_positions);
end
end

function [notebook_info,colorupdaterequired] = spelling_update_cloudnotebook_summary(src,notebook_info,event)
current_val=src.Data{event.DisplaySelection(1),event.DisplaySelection(2)};

%check previous value isn't different
prior_val=notebook_info.edit_table{event.DisplaySelection(1),event.DisplaySelection(2)};

% beacuase empty string classes DO NOT count for "isempty" we will force to
% char array. We should look into docs a bit more to find a more correct
% way... if there is one. 
prior_val=char(prior_val);
current_val=char(current_val);

colorupdaterequired=0;
if event.DisplaySelection(2) > 4
    if strcmp(current_val,prior_val) %same data
    elseif isempty(prior_val) && (~strcmp(current_val,prior_val)) %different data where there should be no data (outside of the vals)
        % have to convert back to string
        prior_val=string(prior_val);
        src.Data{event.DisplaySelection(1),event.DisplaySelection(2)}=prior_val;
        colorupdaterequired=1;
    elseif ~strcmp(current_val,prior_val) %different data where clearing out data or different data where adding data
        notebook_info.edit_table{event.DisplaySelection(1),event.DisplaySelection(2)}=string(current_val);
        notebook_info.val{event.DisplaySelection(1)}{str2num(event.InteractionVariable),1}={current_val};
        update_idx=notebook_info.idx(event.DisplaySelection(2),event.DisplaySelection(1));
        assign_update_idx=notebook_info.idx(:,event.DisplaySelection(1))==update_idx;
        notebook_info.original_table{assign_update_idx,event.DisplaySelection(1)}={current_val};
    end
else
    if strcmp(current_val,prior_val) %same data
    elseif ~strcmp(current_val,prior_val) %different data where clearing out data or different data where adding data
        notebook_info.edit_table{event.DisplaySelection(1),event.DisplaySelection(2)}=string(current_val);
        notebook_info.val{event.DisplaySelection(1)}.Properties.VariableNames={current_val};
        notebook_info.original_table.Properties.VariableNames{event.DisplaySelection(1)}=current_val;
    end
end
end

function [] = finish_cloudnotebook_editing(src,notebook_info,project_dir)
%apply Regexpi Entries
logical_include_idx=~cellfun(@isempty,src.Data.("INCLUDE"));
logical_exclude_idx=~cellfun(@isempty,src.Data.("EXCLUDE"));
logical_drop_idx=~cellfun(@isempty,src.Data.("DROP?"));

include_exclude_vector=true(size(notebook_info.original_table,1),1);
keep_idx=true(size(notebook_info.original_table,2),1);

for n=1:numel(logical_include_idx)
    if logical_include_idx(n)
        col_positions_logical = ~cellfun(@isempty,regexpi(notebook_info.val{n}{:,1}, src.Data.("INCLUDE"){n}));
        col_positions=find(col_positions_logical);
        logical_idx=sum(notebook_info.idx(:,n)==col_positions',2)>0;
        include_exclude_vector(logical_idx)=true;
    end
    if logical_exclude_idx(n)
        col_positions_logical = ~cellfun(@isempty,regexpi(notebook_info.val{n}{:,1}, src.Data.("EXCLUDE"){n}));
        col_positions=find(col_positions_logical);
        logical_idx=sum(notebook_info.idx(:,n)==col_positions',2)>0;
        include_exclude_vector(logical_idx)=false;
    end
    if logical_drop_idx(n)
        if src.Data.("DROP?"){n}
            keep_idx(n)=false;
        end
    end
end
output_table=notebook_info.original_table(include_exclude_vector,:);
output_table=output_table(:,keep_idx);
civm_write_table(output_table,fullfile(project_dir,strcat('Edited_GoogleSheet_',date,'.txt')));
end




