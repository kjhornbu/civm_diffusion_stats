function ontology_plotting(layout_table,parent_regex,color_LUT,filename)

font='FixedWidth';

if strcmp(hostname,'blackbox')
   font='Liberation Mono'; 
else
   warning('ontology_plotting font is supposed to be fixed width. You should check the ontology fonts in the SVG at least the first time and update this code accordingly.');
end

%% 

% out.pdf is the 'true' output of the function right now, using inkscape to
% convert to both svg and png. svg is a required and expected output
[p,n,~]=fileparts(filename);
[out]=figure_out_struct(path_convert_platform(fullfile(p,n),'native'));

% IF we wish to skip existing
if exist(out.pdf,'file') && exist(out.svg,'file') && exist(out.png,'file')
    return;
end

%% Ontology Offset && keep in fig
% What region becomes the new parent
parent_table=layout_table( row_find(layout_table,'GN_Symbol',parent_regex), :);
if height(parent_table)==1
    layout_table.keep_in_figure = layout_table.ontology_order_ROI(:,parent_table.ontology_level+1) == parent_table.ROI;

    layout_table.ontology_level = layout_table.ontology_level - (parent_table.ontology_level+1);
    layout_table.start_of_bar = layout_table.start_of_bar - parent_table.start_of_bar;
else
    assert( numel(unique(parent_table.ontology_level))==1, ...
        'All Main Parents described for within a single figure must be on same ontology level.')
    c=ismember(layout_table.ontology_order_ROI,parent_table.ROI);
    child=sum(c,2);
    parents=ismember(layout_table.ROI,parent_table.ROI);
    layout_table.keep_in_figure = parents|child;

    [~,smallParentIdx]=min(parent_table.start_of_bar);
    layout_table.ontology_level=layout_table.ontology_level-(parent_table.ontology_level(smallParentIdx));
    layout_table.start_of_bar=layout_table.start_of_bar-(parent_table.start_of_bar(smallParentIdx));

end
%% set used_levels, fig height and width in region-unit (1-region == 1 unit)
[all_levels,~,~]=unique(layout_table.ontology_level);
positive_levels = all_levels( 0 <= all_levels );
used_levels=positive_levels;
deepest_used_level=max(positive_levels);

%Cannonical Atlas # Most Child regions -- needed with the chopped structure
Num_Most_Child=157;
%Cannonical Atlas # of Levels-- needed with the chopped structure
Num_All_Levels=10;
fig_height=sum(and(layout_table.ontology_most_child,layout_table.keep_in_figure));
height_ratio=fig_height/Num_Most_Child;
width_ratio=numel(positive_levels)/Num_All_Levels;
fig_width=numel(positive_levels);

% adjust for deepest used. 
% This block needs to be commented or made optional if we want constant width output
deepest_used_level=max(layout_table.ontology_level(layout_table.keep_in_figure));
used_levels=min(positive_levels):deepest_used_level;
fig_width=numel(used_levels);
width_ratio=fig_width/Num_All_Levels;

%% init figure
% this caps the maximal display at 15 becuase of limitations  in windows,
% and then we scale down from there based on how much we'll be printing.
max_height=15;
max_inner_height=10.4895833333333;
% these just set where on the users screen the figure will show up, these
% mark the bottom left corner.
left_margin=0.25;
bottom_margin=0.25;
% Tried to use the unit height to force reasonable scaling on save via
% exportgraphics, however that didn't work.
% I think the real repair of the error was having the left/bottom be in the
% printable area of the screen.
%expected_unit_height=max_inner_height/Num_Most_Child;
%expected_unit_width=2/Num_All_Levels;
%end_height=fig_height*expected_unit_height;
%end_width=fig_width*expected_unit_width;
figH=figure;
% fancy run at function end to close the figure
C___={};C___{end+1}=onCleanup(@() figure_close(figH) );

set(gca,'FontSize',fig_width,'FontName','Arial');
set(figH, ...
    'PaperUnits', 'inches', 'PaperPosition', [0 0 2*width_ratio max_height*height_ratio],...
    'Units',      'inches', 'InnerPosition', [ left_margin bottom_margin+max_height*height_ratio 2*width_ratio max_inner_height*height_ratio ] );
hold on;
axis( [ min(used_levels) fig_width 0 fig_height ]);

%% loop over each level, levels populate from the back to the front(bottom to top of figure).
for level=used_levels(:)'
    if deepest_used_level < level 
        keyboard;
    end
    % background white prior to alignment
    rectangle('Position',[ level 0 1 fig_height ],'FaceColor',[1 1 1],'EdgeColor',[1 1 1]);
    
    % numeric indicies for all entries on the current level
    idx_entries_in_level=find( and( layout_table.keep_in_figure, layout_table.ontology_level==level ) );

    for idx_e = idx_entries_in_level(:)'
        if ~isempty( layout_table.GN_Symbol{idx_e} )
            entry_text=regexprep(layout_table.GN_Symbol{idx_e},{'-B','-L','-R'},'');
        else
            %If we have a hole because the regions is not defined by a
            %GN symbol shift to ARA abbrev -- No making 3 dashes is
            %good
            entry_text='---';
        end
    
        lut_row=row_find(color_LUT,'GN_Symbol',layout_table.GN_Symbol(idx_e));
        if ~isempty(lut_row)
            entry_color = [ color_LUT.c_r(lut_row), color_LUT.c_g(lut_row), color_LUT.c_b(lut_row), color_LUT.c_a(lut_row) ];
            entry_color = entry_color / 255;
        else
            entry_color=[1 1 1 1];
        end

        entry_start=layout_table.start_of_bar(idx_e);
        entry_length=layout_table.length_of_bar(idx_e);
        rectangle('Position', [ level entry_start 1 entry_length], 'FaceColor', entry_color,'EdgeColor',[1 1 1]);
        text(level+0.5, entry_start+entry_length/2, entry_text, 'HorizontalAlignment','center','FontSize',5,'FontName', font)
    end
end
xticks(linspace(0,numel(used_levels),2));
xticklabels(repmat('',2,1));

yticks(0:1:fig_height)
yticklabels(repmat('',fig_height,1));

%% save
%{
% 'standard' easy prints, works every time EXCEPT you get mega margins. 
% These are just fine if the output svg will be the figure. Not so good if
% you're saving components to composite later.
print(figH, out_svg,'-dsvg','-vector'); %,'-painters
print(figH, out_png,'-dpng','-r600');
% this was tested and found to be MUCH WORSE than exportgraphics
% print(figH, out_pdf,'-dpdf','-vector');
%}

% found eps harder to work with so switched to pdf.
% IN PDF EXPORT EXTRANEOUS SPACE IS CUT OUT. 
%
% WARNING WARNIGN WARNING
% pdf uses the window presentation on screen! what you see IS what you get!
% This seems to mostly be okay, except that we MUST place the window on the
% screen when doing figure init above.
% resolution 600 has no impact with vector, BUT leaving as reminder.
% exportgraphics(figH, out_eps);
exportgraphics(figH, out.pdf,'BackgroundColor','none','ContentType','vector','Resolution',600);

%% convert saved pdf to svg and png via inkscape
warning('NOT GENERATING svg or png from pdf because inkscape hates james');
return;
cmd=sprintf('inkscape --export-filename=%s %s', out.svg, out.pdf);
[s,sout]=system(cmd);
retry=5;
% weird fails of return code. But file exists, so we'll just pretend its
% okay...
while retry > 0 && s ~= 0 && ~exist(out.svg,'file')
    [s,sout]=system(cmd);
    retry=retry-1;
end
assert(s~=0,'inkscape conversion failed with error %s\ncmd:\t%s',sout,cmd);

cmd=sprintf('inkscape --export-filename=%s --export-dpi=600 %s',out.png,out.pdf);
[s,sout]=system(cmd);
retry=5;
while retry>0 && s~=0
    [s,sout]=system(cmd);
    retry=retry-1;
end
assert(s~=0,'inkscape conversion failed with error %s\ncmd:\t%s',sout,cmd);

end

