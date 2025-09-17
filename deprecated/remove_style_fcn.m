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