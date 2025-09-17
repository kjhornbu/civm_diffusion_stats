function [Data,colorupdaterequired] = checkNumbering(src,Data,event)
colorupdaterequired=false;
current_val=src.Data{event.DisplaySelection(1),event.DisplaySelection(2)};

if regexpi(event.InteractionVariable,'^(GROUP)$')
    idx=~cellfun(@isempty,src.Data.GROUP);
    Data_str=src.Data.GROUP(idx);
end

if regexpi(event.InteractionVariable,'^(SUBGROUP)$')
    idx=~cellfun(@isempty,src.Data.SUBGROUP);
    Data_str=src.Data.SUBGROUP(idx);
end

%Check that is proper number series
for n=1:numel(Data_str)
    Data_Num(n)=str2num(Data_str{n});
end

[val,~,val_idx]=unique(Data_Num);
number_of_vals=sum(val_idx==val)>1;

if sum(number_of_vals)>0
    colorupdaterequired=true;
end

Data{event.DisplaySelection(1),event.DisplaySelection(2)}=current_val;
end