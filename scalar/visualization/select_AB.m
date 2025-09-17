function [Data_select_A, Data_select_B, string_test_conditions_out] = select_AB(Data,test_conditions)
%,Non_Repeating_Component_Puller_A,Non_Repeating_Component_Puller_B
%Pull the specific group data
% Find the Rows cooresponding to the data we wish to compare

Data_select_A=false(height(Data), size(test_conditions,2));
Data_select_B=false(height(Data), size(test_conditions,2));
string_test_conditions_out=cell(2, size(test_conditions,2));

for n=1:size(test_conditions,2)
    column_selection_A=strsplit(test_conditions{1,n},',');
    column_selection_B=strsplit(test_conditions{2,n},',');

    %% FIRST ENTRY IN TEST CONDITIONS
    %string_test_conditions=cell(2, numel(column_selection_A));
    %{
    % the (mostly) original code prior to james changing it, and making the
    % sub funciton
    indiv_test_select_A=false(height(Data), numel(column_selection_A));
    for column_setting=1:numel(column_selection_A)
        column_entry_A=strsplit(column_selection_A{1,column_setting},':');

        if ~isempty(column_entry_A{1,2})
            try
                % Data_IDX=~cellfun(@isempty,regexpi(Data.Properties.VariableDescriptions,strcat('^',column_entry_A{1,1},'$')));
                %indiv_test_select_A(:,column_setting) = ~cellfun(@isempty,regexpi(Data{:,Data_IDX},strcat('^',column_entry_A{1,2},'$')));

                data_col_n=column_find(Data.Properties.VariableDescriptions,['^' column_entry_A{1,1} '$']);
                assert(numel(data_col_n)==1,'Trouble finding %s in column descriptions!',column_entry_A{1,1});
                indiv_test_select_A(:,column_setting) = row_find(Data,data_col_n,[ '^' column_entry_A{1,2} '$'],1);
                string_test_conditions{1,column_setting}=column_entry_A{1,2};
            catch merr
                warning(merr.identifier,'Failed to figure out column positions: %s',merr.message);
                keyboard;
            end
        else
            string_test_conditions{1,column_setting}='';
            %pull all from column because we are not considering any
            %segmentation of this column for critera
            indiv_test_select_A(:,column_setting)=repmat(true,size(Data,1),1);
            indiv_test_select_A(:,column_setting)=true(size(Data,1),1);
        end
    end
    %}
    
    [ indiv_test_select_A, string_test_conditions_out{1,n} ]=selector(Data,column_selection_A);
    Data_select_A(:,n) = sum(indiv_test_select_A,2)==size(indiv_test_select_A,2);

    %% SECOND ENTRY IN TEST CONDITIONS
    %{
    for column_setting=1:numel(column_selection_B)
        column_entry_B=strsplit(column_selection_B{1,column_setting},':');
        if ~isempty(column_entry_B{1,2})
            try
                Data_IDX=~cellfun(@isempty,regexpi(Data.Properties.VariableDescriptions,strcat('^',column_entry_B{1,1},'$')));
                indiv_test_select_B(:,column_setting)=~cellfun(@isempty,regexpi(Data{:,Data_IDX},strcat('^',column_entry_B{1,2},'$')));
                string_test_conditions{2,column_setting}=column_entry_B{1,2};
            catch
                keyboard;
            end
        else
            %pull all from column because we are not considering any
            %segmentation of this column for critera
            string_test_conditions{2,column_setting}='';
            indiv_test_select_B(:,column_setting)=repmat(true,size(Data,1),1);
        end
    end
    Data_select_B(:,n)=sum(indiv_test_select_B,2)==size(indiv_test_select_B,2);
    %}

    [ indiv_test_select_B, string_test_conditions_out{2,n} ]=selector(Data,column_selection_B);
    Data_select_B(:,n) = sum(indiv_test_select_B,2)==size(indiv_test_select_B,2);

    %{
    string_test_conditions_out{1,n}=strjoin(string_test_conditions(1,:),' ');
    string_test_conditions_out{2,n}=strjoin(string_test_conditions(2,:),' ');
    %}
end

end
function [column_matches,string_condition]=selector(Data, column_description_and_value_pairs)
% return where column_values(columns found by column desciption) match.
column_matches=false(height(Data), numel(column_description_and_value_pairs));
string_condition=cell([1,numel(column_description_and_value_pairs)]);
for column_setting=1:numel(column_description_and_value_pairs)
    % split column_setting into column & value, 
    % (i think this should always have 2 entries.)
    column_description_and_value=strsplit(column_description_and_value_pairs{1,column_setting},':');
    assert(numel(column_description_and_value)==2,'I thought these were only supposed to have 2 entries. -james');

    if ~isempty(column_description_and_value{2})
        try
            data_col_n=column_find(Data.Properties.VariableDescriptions,['^' column_description_and_value{1} '$']);
            assert(numel(data_col_n)==1,'Trouble finding %s in column descriptions!',column_description_and_value{1});
            column_matches(:,column_setting) = row_find(Data,data_col_n,[ '^' column_description_and_value{2} '$'],1);
            string_condition{1,column_setting}=column_description_and_value{2};
        catch merr
            warning(merr.identifier,'Failed to figure out column positions: %s',merr.message);
            keyboard;
        end
    else
        string_condition{1,column_setting}='';
        %pull all from column because we are not considering any
        %segmentation of this column for critera
        %indiv_test_select_A(:,column_setting)=repmat(true,size(Data,1),1);
        column_matches(:,column_setting)=true(height(Data),1);
    end
end
    string_condition=strjoin(string_condition,' ');
end

