function queue_compositing(composite_queue, composite_out,select_ontology_paths,select_slice_paths)

py_env=path_convert_platform(fullfile(getenv('WORKSTATION_AUX'),'py_env_svg_stack'),'native');
assert(exist(py_env,'dir'),'python setup not complete, need %s',py_env);
complex_code_dir=fileparts(which('ontology_and_slice_generator'));
assert(exist(complex_code_dir,'dir'),'Failed to find complex code dir, this is required to use the composite code');

os_specific_quote=char("'");
if ispc
    os_specific_quote='"';
end

reshaped_slice_paths=vertcat(select_slice_paths{:});
reshaped_ontology_paths=vertcat(select_ontology_paths{:});

py_file=path_convert_platform(fullfile(complex_code_dir,'Python_Support','composite_ontology_w_slice.py'),'native');
py_cmd=[ py_env 'python' py_file {reshaped_ontology_paths.svg} {reshaped_slice_paths.svg} '-o' composite_out ];
py_cmd=sprintf([os_specific_quote '%s' os_specific_quote ' '],py_cmd{:});
cmd=sprintf('conda run -p %s',py_cmd);

queueStruct.command=cmd;
queueStruct.infiles={reshaped_ontology_paths.svg,reshaped_slice_paths.svg};
queueStruct.outfiles={composite_out};

composite_queue(composite_out)=queueStruct;

end
