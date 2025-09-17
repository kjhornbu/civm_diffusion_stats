function [embedded_data] = format_embedded_data_file(df,test_criteria,embedded_data,output_file,file_type)
df_tmp=table;

%Grouping data Selection
subgroup_cols=logical(cellfun(@(C) reg_match(C,'^(group[0-9]+|subgroup[0-9]+)$'),df.Properties.VariableNames));
%Key record keeping components for data
entry_cols=logical(cellfun(@(C) reg_match(C,'specimen|file|^(CIVM_ID)$|^(CIVM_Scan_ID)$'),df.Properties.VariableNames));

n_graphs=size(df,1);

%moving vector data into a long format repeated to follow the format of the vector file 
if isempty(regexpi(file_type,'(norepeat)$'))

    total_names=df.Properties.VariableNames(entry_cols|subgroup_cols);
    total_descriptions=df.Properties.VariableDescriptions(entry_cols|subgroup_cols);

    for n=1:n_graphs
        if ~isempty(regexpi(file_type,'^(regional)$'))
            repeat_count=df.vcount(n);
        elseif ~isempty(regexpi(file_type,'^(regional_bilat)$'))
            repeat_count=df.vcount(n)/2;
        elseif ~isempty(regexpi(file_type,'^(global)$'))
            repeat_count=1;
        end

        for m=1:size(total_names,2)
            df_tmp.(total_names{m})((n-1)*repeat_count+1:n*repeat_count)=repmat(df.(total_names{m})(n),1,repeat_count);
        end

        try
            if n==1
                df_tmp.Properties.VariableDescriptions=total_descriptions;
            end
        catch
            keyboard;
        end
        if ~isempty(regexpi(file_type,'^(regional)$'))
            df_tmp.vertex((n-1)*repeat_count+1:n*repeat_count)=1:repeat_count;
        elseif ~isempty(regexpi(file_type,'^(regional_bilat)$'))
            df_tmp.vertex((n-1)*repeat_count+1:n*repeat_count)=1:repeat_count;
        end
    end
else
    if ~isempty(regexpi(file_type,'^(regionalnorepeat)$'))
        vertex_count=unique(df.vcount);
    elseif ~isempty(regexpi(file_type,'^(regional_bilatnorepeat)$'))
        vertex_count=unique(df.vcount)/2;
    elseif ~isempty(regexpi(file_type,'^(globalnorepeat)$'))
        vertex_count=1;
    end


    if ~isempty(regexpi(file_type,'^(regionalnorepeat)$'))
        df_tmp.vertex(1:vertex_count)=1:vertex_count;
    elseif ~isempty(regexpi(file_type,'^(regional_bilatnorepeat)$'))
        df_tmp.vertex(1:vertex_count)=1:vertex_count;
    end

end
%Assign animal numbers like the JHU code does
%{
[~,group_names,group_name_idx] = find_group_information_from_groupingcriteria(df_tmp,test_criteria{1});
animal_vals = zeros(size(df_tmp.file));

for group = 1:numel(group_names)
    temp = df_tmp.file(group_name_idx==group);
    [~, ~, ic] = unique(temp, 'stable');
    animal_vals(group_name_idx==group) = ic;
end

df_tmp.animal=animal_vals;
%}
%reposition the actual data into the proper location of the ase file.
try
    for n=1:size(embedded_data,2)
        df_tmp.(['X',num2str(n)])=embedded_data(:,n);
    end
catch
    keyboard;
end

%now since we have moved all over from the ase to providing back the
%information to the table again we can get rid of our original ase without
%header data and turn it back to the ase. 

clear embedded_data;
embedded_data= df_tmp;

try
    % THIS WOULD BE NICE, BUT WE'RE USING THE FILE IN R. We dont expect one
    % of our "Rob" ready sheets will work there.
    % 
    % Maybe we should write two copies? one for us, and one for R?
     
    % civm_write_table(embedded_data, output_file);
    writetable(embedded_data, output_file);

%     [path,file_name,extension]=fileparts(output_file);
%     temp_file_name=strsplit(file_name,'_');
%     VariableNames=embedded_data.Properties.VariableNames;
%     VariableDescriptions=embedded_data.Properties.VariableDescriptions;
%     idx_switch=find(~cellfun(@isempty,VariableDescriptions));
% 
%     embedded_data_user_readable=embedded_data;
% 
%     for n=1:numel(idx_switch)
%         embedded_data_user_readable.Properties.VariableNames{idx_switch(n)}=VariableDescriptions{idx_switch(n)};
%         embedded_data_user_readable.Properties.VariableDescriptions{idx_switch(n)}=VariableNames{idx_switch(n)};
%     end
% 
%     civm_write_table(embedded_data_user_readable, fullfile(path,strcat(strjoin(temp_file_name(1:numel(temp_file_name)-1),'_'),'_User_Readable',extension)));
catch
    keyboard;
end
end

