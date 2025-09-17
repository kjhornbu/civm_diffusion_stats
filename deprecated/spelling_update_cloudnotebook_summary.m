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
        update_idx=find(strcmp(table2array(notebook_info.val{event.DisplaySelection(1)}),prior_val));
        assign_update_idx=notebook_info.idx(:,event.DisplaySelection(1))==update_idx;
        notebook_info.original_table{assign_update_idx,event.DisplaySelection(1)}={current_val};

        notebook_info.edit_table{event.DisplaySelection(1),event.DisplaySelection(2)}=string(current_val);
        notebook_info.val{event.DisplaySelection(1)}{update_idx,1}={current_val};
        %str2num(event.InteractionVariable)
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