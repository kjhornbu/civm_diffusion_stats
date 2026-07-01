function [ontology_paths] = prepare_layout_tables(C_contrast_dir,selected_parents,data_identity,segmented_Statistical_Results,ontology_with_stats)

%% ontology component loop
ontology_paths=cell(size(selected_parents));

for i_parent = 1:numel(selected_parents)
    parent_idx = num2str(i_parent);
    ontology_paths{i_parent}=prepare_ontology_pathing(C_contrast_dir,selected_parents{i_parent},data_identity,parent_idx);

    base_layout=gen_ontology_ordering_table(ontology_with_stats,segmented_Statistical_Results,selected_parents{i_parent});
    complete_layout = coordinate_positioning(base_layout);

    if ~exist(ontology_paths{i_parent}.tbl,'file')
        civm_write_table(complete_layout,ontology_paths{i_parent}.tbl,false,true,{},'quiet');
    end
end

end

