function [] = create_rectangular_hit_map(color_lookup_paths,color_lookup_name,ontology_ordering)
% color_lookup_paths: is the path to the lookup file in the exact order you
% want them in along the x axis. 
% color_lookup_name: is a name you want represented for the data along on
% the x axis.
% ontology_ordering: is a single file ordering you want for the y axis of the data. If
% you are to filter the lookup data you will remove regions from the
% ontology ordering. THAT SHOULD BE DONE BEFORE IT PASSES INTO HERE.

if ~istable(ontology_ordering)
    ontology_ordering=civm_read_table(ontology_ordering);
end
for n=1:numel(color_lookup_paths)
    data{n}=civm_read_table(color_lookup_paths{n});
    
    %Confirm uniform size of datasets here

    bilat_data{n}=data(data{n}.hemisphere_assignment==0,:);

    data{n}.Structure
end


plot_hit_map(bilat_data,color_lookup_name,ontology_ordering);
save_hit_map();

% This should basically work off off the ontology stuff. use the ontology
% and slice generator to make the
end

function [] = plot_hit_map(data,x_delineation,y_delineation)
height_entry_prior_graph_inches=10.4895833333333/157;

f=figure;
set(gca,'FontSize',4,'FontName','Arial');
set(gcf,'Units','inches','InnerPosition',[0 0 1.25*2 height_entry_prior_graph_inches*numel(y_delineation)]);
set(gca, 'TickDir','out');

hold on

for x_axis=numel(x_delineation)
    %go through all columns

    % got through all rows
end

for y_axis=1:numel(y_delineation)
    y_delineation.

    for x_axis=1:numel(x_delineation)
        combined_x_idx=x_idx(x_ordered_idx(x_axis));
        data_to_place=data{x_axis}()
        try
            if ~isempty(data_to_place)
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
