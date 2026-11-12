function [Data] = stats_configuration_ui(input_doc)

%% Preliminaries
if istable(input_doc)
    dataFrame=input_doc;
else
    dataFrame=civm_read_table(input_doc);
end

[Note,algorithm_Output] = james_to_study_inDataFrameEntry(dataFrame);
[Data] = create_data_table(dataFrame);

%% Start the GUI
fig=uifigure('Position',[100 100 2150 550]);
main_grid = uigridlayout(fig,[1,2]);
main_grid.ColumnWidth = {'1x','1x'};
main_grid.RowHeight = {'1x'};

uit=uitable(main_grid);
uit.Data=Data;

Data_size=size(Data);
uit.ColumnEditable=repmat(true,[1,Data_size(2)-1]);
uit. CellEditCallback=@track_changes;
 
data_grid = uigridlayout(main_grid,[3,1]);
data_grid.ColumnWidth = {'1x'};
data_grid.RowHeight = {'1x','1x',65};

uilabel(data_grid,'Text',Note);
uit_2=uitable(data_grid);
uit_2.Data=algorithm_Output;

next_button = uibutton(data_grid,'Text','NEXT');
next_button.ButtonPushedFcn=@next_button_pressed;
waitfor(next_button,'ButtonPushedFcn');

%% internal actions
    function track_changes(src,event)
        find_changed_col=event.Source.Data.Properties.VariableNames(event.Indices(2));

        %Check for only one of the number in the data set
        test=~cellfun(@isempty,regexpi(find_changed_col,'^(GROUP|SUBGROUP)$'));
        random_test=~cellfun(@isempty,regexpi(find_changed_col,'^(RANDOM)$'));
        cont_test=~cellfun(@isempty,regexpi(find_changed_col,'^(CONTINUOUS)$'));

        if test
            [Data,colorupdaterequired] = checkNumbering(src,event,Data,find_changed_col);
        elseif random_test
            [Data,colorupdaterequired] = assignRandomEffect(src,event,Data);
        elseif cont_test
            [Data,colorupdaterequired] = assignContinuousVariable(src,event,Data);
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

    function [Data, colorupdaterequired] = assignRandomEffect(src,event,Data)
        colorupdaterequired=false;
        current_val=event.NewData;
        Data{event.Indices(1),event.Indices(2)}={current_val};
    end

    function [Data, colorupdaterequired] = assignContinuousVariable(src,event,Data)
        data_grab=Data.Column_Names{event.Indices(1)};
        colorupdaterequired=false;
        current_val=event.NewData;
        if ~isempty(event.NewData)
            [colorupdaterequired]=checkContinous(src,data_grab,colorupdaterequired);
        else
            %update if empty to remove color
            colorupdaterequired=true;
        end
        Data{event.Indices(1),event.Indices(2)}={current_val};
    end

    function[colorupdaterequired] = checkContinous(src,color_grab,colorupdaterequired)
        data_col=dataFrame(:,color_grab);
        colType = class(dataFrame.(color_grab));
        [a,~,c]=unique(data_col);

        %Autochecker checks for things that automatically would rule
        %something out as a continous variable-categorical terms. For
        %numeric terms that have very low amounts of repeats, or is just
        %nans the size of the data.

        if nnz(strcmp(colType,{'string','cell'})) | ( strcmp(colType,'double') & nnz(sum(c==1:numel(a)')>2)) | nnz(isnan(table2array(a(:,1))))==height(data_col)
            % Strings cannot be continous.
            % if it is double and has more than 2 entries of the
            % exact same value per entry -- probably continous
            colorupdaterequired=true;
        end
    end

    function [Data,colorupdaterequired] = checkNumbering(src,event,Data,find_Interaction_col)
        colorupdaterequired=false;
        current_val=event.NewData;

        if ~cellfun(@isempty,regexpi(find_Interaction_col,'^(GROUP)$'))
            idx=~cellfun(@isempty,src.Data.GROUP);
            Data_str=src.Data.GROUP(idx);
        end

        if ~cellfun(@isempty,regexpi(find_Interaction_col,'^(SUBGROUP)$'))
            idx=~cellfun(@isempty,src.Data.SUBGROUP);
            Data_str=src.Data.SUBGROUP(idx);
        end

        %Check that is proper number series
        %If we make the column empty don't check here.
        if ~isempty(Data_str)
            for n=1:numel(Data_str)
                Data_Num(n)=str2num(Data_str{n});
            end

            [val,~,val_idx]=unique(Data_Num);
            number_of_vals=sum(val_idx==val)>1;

            if sum(number_of_vals)>0
                colorupdaterequired=true;
            end
        end
        if isempty(current_val)
            %update if empty to remove color
            colorupdaterequired=true;
        end

        Data{event.Indices(1),event.Indices(2)}={current_val};
    end

    function [] = colorupdater_stats_config(src,event)
       %get row
        try
            row_position = event.DisplaySelection(1);
        catch
            row_position = event.DisplayIndices(1);
        end

        remove_style_fcn(src,row_position)

        try
            col_positions = event.DisplaySelection(2);
        catch
            col_positions = event.DisplayIndices(2);
        end

        if (col_positions==1 | col_positions==2 | col_positions==4) & ~isempty(event.NewData)
            color = [1 1 0]; % Yellow
            s = uistyle("BackgroundColor",color);
            addStyle(src,s,"cell",[row_position,col_positions]);
        elseif ~isempty(event.NewData)
            color = [1 0 0]; %red -- Some other error and there is data there
            s = uistyle("BackgroundColor",color);
            addStyle(src,s,"cell",[row_position,col_positions]);
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

    function [Data] = create_data_table(dataFrame)
        Data=table;

        dataFrame_name=dataFrame.Properties.VariableNames;
        vcount_logical_idx=~cellfun(@isempty,regexpi(dataFrame_name,'^(vcount)$'));
        vcount_positional_idx=find(vcount_logical_idx);

        for n=1:vcount_positional_idx-1
            Data.('Column_Names'){n}=dataFrame_name{n};
        end

        %Get 4 New Columns
        Data=addvars(Data,repmat({''},size(Data,1),1),'Before',1);
        Data=addvars(Data,repmat({''},size(Data,1),1),'Before',1);
        Data=addvars(Data,repmat({''},size(Data,1),1),'Before',1);
        Data=addvars(Data,repmat({''},size(Data,1),1),'Before',1);

        %And Call them something Useful
        Data = renamevars(Data,1:4,["GROUP","SUBGROUP","RANDOM","CONTINUOUS"]);
    end
end