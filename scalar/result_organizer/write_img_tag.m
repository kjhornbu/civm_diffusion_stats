function write_img_tag(fid, indent, file, width, height, style)
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
fprintf(fid,'%s<img\n', indent);
fprintf(fid,'%s  src=""\n', indent, file);
fprintf(fid,'%s/>\n');

