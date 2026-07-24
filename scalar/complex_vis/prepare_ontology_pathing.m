function [ontology_path] = prepare_ontology_pathing(C_contrast_dir,selected_parents,data_identity,parent_idx)

layout_dir=path_convert_platform(fullfile(C_contrast_dir{1},'ontology_layouts'),'native');

figure_type='ontology_segment';
ontology_dir=fullfile(C_contrast_dir{:},figure_type);
if strcmp(selected_parents,'BRN-B')
    figure_type='ontology';
    ontology_dir=fullfile(C_contrast_dir{:});
end

simplified_parent_list=replace(selected_parents,{'$','(',')','^','-B','-L','-R'},'');
if any(simplified_parent_list=='|')
    simplified_parent_list=strrep(simplified_parent_list,'|','_');
end

out_dirs={ontology_dir,layout_dir};
for i_out_dir=1:numel(out_dirs)
    if ~exist(out_dirs{i_out_dir},'dir')
        mkdir(out_dirs{i_out_dir});
    end
end

ontology_path.fig_name=strjoin([data_identity figure_type parent_idx simplified_parent_list ], '_' );
ontology_path.base_path=path_convert_platform(fullfile(ontology_dir, 'svg', ontology_path.fig_name),'native');
ontology_path.tbl=path_convert_platform(fullfile(layout_dir,strcat(simplified_parent_list,'_ontology_layout.csv')),'native');
ontology_path.svg=sprintf('%s.svg',ontology_path.base_path);
end