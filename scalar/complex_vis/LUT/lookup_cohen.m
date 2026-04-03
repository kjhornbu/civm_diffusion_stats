function stat_colors = lookup_cohen(type)
% returns one of two types of pvalue lookup.
% either 2-gray values, or 6. In both cases uses 4 green levels to indicate
% significance.
if ~exist('type','var')
    type='singleside_cohen';
end


color_range=[0 0.1 0.25 0.4 0.8 1.6 20];

%Shades of Berry
%colors = [119 172 48; 144 187 86; 169 203 125;195 218 164; 221 234 203; 211 211 211];

color =[0.847058823529412	0.105882352941176	0.376470588235294;
0.877647058823529	0.236078431372549	0.306666666666667;
0.908235294117647	0.366274509803922	0.236862745098039;
0.938823529411765	0.496470588235294	0.167058823529412;
0.969411764705882	0.626666666666667	0.0972549019607843;
1	0.756862745098039	0.0274509803921569;
1	0.817647058823529	0.270588235294118;
1	0.878431372549020	0.513725490196078;
1	0.939215686274510	0.756862745098039;
1	1	1].*255;

%Shades of Green
%colors = [119 172 48; 144 187 86; 169 203 125;195 218 164; 221 234 203; 211 211 211];

% Adjustments: this makes the first 4 more distinct, and makes the
% final green a gray. We could move this to its own type to preseve
% the original behavior
colors(1,:)=mean(color(1:2,:));
colors(2,:)=mean(color(3:4,:));
colors(3,:)=mean(color(5:6,:));
colors(4,:)=mean(color(7:8,:));
% 2 grey shades
colors(5,:)=[186,186,186];
colors(6,:)=colors(5,:)+14;

colors=flipud(colors);

color_names={'No Effect'; 'Small'; 'Medium'; 'Large1'; 'Large2';'Large3'};

stat_colors=lookup_colors_apply_values(colors,color_range,color_names);
end