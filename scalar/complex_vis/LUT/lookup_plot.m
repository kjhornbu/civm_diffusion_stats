function lookup_plot(stat_colors,varargin)
% Given an input colors table(or structure), plot and optionally save
% NOTE: table not functional yet.
arg_count=numel(varargin);
if arg_count
    for i_v=arg_count:-1:1
        if isstruct(varargin{i_v})
            out=varargin{i_v};
            varargin(i_v)=[];
        end
    end
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

% Parse input
parse(p, varargin{:});

params=p.Results; 


if isstruct(stat_colors)
    color_bounds=[ [stat_colors.bin_start]; [stat_colors.bin_stop] ];
    color_range=sort(unique(color_bounds(:)));
elseif istable(stat_colors)
    error('unimplemented');
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
C___={};C___{end+1}=onCleanup(@() figure_close(params.fig_n) );

set(gca,'FontSize',8,'FontName','Arial');
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 2 15],'Units','inches','InnerPosition',[0 1 2 10.4895833333333]);

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
    if isfield(out,'svg')
        print(fig_colormap, out.svg, '-dsvg', '-vector');
    end
    if isfield(out,'png')
        print(fig_colormap, out.png, '-dpng', '-r600');
    end
end

