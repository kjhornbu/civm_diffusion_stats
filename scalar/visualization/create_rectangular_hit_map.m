function [] = create_rectangular_hit_map(data,x_delineation,x_order,set_x_order,y_delineation,y_order,set_y_order,hitMetric)


[x_ordered_idx] = order_axis(data,x_delineation,x_order,set_x_order);
[y_ordered_idx] = order_axis(data,y_delineation,y_order,set_y_order);
plot_hit_map(data,hitMetric,x_delineation,x_ordered_idx,y_delineation,y_ordered_idx);

end

function [axis_ordered] = order_axis(data,axis_name,order_type,set_order)

if reg_match(order_type,'alphabetical')
    [~,axis_ordered]=sortrows(data,axis_name,'ascend');
elseif reg_match(order_type,'ontological')
elseif reg_match(order_type,'set')
    [~,axis_ordered]=sortrows(data,axis_name,'ascend');

    for n=1:numel(set_order)
        axis_ordered(n)
    end

else
end



end

function [] = plot_hit_map(data,hitMetric,x_delineation,x_ordered_idx,y_delineation,y_ordered_idx)
height_entry_prior_graph_inches=10.4895833333333/157;
Color=color_range_find;

[x_values,~,x_idx]=unique(data.(x_delineation),'stable');
[y_values,~,y_idx]=unique(data.(y_delineation),'stable');

f=figure;
set(gca,'FontSize',4,'FontName','Arial');
set(gcf,'Units','inches','InnerPosition',[0 0 1.25*2 height_entry_prior_graph_inches*numel(GN_Symbol_name)]);
set(gca, 'TickDir','out');

hold on

for y_axis=1:numel(y_values)

    combined_y_idx=y_idx(y_ordered_idx(y_axis));

    for x_axis=1:numel(x_values)
        combined_x_idx=x_idx(x_ordered_idx(x_axis));
        data_to_place=data.(hitMetric)(combined_x_idx&combined_y_idx);
        try
            if ~isempty(data_to_place)
                [~,color_index]=min(abs(color_range-data_to_place));

                rectangle('Position',[contrast_value+((x_axis-1)/numel(x_values)), y_axis, 1/numel(x_values), 1],'FaceColor',Color(color_index,:)./255,'EdgeColor',[1 1 1]);
            else
                rectangle('Position',[contrast_value+((x_axis-1)/numel(x_values)), y_axis, 1/numel(x_values), 1],'FaceColor',[1 1 1],'EdgeColor',[1 1 1]);
            end
        catch
            keyboard;
        end
    end
end

for x_axis=2:numel(x_values)
    xline(x_axis,'Color',[0 0 0])
end

xticks((1:numel(x_values)+0.5));
xticklabels(x_values);

yticks((1:numel(y_values))+0.5);
yticklabels(y_values);

end
function[colorspace] = color_range_find()

color_range=linspace(-0.3,0.3,255);
color_range_small=-0.3:0.1:0.3;

%Laying out Cold Hot Color space with 255 divisions
%whiter center
Color(:,1)=linspace(26,250,128); %Cold -- R
Color2(:,1)=linspace(250,212,128); %Hot -- R

Color(:,2)=linspace(133,250,128); %Cold -- G
Color2(:,2)=linspace(250,17,128); %Hot -- G

Color(:,3)=linspace(255,250,128); %Cold -- B
Color2(:,3)=linspace(250,89,128); %Hot -- B

length_color=size(Color,1);
Color(length_color+(1:127),1)=Color2(2:end,1);
Color(length_color+(1:127),2)=Color2(2:end,2);
Color(length_color+(1:127),3)=Color2(2:end,3);

fig_colormap=figure;
set(gca,'FontSize',8,'FontName','Arial');
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 2 15],'Units','inches','InnerPosition',[0 0 2 10.4895833333333]);

hold on

for n=1:size(Color,1)
    rectangle('Position',[0 n 1 1],'FaceColor',Color(n,:)./255,'EdgeColor',Color(n,:)./255);
end

axis([0 1 1 255])

xticks(linspace(0,1,2))
xticklabels(repmat('',2,1))

yticks(linspace(1,255,size(color_range_small,2)))
yticklabels(color_range_small')

print(fig_colormap, strcat('Stratified_ColorMap.png'),'-dpng','-r600');
print(fig_colormap, strcat('Stratified_ColorMap.svg'),'-dsvg','-vector');


end