function [composite_out] = prepare_composite(C_contrast_dir,data_identity)

figure_type='ontology_composite';
composite_ol_dir=fullfile(C_contrast_dir{:});
C_ontoslice_name=[data_identity,figure_type];
composite_out=path_convert_platform(fullfile(composite_ol_dir,'svg',[ strjoin(C_ontoslice_name,'_') '.svg' ]),'native');

end