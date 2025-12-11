function stat_table=lookup_colors_apply_values(ColorArray,color_range,color_names,out_txt)
% function stat_lookup=lookup_colors_apply_values(ColorArray,color_range,color_names,out_txt)
% given an array of colors (Nx3) and a color_range with N=1 value (these
% are the values before,between, and after all the colors, and a set of
% names(optional) return a slicer-lookup table which will presume the label
% values are 1..N colors. Optionally specify the ouptut location.



color_bounds = [color_range(1:end-1); color_range(2:end)];

% add bin start/stop so we could save a meaningful text table version.
ColorArray(:,4)=255;
ColorArray(:,5)=color_bounds(1,:);
ColorArray(:,6)=color_bounds(2,:);
stat_table=array2table(ColorArray,'VariableNames',{'r','g','b','a','bin_start','bin_stop'});
stat_table.index=(1:height(stat_table))';
if ~isempty(color_names)
    stat_table.name=color_names;
else
    stat_table.name=list2cell(sprintf('color%i ',1:height(stat_table)))';
end
stat_table.sep=repmat({'#'},[height(stat_table),1]);
stat_table=column_reorder(stat_table,{'index','name','r','g','b','a','sep'});

if exist('out_txt','var')
    desc={
        'Stat color table for use in complex visualizations. Partially compataible with 3d slicer.'
        sprintf('color_range = [%s];', cell2str(num2cell(color_range)) );
        };
    
    
    civm_write_table(stat_table,out_txt,0,1,desc,'quiet');
end

