function [Note,algorithm_Output] = james_to_study_inDataFrameEntry(input_doc)

if istable(input_doc)
    dataFrame=input_doc;
else
    dataFrame=civm_read_table(input_doc);
end

dataFrame_names = dataFrame.Properties.VariableNames;
show_col_viable = true;
column_statistic_viablity=cell(2,width(dataFrame));

for n=1:numel(dataFrame_names)
    viable=true;
    col=dataFrame_names{n};
    % get vals and counts for unique elements of column
    A=dataFrame.(col);
    if ~iscell(A)
        A=num2cell(A);
        A=cellfun(@num2str,A,'UniformOutput',false);
    end
    [C,ia,ic] = unique(A);
    A=sort(ic);B=sort(unique(ic));
    out = [B,histc(A,B)];
    vals=C(out(:,1));
    empty_field=cellfun(@isempty,vals);
    empty_field=find(empty_field);
    if empty_field
        out(empty_field,:)=[];
        vals=C(out(:,1));
    end
    info=num2cell(out(:,2));
    % first dumb test of viability is are there at least 4 entries for
    % most every thing(in this context 75% of things have at least 4
    % entries)
    N_gt4=nnz(out(:,2)>=4);
    if N_gt4 < 0.5*numel(vals)
        viable=false;
    end
    % Second dumb check, we cant have too many entries in total. 
    % This ... probably min = 2, max = 6
    % NOTE: this would mark columns in several studies in progress
    % NON-viable WHICH WE WANT to try-hard on! (18.gaj, 20.5xfad)
    if numel(vals) < 2 || 100 < numel(vals) 
        viable=false;
    end
    if ~viable
        column_statistic_viablity(:,n)={col,viable};
    else
        for i_u=1:numel(info)
            info{i_u}=sprintf('"%s" N(%i)',vals{i_u},info{i_u});
        end
        column_statistic_viablity(:,n)={col,info'};
    end
end

%% Creating the text to populate
algorithm_Output=table;

if show_col_viable
    Note=sprintf('Indicate which "Column_Names" belong to "GROUP" and "SUBGROUP" on left.\nGroup are the main effects of the system you are studying. Subgroup are things we should control for in the study.\n Indicate the relative importance of  "GROUP" and SUBGROUP" with numbers 1...N.\n\n\nThese are the columns James thinks you could study.');
    for n=1:numel(dataFrame_names)
        col=column_statistic_viablity{1,n};
        info=column_statistic_viablity{2,n};
        if iscell(info)
            for m=1:numel(info)
                algorithm_Output.(col){m}=info{1,m};
            end
        end
    end
end

end