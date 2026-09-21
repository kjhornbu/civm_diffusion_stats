function write_slice_htm(out_htm, headings, slices, colorbar)

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

fid=fopen(out_htm,'w');
%C__=cell(0); C__{end+1}={onCleanup(@(fid) fclose(fid))};

% TODO: write style?
for h_tag=fieldnames(headings)'
    h_tag=uncell(h_tag);
    fprintf(fid, '<%s>%s</%s>\n', h_tag, headings.(h_tag), h_tag);
end
slice_ids=fieldnames(slices);
indent='';
slice_width=80/numel(slice_ids);
for img_idx=1:numel(slice_ids)
    %img_pos=uncell(img_pos);

    img_pos=slice_ids{img_idx};

    %% convert slice-path to relative
    slice=relative_path(slices.(img_pos), fileparts(out_htm));
    
    %% write img tag
%{
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
%}
    
    [~,svg_name]=fileparts(slice);
    n=strrep(svg_name,'_',' ');
    attrib=struct( ...
        'src', slice, ...
        'alt', n, ...
        'caption', n, ...
        'role', n, ...
        'title', n, ...
        'width', sprintf('%i%%', slice_width), ...
        'height', sprintf('%i%%', 75), ...
        'style', 'vertical-align: center' ...
        );

    write_tag(fid, indent, 'img', attrib)
    
end

rel_bar=relative_path(colorbar, fileparts(out_htm));

[~,svg_name]=fileparts(rel_bar);
n=strrep(svg_name,'_',' ');
attrib=struct( ...
    'src', rel_bar, ...
    'alt', n, ...
    'caption', n, ...
    'role', n, ...
    'title', n, ...
    'width', sprintf('%i%%', 15), ...
    'height', sprintf('%i%%', 58), ...
    'style', 'vertical-align: center' ...
    );

write_tag(fid, indent, 'img', attrib)
fclose(fid);

end