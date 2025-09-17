close all
clear all

%% The actual editable summary cloud notebook

%Notebook_info need to be a class??
BD='/Volumes/dusom_civm-kjh60/All_Staff';
HOME_DIR=BD;
studyID='24.niehs.01';
project_dir=fullfile(HOME_DIR,studyID);
google_doc=fullfile(project_dir,'google_sheet_caps', '24.niehs.01 - Phase I_2025-06-24-NoLow.txt');
cloud_notebook=civm_read_table(google_doc);

[notebook_info] = generate_cloudnotebook_summary_table(cloud_notebook);
[notebook_info] = cloudnotebook_table_ui(notebook_info);

function [notebook_info] = cloudnotebook_table_ui(notebook_info)
%Plot/Visualize the Summary Table

fig=uifigure('Position',[100 100 2150 550]);
main_grid = uigridlayout(fig,[3,1]);
main_grid.ColumnWidth = {'1x'};
main_grid.RowHeight = {'1x',65, 65};

uit=uitable(main_grid);
uit.Data=notebook_info.edit_table;

%should be able to edit the entire table
notebook_size=size(notebook_info.edit_table);
uit.ColumnEditable=repmat(true,[1,notebook_size(2)]);

%Add update/end buttons at bottom
%apply_change_button = uibutton(main_grid,'Text','APPLY CHANGES');

    function update_and_go_again(uibtn,event,src)
        % integrate new things from uit.Data to note_info
        update_cloudnotebook_ui(uit,notebook_info);
    end

fcn=@update_and_go_again; 
apply_change_button = uibutton(main_grid,'Text','APPLYCHANGES','ButtonPushedFcn',fcn);

%apply_change_button = uibutton(main_grid,'Text','APPLY CHANGES','ButtonPushedFcn',@(src,event)update_cloudnotebook_ui(uit,notebook_info));

done_button = uibutton(main_grid,'Text','DONE','ButtonPushedFcn',@(src,event)finish_cloudnotebook_editing(uit,notebook_info,project_dir));

end

function [] = update_cloudnotebook_ui(uit,notebook_info)

% Clear inital color selections
if size(uit.StyleConfigurations,1)>0
    removeStyle(uit,1:size(uit.StyleConfigurations,1))
end

%Update the Summary table for the Cloud Notebook
[notebook_info] = check_drop_entry(uit,notebook_info); 
%classes are a gross syntax in matlab so just working from the table to determine what should be done
[notebook_info] = drop_entry_cloudnotebook_summary(uit,notebook_info);


color_entry_cloudnotebook_summary(uit,notebook_info);
end

function [] = finish_cloudnotebook_editing(uit,notebook_info,project_dir)
output_table = table;
%remove drop entries in notebook information
[notebook_info] = check_drop_entry(uit,notebook_info); %respelling of groups issue? 

output_table=notebook_info.original_table(:,notebook_info.keep_idx); 


%civm_write_table(,fullfile(project_dir,strcat('Edited_GoogleSheet',date,'.txt')));

end

function [notebook_info] = color_entry_cloudnotebook_summary(uit,notebook_info)
notebook_size=size(notebook_info.original_table);
for n=1:numel(uit.Data.IDX)
    logical_idx_column=notebook_info.edit_table.IDX==uit.Data.IDX(n)';
    positional_idx_column=find(logical_idx_column);

    if notebook_info.keep_idx(positional_idx_column)
        include=0;
        exclude=0;

        %% start with all include no exclude -- This doesn't work if the
        %% spelling changes between the original and uit! If changing spelling it has to be on the index of the thing working with to include or not rather than using regexp. 

        include_critera=true(numel(notebook_info.val{positional_idx_column}),1);
        exclude_critera=false(numel(notebook_info.val{positional_idx_column}),1);

        if ~isempty(uit.Data.("INCLUDE"){n})
            include_critera=~cellfun(@isempty,regexpi(notebook_info.val{positional_idx_column}{:,1}, uit.Data.("INCLUDE"){n}));
            if sum(include_critera)==0
                include_critera=false(numel(notebook_info.val{positional_idx_column}),1);
                string_position=strsplit(uit.Data.("INCLUDE"){n});
                count=1;
                for m=1:numel(string_position)
                   temp=str2num(string_position{m}); 
                   if ~isempty(temp)
                       position_to_include(count)=temp;
                       count=count+1;
                   end
                end
                include_critera(position_to_include)=true;
            end
            s = uistyle("BackgroundColor",[0.6 1 0.6]);
            addStyle(uit,s,"cell",[n,2]);
            include=1;
        end

        if ~isempty(uit.Data.("EXCLUDE"){n})
            exclude_critera=cellfun(@isempty,regexpi(notebook_info.val{positional_idx_column}{include_critera,1}, uit.Data.("EXCLUDE"){n}));
            if sum(exclude_critera)==0
                exclude_critera=true(numel(notebook_info.val{positional_idx_column}),1);
                string_position=strsplit(uit.Data.("EXCLUDE"){n});
                count=1;
                for m=1:numel(string_position)
                   temp=str2num(string_position{m}); 
                   if ~isempty(temp)
                       position_to_exclude(count)=temp;
                       count=count+1;
                   end
                end
             exclude_critera(position_to_exclude)=false;
            end
            s = uistyle("BackgroundColor",[1 0.6 0.6]);
            addStyle(uit,s,"cell",[n,3]);
            exclude=1;
        end

        if include==1 && exclude == 0 
            %only Include
            positional_idx=find(include_critera);
            color = [0.6 1 0.6];
        elseif include==0 && exclude == 1 
            %only Exclude
            positional_idx=find(exclude_critera==0);
            color = [1 0.6 0.6];
        else
            % Both together so Follow Include Color
            positional_idx=find(include_critera(exclude_critera==0));
            color = [0.6 1 0.6];
        end

        row = repmat(n,size(positional_idx));
        col = positional_idx;

        logical_index_with_Data=~cellfun(@isempty,strrep(uit.Data{n,5:end},' ', ''));
        count_index_with_Data=sum(logical_index_with_Data);

        if all(and(include_critera, ~exclude_critera))
            %Its staying the same so we aren't doing anything there
            continue
        elseif count_index_with_Data==1 && numel(positional_idx)>0
            %When we have those summary entries instead
            uit.Data{n,5}=sprintf('%d of %d entries are unique',numel(positional_idx),notebook_size(1));
        else
            for o=1:numel(positional_idx)
                %only color the Include Critera that remains
                s = uistyle("BackgroundColor",color);
                addStyle(uit,s,"cell",[row(o),4+col(o)]);
            end
        end
    end
end

end

function [notebook_info] = check_drop_entry(uit,notebook_info)
%Make sure we don't have any previously dropped entries not accounted for
%in original state table.
Current_Data_Num=numel(uit.Data.IDX);
if Current_Data_Num == numel(notebook_info.edit_table.IDX)
    %if nothing has been removed nothing needs to be corrected
    return;
else
    notebook_info.keep_idx=false(size(notebook_info.keep_idx));
    for n=1:Current_Data_Num
        logical_idx=notebook_info.edit_table.IDX==uit.Data.IDX(n)';
        positional_idx=find(logical_idx);
        notebook_info.keep_idx(positional_idx)=true;
    end
end
end

function [notebook_info] = drop_entry_cloudnotebook_summary(uit,notebook_info)
no_regexp='^([Nn])$|^([Nn][Oo])$|^(0)$';

current_Data=notebook_info.keep_idx;
current_Data_positional_idx=find(current_Data);
for n=1:numel(current_Data_positional_idx)
    if notebook_info.keep_idx(current_Data_positional_idx(n))
        if ~(~isempty(regexpi(uit.Data.("DROP?"){n}, no_regexp)) || isempty(uit.Data.("DROP?"){n}))
            notebook_info.keep_idx(current_Data_positional_idx(n))=false;
            continue; 
        end
    end
end

%Remove worthless data
uit.Data=uit.Data(notebook_info.keep_idx(current_Data_positional_idx),:);
end





