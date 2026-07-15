function fig_colormap = lookup_plot_gpt1(stat_colors,varargin)
% fig_colormap = lookup_plot_gpt1(stat_colors, [ ARGS, out_struct])
% Given an input colors table(or structure), plot and optionally save
% This function might be better named as "LUT_plot", as it does NOT plot a
% 3D slicer "lookup.txt".
%
% stat_colors is a structure array of colors to plot with their start and
% stop values. Required elements are "r g b bin_start bin_stop".
% This could be a table with the required columns.
% A name column will be required if use_names == true.
%
% The out struct should have at least a pdf field, and optionally svg and
% png. If only output file is desired, out can be a single output path.
%
% ARGS are paired arguments: 
% proportional - bool, default true.
% use_names -  bool, default false.
% fig_n - integer, default 999. 
% font - default 'Arial' in windows, or 'Liberation Sans' on linux
% out_height - float, default 10, has an enforced maximum of 10.4895833 to 
%   prevent failure to render on windows. Testing for this has been very limited. 
%   It is not known if small-screens in windows will have a problem. 
% direction - default 'vertical'; alternate value is 'horizontal'
%   (unimplemented)
 
%% find the out struct
% Starting from the final optional arg, check for an out struct. 
arg_count=numel(varargin);
if arg_count
    for i_v=arg_count:-1:1
        if isstruct(varargin{i_v})
            out=varargin{i_v};
            varargin(i_v)=[];
        end
    end
end
if ~exist('out','var') && mod(arg_count,2) && ischar(varargin{end}) || isstring(varargin{end})
    out=varargin{end};
    varargin(end)=[];
elseif exist('out','var') 
    supported=list2cell('pdf png svg');
    assert( all(ismember(fieldnames(out), supported)), ...
        'Unsupported output type requested. only %s allowed.',strjoin(supported,', '));
    clear supported;
end

clear arg_count i_v;
params=struct();
params.font='Arial';
if isunix
   params.font='Liberation Sans'; 
else
   warning('plotting font could be a problem. You should check output SVG at least the first time and update this code accordingly.');
end

%% figure size settings
% Why'd we set this to 15 inches tall? This is making the font uselessly
% small when we try to scale up/around?
% can we adjust that to be "good"?
p_pos=[0 0 2 15];
i_pos=[0 1 2 10.4895833333333];
% naming these specifically so i can refer to them later. 
calibrated_width=p_pos(3);
calibrated_height=p_pos(4);

% minimum width inches for the color bar
min_plot_width=0.2;
min_plot_width=0.125;
% how much area the label axis will use
axis_area=0.275;
% blank margin on right side
right_margin=0.025;
% blank margin on bottom
bottom_margin=0.15;
% blank margin on top
top_margin=bottom_margin;

min_a_pos=min_plot_width+axis_area+right_margin;
max_div=calibrated_width/min_a_pos;
min_height=calibrated_height/max_div;

%% input parsing
p = inputParser;
addParameter(p, 'proportional', true, @(x) islogical(x) && isscalar(x));
addParameter(p, 'use_names', false, @(x) islogical(x) && isscalar(x));
addParameter(p, 'fig_n', 999, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'direction', 'vertical', @(x) ( ischar(x) || isstring(x) ) && reg_match(x,'vertical|horizontal') );
addParameter(p, 'font', params.font, @validate_text);
% This max height is the magic number 10.4895833333333 for windows.
% This was found through painstaking experimentation. 
% The min_height is found via the function above, and rounded up to a nice
% number. True min_height is 3.1875.
% addParameter(p, 'out_height', 10, @(x) isnumeric(x) && numel(x)==1 && 3.2 <= x && x <= 10.4895833333333);
% created cooler validateattributes version:
addParameter(p, 'out_height', 10, @(x) validate_floatinrange(3.2, x, 10.4895833333333));
% do parsing
parse(p, varargin{:});
% unnecessary? clear defaults
clear params;
params=p.Results; 

assert(~strcmp(params.direction,'horizontal'),'Horizontal mode not implemented. Please implement, or stop requesting it.');

%% final validation of inputs
required_fields=list2cell('r g b bin_start bin_stop');
if params.use_names
    required_fields=[required_fields, 'name'];
end
if istable(stat_colors)
    warning('Table input mode not fully tested. maybe you can evaluate that more and remove this message?');
    col_pat=sprintf('^(%s)$',strjoin(required_fields,'|') );
    assert( nnz(column_find(stat_colors,col_pat,1))==numel(required_fields),...
        'Cannot process, missing required information. need: %s ',strjoin(required_fields));
    stat_colors=table2struct(stat_colors);
end

%% get color bounds and color range from inputs
if isstruct(stat_colors)
    color_bounds=[ [stat_colors.bin_start]; [stat_colors.bin_stop] ];
    color_range=sort(unique(color_bounds(:)));
end
 
% if flag to plot proportional is off, color_bounds
if ~params.proportional
    idx_vals=1:numel(color_range);
    color_bounds=[idx_vals(1:end-1); idx_vals(2:end)];
end

%% fancy handling to sometimes close figure
% If the user set the output save location, this schedules a figure close.
% If the user didn't provide a struct, and output was a svg, this will 
% schedule deletion of the pdf output. (becuase we only have matlab save a
% pdf as its the only output which allowed real control)
if exist('out','var')
    C___={};C___{end+1}=onCleanup(@() figure_close(params.fig_n) );
    % out.pdf is the 'true' output of the function right now, using inkscape to
    % convert to both svg and png. svg is a required and expected output
    if ~isstruct(out) && ( ischar(out) || isstring(out) )
        [p,n,e]=fileparts(out);
        [out]=figure_out_struct(path_convert_platform(fullfile(p,n),'native'));
        if strcmp(e,'.svg')
            C___{end+1}=onCleanup(@() delete(out.pdf) );
            out=rmfield(out,'png');
            if exist(out.svg,'file') 
                return;
            end
        elseif strcmp(e,'.png') && exist(out.pdf,'file') 
            return;
        elseif strcmp(e,'.pdf') && exist(out.pdf,'file') 
            return;
        end
    elseif isstruct(out)
        % IF we wish to skip existing
        files_ready=cellfun(@(x) exist(x,'file'), struct2cell(out));
        if all(files_ready)
            return;
        end
        clear files_ready;
    else
        error('ruh-roh')
    end
end

%% calculate scaling
% we're dividing because we have such a struggle with size seting, and
% p_pos+i_pos were already painstakingly configured.
% for 1.5 inch, divide by 10
desired_out=params.out_height;
div=p_pos(4)/desired_out;
p_pos(3:4)=p_pos(3:4)./div;
i_pos(3:4)=i_pos(3:4)./div;

% set screen offsets
p_pos(1)=0.025;
p_pos(2)=1;

a_pos=[0,0,0,0];

a_pos(1)=axis_area;
a_pos(2)=bottom_margin;
% UNCELAR if i should use the expected interior position, or the paper
% position or the outer position of the "axis()".
%a_pos(3)=i_pos(3)-a_pos(1)-right_margin;
%a_pos(4)=i_pos(4)-2*a_pos(2);
a_pos(3)=p_pos(3)-a_pos(1)-right_margin;
a_pos(4)=p_pos(4)-a_pos(2)-top_margin;

% in theory, it is not possible to fail this assert becauase we calculate
% minimums before we parse input.
assert( min_plot_width <= a_pos(3), ...
    'unsupported height requested %g. Minimum height is: %g', desired_out, min_height);

%% figure reset
% close previous fig (if open)
figure_close(params.fig_n)
% start new fig
fig_colormap=figure(params.fig_n);

%% set axis units
axis([ 0 1 color_bounds(1,1) color_bounds(2,end)]);

%% ticks
xticks(0);
xticklabels('');
if params.proportional
    yticks(color_range);
else
    yticks(sort(unique(color_bounds)))
    yticklabels(color_range)
end
if params.use_names
    if params.proportional
        tik_val=yticks();
        tik_val=tik_val+0.5;
        yticks(tik_val)
    end
    yticklabels({stat_colors.name})
end

%% set font 
% (formerly arial).
set(gca,'FontSize',8,'FontName',params.font);

%% size figure size
ax = gca;
fig_colormap.Units = 'inches';
ax.Units = 'inches';
set(gcf,'PaperUnits', 'inches', ...
    'Position', p_pos ...
);
fig_colormap.PaperPosition(2)=1.5;
%{
%ax = axes(fig_colormap);
% If we called the "axis" function using our figure handle as input,  it 
% would create another axis on the plot, which is counter-productive.
% Thinking cleverly, this might be a method to put the numbers/symbols on
% top of the graph.
ax.Units = 'normalized';
% 25% reserved area for axis
%  5% bottom margin
% 50% plot-width
% 90% plot-height
ax.Position = [0.25 0.050 0.5 0.9];
%}
% a_pos=ax.Position;
% a_pos = ( 
%    axis_reservation
%    bottom_margin
%    plot_area_width
%    plot_area_height
% )
ax.Position = a_pos;

%% feedback on current 
%{
pos_feedback=struct('c_pos',fig_colormap.Position,...
'cp_pos',fig_colormap.PaperPosition,...
'ci_pos',fig_colormap.InnerPosition);
disp(pos_feedback);

axpos_feedback=struct('c_pos',ax.Position,...
'co_pos',ax.OuterPosition,...
'ci_pos',ax.InnerPosition);
disp(axpos_feedback);
%}
clear ax;

%% draw rectangles
hold on
for n=1:numel(stat_colors)
    p_x=0;
    p_y=color_bounds(1,n);
    w_x=1;
    w_y=color_bounds(2,n)-color_bounds(1,n);
    clr=[stat_colors(n).r, stat_colors(n).g, stat_colors(n).b] / 255;
    rectangle('Position', [ p_x, p_y, w_x, w_y ],...
        'FaceColor', clr, 'EdgeColor', clr);
end
hold off;

%% save
if exist('out','var') 
    % DERP print is not recommended!
    % ESPECIALLY for svg files!
    % In other code we're using PDF files for the direct output, and then
    % converting those to svg to maintain editable text.
    %
    % In NEWER versions of matlab we could use export graphics with svg
    % output, HOWEVER 2021b cannot do that!
    %{ 
    %% FAIL-TRY blarg
    if isfield(out,'svg') && ~exist(out.svg,'file')
        print(fig_colormap, out.svg, '-dsvg', '-vector');
        %exportgraphics(fig_colormap, out.svg, 'ContentType', 'vector');
    end
    if isfield(out,'png') && ~exist(out.png,'file')
        print(fig_colormap, out.png, '-dpng', '-r600');
        %exportgraphics(fig_colormap, out.png, 'Resolution', 600);
    end
    %}
    %% Updated Doodly doo!
    %if isfield(out,'pdf')
    exportgraphics(fig_colormap, out.pdf,'BackgroundColor','none','ContentType','vector','Resolution',600);
    %end
    if isfield(out,'svg')
        pdf2svg(out.pdf, out.svg);
    end
    if isfield(out,'png')
        pdf2png(out.pdf, out.png);
    end
end

