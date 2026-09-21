function write_statistical_view_htm(out_htm, contrasts, out_types)

% code_path=fileparts( which('write_statistical_view_htm') );
code_path=fileparts( which( mfilename ) );
html_template=fullfile(code_path, 'statistical_viewer_with_contrast_switching.html');
assert( exist(html_template,'file'), 'missing template');

if exist(out_htm,'file')
    delete(out_htm);
end
copyfile(html_template, out_htm);

out_dir=fileparts(out_htm);
out_config=fullfile(out_dir,'.config.js');
if exist(out_config,'file')
    delete(out_config);
end

if iscell(contrasts) 
    % string is probably easier...
    contrasts=string(contrasts);
elseif isstring(contrasts)
    % contrasts=cellstr(contrasts);
end

if isstruct(out_types) 
    out_types=string(fieldnames(out_types));
elseif iscell(out_types) 
    out_types=string(out_types);
end

%% begin
lines_begin={
    '// ─── CONFIGURATION ──────────────────────────────────────────────────────────'
    '// Configuration auto-saved from matlab.'
    };
lines_base_path={
    '// Base path shared by all datasets'
    'const BASE_PATH = ".";'
    };
%% datasets
lines_datasets={
    '// All datasets listed in alphabetical order.'
    '// Each entry: { label, folder, prefix }'
    '//   folder : path segment after BASE_PATH'
    '//   prefix : the filename prefix used for all three metric files'
    'const DATASETS = ['
    };
example_lines={
    '{'
    '  label:  "ad_mean",'
    '  //experiment: "14Month_nTg-vs-5xFAD",'
    '  folder: "ad_mean",'
    '  prefix: "ad_mean"'
    '},'
    '{'
    '  label:  "volume_mm3",'
    '  //experiment: "14Month_nTg-vs-5xFAD",'
    '  folder: "volume_mm3",'
    '  prefix: "volume_mm3"'
    '},'
    };
for contrast=contrasts
    % contrast=uncell(contrast);
    lines_datasets{end+1}='{';
    lines_datasets{end+1}=sprintf('  label:  "%s",', contrast);
    % lines_datasets{end+1}=sprintf('  //experiment: "14Month_nTg-vs-5xFAD",');
    lines_datasets{end+1}=sprintf('  folder: "%s",', contrast);
    lines_datasets{end+1}=sprintf('  prefix: "%s"', contrast);
    lines_datasets{end+1}='},';
end
lines_datasets{end+1}='].sort((a, b) => a.label.localeCompare(b.label));   // keep sorted automatically';
%% metrics
ot=sprintf('"%s", ',sort(out_types));
ot(end-1:end)=[];
lines_metrics={
    '// Available metric suffixes (must match filenames: prefix_SUFFIX.htm)'
    % 'const METRICS = ["CohenD", "percent_change", "pval_BH", "CohenF"];'
    sprintf('const METRICS = [ %s ];', ot)
    };
%% end
lines_end={
    '// ─── END CONFIGURATION ──────────────────────────────────────────────────────'
    };

lines=[lines_begin; lines_base_path; {''}; lines_datasets; {''}; lines_metrics; lines_end];
fid=fopen(out_config,'w');
for line=lines'
    fprintf(fid,'%s\n', uncell(line));
end
fclose(fid);

if ispc
    fileattrib(out_config,'+h','');
end

end