function lookup_plot(stat_colors,varargin)
% Given an input colors table(or structure), plot and optionally save
% NOTE: table not functional yet.
% This function might be better named as "LUT_plot", as it does NOT plot a
% 3D slicer "lookup.txt".

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
end

params=struct();
params.font='Arial';
if strcmp(hostname,'blackbox')
   params.font='Liberation Sans'; 
else
   warning('plotting font could be a problem. You should check output SVG at least the first time and update this code accordingly.');
end

p = inputParser;

% === Positional arguments ===
%addRequired(p, 'desired_steps', @(x) isscalar(x) && isnumeric(x) && x >= 0 && x <= 255 && mod(x,1)==0);
%addOptional(p, 'neutrals', 0,  @(x) isscalar(x) && ismember(x, [0, 1, 2]));

% Add parameters
addParameter(p, 'proportional', true, @(x) islogical(x) && isscalar(x));
addParameter(p, 'use_names', false, @(x) islogical(x) && isscalar(x));
addParameter(p, 'fig_n', 999, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'direction', 'vertical', @(x) ( ischar(x) || isstring(x) ) && reg_match(x,'vertical|horizontal') );
addParameter(p, 'font', params.font, @validate_text);
addParameter(p, 'out_height', 15, @(x) isnumeric(x) && numel(x)==1 );

% Parse input
parse(p, varargin{:});
clear params;
params=p.Results; 

assert(~strcmp(params.direction,'horizontal'),'Horizontal mode not implemented. Please implement, or stop requesting it.');

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

if isstruct(stat_colors)
    color_bounds=[ [stat_colors.bin_start]; [stat_colors.bin_stop] ];
    color_range=sort(unique(color_bounds(:)));
end
 
% if flag to plot proportional is off, color_bounds
if ~params.proportional
    idx_vals=1:numel(color_range);
    color_bounds=[idx_vals(1:end-1); idx_vals(2:end)];
end

% close previous fig
figure_close(params.fig_n)
% start new fig
fig_colormap=figure(params.fig_n);
% fancy run at function end to close the figure
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
            %C___{end+1}=onCleanup(@() delete(out.png) );
        end
    end
    % IF we wish to skip existing
    if exist(out.pdf,'file') && exist(out.svg,'file') && exist(out.png,'file')
        return;
    end
end


% formerly set arial.
set(gca,'FontSize',8,'FontName',params.font);
% Why'd we set this to 15 inches tall? This is making the font uselessly
% small when we try to scale up/around?
% can we adjust that to be "good"?
p_pos=[0 0 2 15];
i_pos=[0 1 2 10.4895833333333];

% we're dividing because we have such a struggle with size seting, and
% p_pos+i_pos were already painstakingly configured.
% for 1.5 inch, divide by 10
desired_out=params.out_height;
div=p_pos(4)/desired_out;
p_pos=p_pos./div;
i_pos=i_pos./div;

x_off=0.25;
y_off=0.5;
p_pos(1:2)=p_pos(1:2)+[x_off,y_off];
i_pos(1:2)=i_pos(1:2)+[x_off,y_off];
% Do i have to add offsets to both y and x stop to get same behavior?
% kinda doesnt seem like it.
%p_pos(3:4)=p_pos(3:4)+[x_off,y_off];
%i_pos(3:4)=i_pos(3:4)+[x_off,y_off];

set(gcf,'PaperUnits', 'inches','PaperPosition',p_pos,'Units','inches','InnerPosition',i_pos);
hold on

for n=1:numel(stat_colors)
    %{
    if add_neutral==0
        rectangle('Position',[0 n 1 1],...
            'FaceColor',[colors(n).r,colors(n).g,colors(n).b],...
            'EdgeColor',[colors(n).r,colors(n).g,colors(n).b]);
    else
    %}
    p_x=0;
    p_y=color_bounds(1,n);
    w_x=1;
    w_y=color_bounds(2,n)-color_bounds(1,n);
    clr=[stat_colors(n).r, stat_colors(n).g, stat_colors(n).b] / 255;
    rectangle('Position', [ p_x, p_y, w_x, w_y ],...
        'FaceColor', clr, 'EdgeColor', clr);
    %end
end
% this fixes display range and is required when non-round min and max of range.
axis([ 0 1 color_bounds(1,1) color_bounds(2,end)]);

%{
if add_neutral==0
    axis([0 1 size(color_range)])
end
%}
xticks(linspace(0,1,2));
xticklabels(repmat('',2,1));

% relable for unscaled
if params.proportional
    yticks(color_range);
else
    %yticks(linspace(1,size(color_range,2),size(color_range,2)))
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

hold off;

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

