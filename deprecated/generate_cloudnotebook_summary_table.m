function [notebook_info] = generate_cloudnotebook_summary_table(cloud_notebook)
%Generate the Summary table for the Cloud Notebook

notebook_size = size(cloud_notebook);
max_Uniques=floor((notebook_size(1)-1)/2);

VarNames(1)={'Column_Names'};
VarNames(1+(1:max_Uniques))=strsplit(num2str(1:max_Uniques),' ');

edit_table=table('Size',[notebook_size(2) numel(VarNames)],'VariableTypes',repmat({'string'},[numel(VarNames),1]),'VariableNames',VarNames);

notebook_info=struct;
for n=1:size(cloud_notebook,2)
    [val{n},~,idx(:,n)]=unique(cloud_notebook(:,n));

    if ~(iscell(val{n}{:,1}))
        temp_name=val{n}.Properties.VariableNames;
        temp=val{n}{:,1};
        for m=1:height(temp)
            temp2{m,1}=num2str(temp(m));
        end
        val{n}=[];
        val{n}=table(temp2,'VariableNames',temp_name);

        clear temp_name temp temp2
    end
    
    count_val(n)=numel(val{n});

    edit_table.('Column_Names'){n}=val{n}.Properties.VariableNames{:};
    edit_table(n,2:end)={''};
    if count_val(n) == notebook_size(1)
        edit_table.('1'){n}='all entries are unique';
    elseif (count_val(n) < (notebook_size(1))) && (count_val(n) > max_Uniques)
        edit_table.('1'){n}=sprintf('%d of %d entries are unique',count_val(n),notebook_size(1));
    else
        for m=1:count_val(n)
            edit_table.(num2str(m))(n)=val{n}{m,1};
        end
    end
end

%Get 3 New Columns
edit_table=addvars(edit_table,repmat({''},notebook_size(2),1),'Before',1);
edit_table=addvars(edit_table,repmat({''},notebook_size(2),1),'Before',1);
edit_table=addvars(edit_table,repmat({''},notebook_size(2),1),'Before',1);

%And Call them something Useful
edit_table = renamevars(edit_table,1:3,["DROP?","INCLUDE","EXCLUDE"]);

edit_table.Properties.RowNames=strsplit(num2str(1:height(edit_table)))';

notebook_info.val=val;
notebook_info.idx=idx;
notebook_info.count_val=count_val;
notebook_info.edit_table=edit_table;
notebook_info.original_table=cloud_notebook;
end