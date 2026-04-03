function [keep_last_dataframe] = do_dataframe_ui(setup_file)

fig=uifigure('Position',[100 100 2150 550]);


main_grid = uigridlayout(fig,[3,1]);
main_grid.RowHeight = {'1x','1x',65};
main_grid.ColumnWidth = {'1x'};

uil=uilabel(main_grid,'text',sprintf(['A dataframe file exists for this project at: %s.\n\n' ...
    'DO YOU WANT TO MAKE A NEW DATAFRAME FILE?'],setup_file));

yes_no_buttons = uibuttongroup(main_grid);
rb1 = uiradiobutton(yes_no_buttons,'Position',[10 60 91 15]);
rb2 = uiradiobutton(yes_no_buttons,'Position',[10 38 91 15]);
rb1.Text = 'YES';
rb1.Value= 0;
rb2.Text = 'NO';

next_button = uibutton(main_grid,'Text','NEXT');
next_button.ButtonPushedFcn=@next_button_pressed;
waitfor(next_button,'ButtonPushedFcn');

%Internal Functions
    function next_button_pressed(src,event)
        if strcmp(yes_no_buttons.SelectedObject.Text,'NO')
            keep_last_dataframe = 1;
        elseif strcmp(yes_no_buttons.SelectedObject.Text,'YES')
            keep_last_dataframe = 0;
        end
        close(fig);
        return
    end
end