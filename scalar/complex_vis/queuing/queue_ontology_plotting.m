function queue_ontology_plotting(plot_queue,ontology_paths,selected_parents,slice_lut_out)
for i_parent = 1:numel(selected_parents)

    ontology_path=ontology_paths{i_parent};

    onto_plot=@(ontology,lut) ontology_plotting(ontology,selected_parents{i_parent},lut,ontology_path.base_path);

    LUT=civm_read_table(slice_lut_out,[],[],true);
    ONTOLOGY=civm_read_table(ontology_path.tbl,[],[],true);

    queueStruct.command=@() onto_plot(ONTOLOGY,LUT);
    queueStruct.infiles={ontology_path.tbl};
    queueStruct.outfiles={ontology_path.svg};

    plot_queue(ontology_path.svg)=queueStruct;

end
end