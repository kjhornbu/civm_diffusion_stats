function [paths] = switch_ase_file_on_counts(paths,max_ase_param_count,ase_param_count)

if max_ase_param_count < ase_param_count
    % reload
    ase=civm_read_table(paths.ase);
    [ad,an,ae]=fileparts(paths.ase);
    ase_name=sprintf('ASEx%i',max_ase_param_count);
    ase_file=fullfile(ad,strcat(strrep(an,'ASE',ase_name),ae));
    ase_cols=column_find(ase,'^X[0-9]+$');
    non_ase_cols=column_find(ase,'[^(^X[0-9]+$)]');

    ase_cols(1:(end-max_ase_param_count))=[];

    %this sets the data we want to nothing not just selecting it.
    %ase_regional(:,ase_cols)=[];

    ase_select=ase(:,[non_ase_cols ase_cols]);
    writetable(ase_select, ase_file);
    paths.ase=ase_file;
end
end