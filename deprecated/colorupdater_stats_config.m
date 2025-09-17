function [] = colorupdater_stats_config(src,event)
ui_size=size(src.Data);

row_position = event.DisplaySelection(1);
remove_style_fcn(src,row_position)

% Assorted Other Issues
if reg_match(event.InteractionVariable,'SUBGROUP|GROUP')
    color = [1 1 0]; %yellow hey there is somethign going on here...
    % (probably adding something outside of scope) That isn't in one of our main update columns
    col_positions= event.DisplaySelection(2);

    for o=1:numel(col_positions)
        %only color the Include Critera that remains
        s = uistyle("BackgroundColor",color);
        addStyle(src,s,"cell",[row_position,col_positions(o)]);
    end
end

%Random
random_entry=str2num(src.Data.("RANDOM"){row_position});
if random_entry == 1
    color = [0.6 1 0.6]; %green
    col_positions=1:ui_size(2);

    for o=1:numel(col_positions)
        %only color the Include Critera that remains
        s = uistyle("BackgroundColor",color);
        addStyle(src,s,"cell",[row_position,col_positions(o)]);
    end
end
end