function success=write_effect_dist_htm(out_htm, headings, summary_graph, effects)

%   html_conf=files.html_out(htm{3})

%{
    echo "<h3>$heading</h3>" > "$out";
    echo "<h4>$metric $param</h4>" >> "$out";

    echo '<img'; 
    echo "  src=\"$img\"";
    echo "  role=\"img\"";
    echo "  width=\"$slice_width%\"";
    echo "  height=\"$slice_height%\"";
    echo "  alt=\"${n//_/ }\"";
    echo "  caption=\"${n//_/ }\"";
    echo "  title=\"${n//_/ }\"";
    echo "  style=\"vertical-align: center\"";
    echo "/>"; 

    let "slice_width=80/$slice_count";
    img_tag_print "$colorbar_svg" 15 >> "$out";
%}

indent='  ';
indent_level=0;

fid=fopen(out_htm,'w');
%C__=cell(0); C__{end+1}={onCleanup(@(fid) fclose(fid))};

fprintf(fid,'<!DOCTYPE html>\n');
fprintf(fid,'%s<html>\n', repmat(indent,[1,indent_level]));
fprintf(fid,'%s<head>\n', repmat(indent,[1,indent_level]));
%indent_level=indent_level+1;
fprintf(fid,'%s<style>\n', repmat(indent,[1,indent_level]));

%% grid style
fprintf(fid,'.effect_grid {\n');
fprintf(fid,'  display: grid;\n');
fprintf(fid,'  grid-template-columns: repeat(3, 1fr);\n');
fprintf(fid,'  gap: 0;\n');
fprintf(fid,'  align-items: stretch;\n');
fprintf(fid,'}\n');

%% graph title
fprintf(fid,'.figure_title {\n');
fprintf(fid,'  font-weight: bold;\n');
fprintf(fid,'  width: 70%%;\n');
fprintf(fid,'  margin: 0 0 0;\n');
fprintf(fid,'  display: flex;\n');
fprintf(fid,'  text-align: center;\n');
fprintf(fid,'  align-items: flex-end; /* push text to bottom */\n');
fprintf(fid,'  justify-content: center;\n');
fprintf(fid,'}\n');

%% graph area
fprintf(fid,'.summary_graph {\n');
% fprintf(fid,'  width: auto;   /* or whatever size you want */\n');
% fprintf(fid,'  height: 50%%;\n');
fprintf(fid,'  width: min(50vw, 70vw);\n');
fprintf(fid,'  height: auto;\n');
fprintf(fid,'}\n');

fprintf(fid,'.effect_graph {\n');
fprintf(fid,'  border: 1px solid #bbb;\n');
fprintf(fid,'  padding: 0;\n');
fprintf(fid,'  display: flex;\n');
fprintf(fid,'  justify-content: center;\n');
fprintf(fid,'}\n');

fprintf(fid,'.effect_grid img {\n');
fprintf(fid,'  width: min(18vw, 25vw);\n');
fprintf(fid,'  height: auto;\n');
fprintf(fid,'}\n');

%% figure styling
fprintf(fid,'figure {\n');
fprintf(fid,'  margin: 0;\n');
fprintf(fid,'  gap: 0;\n');
fprintf(fid,'  width: 100%%;\n');
fprintf(fid,'  align-items: center;\n');
fprintf(fid,'  display: flex;\n');
fprintf(fid,'  flex-direction: column;\n');
fprintf(fid,'}\n');

%% style end
fprintf(fid,'%s</style>\n', repmat(indent,[1,indent_level]));
%indent_level=indent_level-1;
fprintf(fid,'%s</head>\n', repmat(indent,[1,indent_level]));
%% body open
fprintf(fid,'%s<body>\n', repmat(indent,[1,indent_level]));
for h_tag=fieldnames(headings)'
    h_tag=uncell(h_tag);
    fprintf(fid, '%s<%s>%s</%s>\n', repmat(indent,[1,indent_level]), ...
        h_tag, headings.(h_tag), h_tag);
end

efect_ids=fieldnames(effects);
img_colums=3;
img_rows=2;
img_width=round(80/img_colums);
% idk...

%img_height=90/img_rows;

%% convert slice-path to relative
graph=relative_path(summary_graph, fileparts(out_htm));

%% write img tag
[~,svg_name]=fileparts(graph);
n=strrep(svg_name,'_',' ');

% 'width', sprintf('%i%%', 2*img_width), ...
attrib=struct( ...
    'src', graph, ...
    'alt', n, ...
    'caption', n, ...
    'role', n, ...
    'title', n ...
    );
%{
write_tag(fid, repmat(indent,[1,indent_level]), 'img', attrib)
%}
div_figure(fid, indent, indent_level, 'summary_graph', 'figure_title', n, attrib);

% open div for graph grid
fprintf(fid, '%s<div class="effect_grid">\n', repmat(indent,[1,indent_level]));
indent_level=indent_level+1;
for img_idx=1:numel(efect_ids)
    img_id=efect_ids{img_idx};

    %% convert slice-path to relative
    slice=relative_path(effects.(img_id), fileparts(out_htm));
    
    %% write img tag
    [~,svg_name]=fileparts(slice);
    n=strrep(svg_name,'_',' ');
    % 'height', sprintf('%i%%', img_height), ...
    % 'width', sprintf('%i%%', img_width), ...
    attrib=struct( ...
        'src', slice, ...
        'alt', n, ...
        'caption', n, ...
        'role', n, ...
        'title', n, ...
        'style', 'vertical-align: center' ...
        );

%{
    attrib=struct( ...
        'src', slice, ...
        'alt', n, ...
        'caption', n, ...
        'role', n, ...
        'title', n, ...
        'class', 'effect_graph' ...
        );
%}

    %{
    fprintf(fid, '%s<div class="effect_graph">\n', repmat(indent,[1,indent_level]));
    indent_level=indent_level+1;
    fprintf(fid, '%s<figure>\n', repmat(indent,[1,indent_level]));
    indent_level=indent_level+1;
    fprintf(fid, '%s<figcaption class="effect_title">%s</figcaption>\n', repmat(indent,[1,indent_level]), n);
    write_tag(fid, repmat(indent,[1,indent_level]), 'img', attrib);
    indent_level=indent_level-1;
    fprintf(fid, '%s</figure>\n', repmat(indent,[1,indent_level]));
    indent_level=indent_level-1;
    fprintf(fid, '%s</div>\n', repmat(indent,[1,indent_level]));
    indent_level=indent_level-1;
    %}
    div_figure(fid, indent, indent_level, 'effect_graph', 'figure_title', n, attrib);
end

% close graph grid
fprintf(fid, '%s</div>\n', repmat(indent,[1,indent_level]));
indent_level=indent_level-1;

fprintf(fid,'</body>\n');
fprintf(fid,'</html>\n');
fclose(fid);

end
function div_figure(fid, indent, indent_level, div_class, title_class, title, attrib)

fprintf(fid, '%s<div class="%s">\n', repmat(indent,[1,indent_level]), div_class);
indent_level=indent_level+1;

fprintf(fid, '%s<figure>\n', repmat(indent,[1,indent_level]));
indent_level=indent_level+1;

fprintf(fid, '%s<figcaption class="%s">%s</figcaption>\n', repmat(indent,[1,indent_level]), title_class, title);
write_tag(fid, repmat(indent,[1,indent_level]), 'img', attrib);

indent_level=indent_level-1;
fprintf(fid, '%s</figure>\n', repmat(indent,[1,indent_level]));

indent_level=indent_level-1;
fprintf(fid, '%s</div>\n', repmat(indent,[1,indent_level]));

end
