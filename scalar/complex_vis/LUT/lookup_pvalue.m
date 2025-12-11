function stat_colors = lookup_pvalue(type)
% returns one of two types of pvalue lookup.
% either 2-gray values, or 6. In both cases uses 4 green levels to indicate
% significance.
if ~exist('type','var')
    type='pvalue';
end


%Colors to apply
%         Color = [119 172 48; 153 193 100; 187 214 152; 221 234 203; 211 211 211];
%color_bounds=[0 0.05 0.1 0.2 0.5;0.05 0.1 0.2 0.5 1];
%color_range=[0 0.05 0.1 0.2 0.5 1];
%
%         color_bounds=[0 0.0001 0.001 0.01 0.05;0.0001 0.001 0.01 0.05 1];
%         color_range=[0 0.0001 0.001 0.01 0.05 1];

color_range=[0 0.0001 0.001 0.01 0.05 0.1 1];
color_bounds=[color_range(1:end-1); color_range(2:end)];

% first set, where 0.5-0.1 was a very faded green.
colors = [119 172 48; 144 187 86; 169 203 125;195 218 164; 221 234 203; 211 211 211];
gray_count=1;

% Adjustments: this makes the first 4 more distinct, and makes the
% final green a gray. We could move this to its own type to preseve
% the original behavior
colors(2,:)=mean(colors(2:3,:));
colors(3,:)=mean(colors(3:4,:));
colors(4,:)=mean(colors(4:5,:));
colors(5,:)=[186,186,186];
colors(6,:)=colors(5,:)+14;
gray_count=2;

if strcmp(type,'pvalue_extended')
    % extend our pvalue color scheme to add some more gray values
    gray1=colors(6,:);
    g_inc=8;
    ext_range=[0.2,0.3,0.4,0.5,1];
    added_grays=numel(ext_range)-1;
    ext_color=0:added_grays;
    ext_color=g_inc*ext_color;
    ext_color=[ext_color;ext_color;ext_color]'+gray1;

    color_range(end:end+added_grays)=ext_range;
    colors(end:end+added_grays,:)=ext_color;
    gray_count=gray_count+added_grays;
end

gray_names=list2cell( sprintf('gray%i ',1:gray_count )  )';
color_names=['****'; '***'; '**'; '*'; gray_names];

%color_bounds=[color_range(1:end-1); color_range(2:end)];
stat_colors=lookup_colors_apply_values(colors,color_range,color_names);
