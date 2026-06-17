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

Color=color_range_find;

[x_values,~,x_idx]=unique(data.(x_delineation),'stable');
[y_values,~,y_idx]=unique(data.(y_delineation),'stable');

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

end
function[] = color_range_find()
end