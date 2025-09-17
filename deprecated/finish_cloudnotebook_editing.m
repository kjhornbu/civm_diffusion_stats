function [] = finish_cloudnotebook_editing(src,notebook_info,output_path)
%apply Regexpi Entries
has_include=~cellfun(@isempty,src.Data.("INCLUDE"));
has_exclude=~cellfun(@isempty,src.Data.("EXCLUDE"));
has_drop=~cellfun(@isempty,src.Data.("DROP?"));

keep_row=true(size(notebook_info.original_table,1),1);
keep_col=true(size(notebook_info.original_table,2),1);

for n=1:numel(has_include)
    if has_include(n)
        col_positions_logical = ~cellfun(@isempty,regexpi(notebook_info.val{n}{:,1}, src.Data.("INCLUDE"){n}));
        col_positions=find(col_positions_logical);
        logical_idx=sum(notebook_info.idx(:,n)==col_positions',2)>0;
        keep_row(~logical_idx)=false;
    end
    if has_exclude(n)
        col_positions_logical = ~cellfun(@isempty,regexpi(notebook_info.val{n}{:,1}, src.Data.("EXCLUDE"){n}));
        col_positions=find(col_positions_logical);
        logical_idx=sum(notebook_info.idx(:,n)==col_positions',2)>0;
        keep_row(logical_idx)=false;
    end
    if has_drop(n)
        if src.Data.("DROP?"){n}
            keep_col(n)=false;
        end
    end
end

output_table=notebook_info.original_table(keep_row,:);
output_table=output_table(:,keep_col);

civm_write_table(output_table,output_path);
end