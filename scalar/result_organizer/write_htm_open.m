function write_htm_open(fid, head)
%{
<!DOCTYPE html>
<html>
<head>
<style>
body {background-color: powderblue;}
h1   {color: blue;}
p    {color: red;}
</style>
</head>
<body>

</body>
</html>
%}
% cleaner=cell(0);
fprintf(fid,'<!DOCTYPE html>\n');
fprintf(fid,'<html>\n');
fprintf(fid,'<head>\n');
fprintf(fid,'<style>\n');
fprintf(fid,'.effect_graph {\n');
% fprintf(fid,'  background-color: tomato;\n');
%fprintf(fid,'  color: white;\n');
fprintf(fid,'  border: 2px solid black;\n');
%fprintf(fid,'  margin: 20px;\n');
%fprintf(fid,'  padding: 20px;\n');
fprintf(fid,'}\n');
fprintf(fid,'</style>\n');
fprintf(fid,'</head>\n');
% this probably wont work
% cleaner{end+1} = onCleanup(@() fprintf(fid,'</body>\n'));
% cleaner{end+1} = onCleanup(@() fprintf(fid,'</html>\n'));

% fprintf(fid,'<head>\n');