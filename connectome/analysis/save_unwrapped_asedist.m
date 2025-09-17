function save_unwrapped_asedist()
db_inplace(mfilename,'UNTESTED, Literally will not work');
% ASE Distance **MIGHT** be translateable between different embeddings.
% Dist_regional is specimen X specimen X vertex
% 1-D table of distance with colums for src/dest
% idx for src, dest and vertex (where vertex is easy as its just the
% number)
dist_sz=size(Dist_regional);
graph_sz=size(graphs);
if graph_sz(1) ~= dist_sz(1) ||  dist_sz(1) ~= dist_sz(2) || dist_sz(3) ~= graph_sz(2)
    warning('Dist regional size not as expected! meaning unclear');
    keyboard;
end
[spec_idx_src, spec_idx_dest, vertex]=meshgrid( 1:dist_sz(1),1:dist_sz(2),1:dist_sz(3));
spec_idx_src=spec_idx_src(:);
spec_idx_dest=spec_idx_dest(:);
vertex=vertex(:);
warning('HARD CODED ROI TO VERTEX conversion! This should be fixed inside the code which touches the graphs as that code *SHOULD* know the vertex to roi mapping');
vertices=1:graph_sz(2);
roi=vertices(:);roi(roi>180)=roi(roi>180)-180+1000;

% for now only comping the study identified metadata due to how big
% this table can get.
dist_table=table;
dist_table.CIVM_ID=dataframe.CIVM_ID(spec_idx_src);
for i_g=1:numel(group)
    col=sprintf('group%i',i_g);
    dist_table.(col)=dataframe.(col)(spec_idx_src);
end
for i_sg=1:numel(subgroup)
    col=sprintf('subgroup%i',i_sg);
    dist_table.(col)=dataframe.(col)(spec_idx_src);
end

dist_table.dest_ID=dataframe.CIVM_ID(spec_idx_dest);
for i_g=1:numel(group)
    col=sprintf('group%i',i_g);
    dcol=sprintf('dest_%s',col);
    dist_table.(dcol)=dataframe.(col)(spec_idx_dest);
end
for i_sg=1:numel(subgroup)
    col=sprintf('subgroup%i',i_sg);
    dcol=sprintf('dest_%s',col);
    dist_table.(dcol)=dataframe.(col)(spec_idx_dest);
end
% group1 ***SHOULD*** be primary study condition!
within_idx=strcmp(dist_table.group1,dist_table.dest_group1);
dist_table.group1_variance=repmat({'between'},height(dist_table),1);
dist_table.group1_variance(within_idx)={'within'};
dist_table.vertex=vertex;
dist_table.ROI=roi(vertex);
dist_table.distance=Dist_regional(:);

out_name=sprintf('Regional_ASEDIST_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
regional_paths.asedist=out_file;
civm_write_table(dist_table,out_file);