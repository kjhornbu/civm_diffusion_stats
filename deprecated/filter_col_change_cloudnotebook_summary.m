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