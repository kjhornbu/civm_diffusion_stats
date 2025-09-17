function [Data, colorupdaterequired] = assignRandomEffect(src,Data,event)
colorupdaterequired=false;
current_val=src.Data{event.DisplaySelection(1),event.DisplaySelection(2)};
prior_val=Data{event.DisplaySelection(1),event.DisplaySelection(2)};

if ~strcmp(current_val,prior_val)
    colorupdaterequired=true;
end

Data{event.DisplaySelection(1),event.DisplaySelection(2)}=current_val;
end