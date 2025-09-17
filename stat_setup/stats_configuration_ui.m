function [Data] = stats_configuration_ui(input_doc)

if istable(input_doc)
    dataFrame=input_doc;
else
    dataFrame=civm_read_table(input_doc);
end

[Note,algorithm_Output] = james_to_study_inDataFrameEntry(dataFrame);

Data=table;

dataFrame_name=dataFrame.Properties.VariableNames;
vcount_logical_idx=~cellfun(@isempty,regexpi(dataFrame_name,'^(vcount)$'));
vcount_positional_idx=find(vcount_logical_idx);

for n=1:vcount_positional_idx-1
    Data.('Column_Names'){n}=dataFrame_name{n};
end

%Get 3 New Columns
Data=addvars(Data,repmat({''},size(Data,1),1),'Before',1);
Data=addvars(Data,repmat({''},size(Data,1),1),'Before',1);
Data=addvars(Data,repmat({''},size(Data,1),1),'Before',1);

%And Call them something Useful
Data = renamevars(Data,1:3,["GROUP","SUBGROUP","RANDOM"]);

%Start the ui for figure generation
fig=uifigure('Position',[100 100 2150 550]);
main_grid = uigridlayout(fig,[1,2]);
main_grid.ColumnWidth = {'1x','1x'};
main_grid.RowHeight = {'1x'};

uit=uitable(main_grid);
uit.Data=Data;

Data_size=size(Data);
uit.ColumnEditable=repmat(true,[1,Data_size(2)-1]);
uit.DisplayDataChangedFcn=@track_changes;

secondary_grid = uigridlayout(main_grid,[3,1]);
secondary_grid.ColumnWidth = {'1x'};
secondary_grid.RowHeight = {'1x','1x',65};

uil=uilabel(secondary_grid,'Text',Note);
uit_2=uitable(secondary_grid);
uit_2.Data=algorithm_Output;

next_button = uibutton(secondary_grid,'Text','NEXT');
next_button.ButtonPushedFcn=@next_button_pressed;
waitfor(next_button,'ButtonPushedFcn');

%internal actions
    function track_changes(src,event)
        %Check for only one of the number in the data set
        test=regexpi(event.InteractionVariable,'^(GROUP|SUBGROUP)$'); 
        if ~isempty(test) && test
            [Data,colorupdaterequired] = checkNumbering(src,Data,event);
        else
            [Data,colorupdaterequired] = assignRandomEffect(src,Data,event);
        end

        %color those that are in error
        if colorupdaterequired
            colorupdater_stats_config(src,event)
        end
    end

    function next_button_pressed(src,event)
        close(fig);
        return
    end

%External Functions put back in
    function [Data, colorupdaterequired] = assignRandomEffect(src,Data,event)
        colorupdaterequired=false;
        current_val=src.Data{event.DisplaySelection(1),event.DisplaySelection(2)};
        prior_val=Data{event.DisplaySelection(1),event.DisplaySelection(2)};

        if ~strcmp(current_val,prior_val)
            colorupdaterequired=true;
        end

        Data{event.DisplaySelection(1),event.DisplaySelection(2)}=current_val;
    end

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
end