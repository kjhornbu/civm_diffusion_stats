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
col_positions_logical = ~cellfun(@isempty,regexpi(notebook_info.val{row_position}{:,1}, src.Data.("EXCLUDE"){row_position}));
%col_positions_logical=reg_match(notebook_info.val{row_position}{:,1}, src.Data.("EXCLUDE"){row_position});
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