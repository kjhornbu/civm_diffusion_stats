function stat_colors = lookup_cohen(type)
% returns one of two types of pvalue lookup.
% either 2-gray values, or 6. In both cases uses 4 green levels to indicate
% significance.
if ~exist('type','var')
    type='singleside_cohen';
end


color_range=[0 0.1 0.25 0.4 0.8 1.6 20];
color_bounds=[color_range(1:end-1); color_range(2:end)];

%Shades of Green
colors = [119 172 48; 144 187 86; 169 203 125;195 218 164; 221 234 203; 211 211 211];

% Adjustments: this makes the first 4 more distinct, and makes the
% final green a gray. We could move this to its own type to preseve
% the original behavior
colors(2,:)=mean(colors(2:3,:));
colors(3,:)=mean(colors(3:4,:));
colors(4,:)=mean(colors(4:5,:));
colors(5,:)=[186,186,186];
colors(6,:)=colors(5,:)+14;

colors=flipud(colors);

color_names={'No Effect'; 'Small'; 'Medium'; 'Large1'; 'Large2';'Large3'};

stat_colors=lookup_colors_apply_values(colors,color_range,color_names);
end