function [make_axis] = create_rectangular_hit_map(save_dir,color_lookup_paths,color_lookup_name,ontology_ordering,make_axis)
% color_lookup_paths: is the path to the lookup file in the exact order you
% want them in along the x axis.
% color_lookup_name: is a name you want represented for the data along on
% the x axis.
% ontology_ordering: is a single file ordering you want for the y axis of the data. If
% you are to filter the lookup data you will remove regions from the
% ontology ordering. THAT SHOULD BE DONE BEFORE IT PASSES INTO HERE.

load_ontology_individually=0;
if ~istable(ontology_ordering)
    if numel(ontology_ordering)==1
        indiv_ontology_ordering=civm_read_table(ontology_ordering);
    else
        load_ontology_individually=1;
    end
else
    indiv_ontology_ordering=ontology_ordering;
    load_ontology_individually=1;
end

if load_ontology_individually==1
    assert(numel(color_lookup_paths)==numel(ontology_ordering),'Your Individual Lookups do not match the number of your Indivdually defined Ontologies!');
end

for n=1:numel(color_lookup_paths)
    data{n}=civm_read_table(color_lookup_paths{n});

    if load_ontology_individually==1
        indiv_ontology_ordering=civm_read_table(ontology_ordering{n});
    end

    temp_data=data{n}(data{n}.hemisphere_assignment==0,:);
    temp_data.ROI=[];

    data_w_ontology=innerjoin(temp_data,indiv_ontology_ordering,'Keys',{'Structure','GN_Symbol','hemisphere_assignment','ARA_abbrev'});

    key_data{n}=sortrows(data_w_ontology,{'start_of_bar','ontology_level'});
    key_data_size(n)=height(key_data{n});
end

if numel(key_data_size)>1
    assert(nnz(key_data_size(1)==key_data_size(2:end)),'You have different sized key data -- you sure you giving the correct sheets to this function?');
end

[hit_map,data_x_labels,data_y_labels]=make_hit_map(key_data,color_lookup_name,key_data_size(1));
[make_axis]=save_hit_map(save_dir,hit_map,data_x_labels,data_y_labels,make_axis);
end

function [hit_map,data_x_labels,data_y_labels] = make_hit_map(data,x_delineation,y_delineation)
hit_map=zeros([y_delineation,numel(x_delineation),4],'single');

for y_idx=1:y_delineation
    for x_idx=1:numel(x_delineation)
        data_to_place=data{x_idx}(y_idx,:);
        hit_map(y_idx,x_idx,1)=data_to_place.c_r;
        hit_map(y_idx,x_idx,2)=data_to_place.c_g;
        hit_map(y_idx,x_idx,3)=data_to_place.c_b;
        hit_map(y_idx,x_idx,4)=data_to_place.c_a;
    end
end

data_y_labels=strrep(strrep(strrep(data{1}.GN_Symbol,{'-B'},{''}),{'-L'},{''}),{'-R'},{''});
data_x_labels=x_delineation;

end

function [make_axis]=save_hit_map(filename,hit_map,data_x_labels,data_y_labels,make_axis)
% takes one of our hit_map and saves it.
% Expects 3-D input where the 3rd dimension has 3 or 4 elements.
% When there are 4 elements the 4th is used as the alpha mask.
assert( size(hit_map,3) <= 4, 'unexpected image size, only 2-D grey or color supported. Alpha-channel allowed');
fontsize=4;
[p,n,~]=fileparts(filename);
[out]=figure_out_struct(path_convert_platform(fullfile(p,n),'native'));
height_entry_prior_graph_inches=10.4895833333333/231*height(hit_map); %fixing the max hight to 10.4896 (which is maximal size that you can have on the windows machines for some reason!)
height_entry_prior_graph_cm=height_entry_prior_graph_inches*2.54;

out_height=height_entry_prior_graph_cm*(72/96);
position_matrix = [0 0 0 0];

%Smallest non color Dim of data is 3.3 repeating inches
img_size=size(hit_map);
%img_size(2)=img_size(2);
[smallDim,smallDim_idx]=min([img_size(1),img_size(2)]);
[bigDim,bigDim_idx]=max([img_size(1),img_size(2)]);

%row column flip in imagesc so force a flip here by inverting big and small
position_matrix(smallDim_idx+2)=out_height;
position_matrix(bigDim_idx+2)=(bigDim/smallDim)*out_height;

% force largest dimension to be height cm tall
position_matrix=position_matrix/max(position_matrix)*out_height;

% move it of the bottom corner so its not obscured by doc/start bar
position_matrix(1:2)=25;

alpha_mask=[];
if 1 < size(hit_map,3)
    % have alpha chanel(we have EITHER 4 or 2 entries)
    alpha_mask=hit_map(:,:,end);
    hit_map(:,:,end)=[];
end

if size(hit_map,3) == 3 && max(reshape(hit_map(:,:,2:3),1,[]))==0
    % empty slices 2-3 due to forced convention of 4-elements per
    % co-ordinate. But we just want a greyscale.
    % Note, MAY NOT save correctly for all modes, that's on you.
    hit_map(:,:,2:3)=[];
end

selection_Number_y=numel(data_y_labels);
selection_Number_x=numel(data_x_labels);

position_matrix_in=([0 0 position_matrix(4) position_matrix(3)]/2.54); 
%% Data Figure Generate
f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',(96/72)*position_matrix_in,'InnerPosition',position_matrix_in,'PaperPositionMode', 'manual');
hold on

rectangle("Position",[0.5 (selection_Number_x)+0.5 0.5 (selection_Number_y)+0.5],"FaceColor",[1 1 1],"EdgeColor",[1 1 1])

for region=1:size(hit_map,1)
    for stratification=1:size(hit_map,2)
    rectangle('Position',[stratification-1 region-1  1 1],'FaceColor',hit_map(region,stratification,1:3)./255,'EdgeColor',[1 1 1]);
    end
end

    xticks(0);
    xticklabels("");
    yticks(0);
    yticklabels("");

axis([0 selection_Number_x 0 selection_Number_y]);
print(f, out.pdf,'-dpdf','-painters');

if make_axis
    make_axis=0;
    %% y-axis generate
    %y_line_coor=[0.15 0.2];
    offset=4/13; %4 ticks of the 13 regions
    y_line_coor=offset+[0 0.05];
    fL=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',(96/72)*position_matrix_in,'InnerPosition',position_matrix_in,'PaperPositionMode', 'manual');

    rectangle("Position",[0 0 1 (selection_Number_y)+1],"FaceColor",[1 1 1],"EdgeColor",[1 1 1])
    axis([0 1 0.5 (selection_Number_y)+0.5]);

    positioning = linspace(0,(selection_Number_y),(selection_Number_y)+1)+1;
    positioning(positioning>(selection_Number_y))=[];

    for n=1:(selection_Number_y)
        text(0,positioning(n),strcat(data_y_labels{n}),'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',fontsize,'FontName','FixedWdith');
        line(y_line_coor,[positioning(n),positioning(n)],'Color','black');
    end
    
    xticks(0);
    xticklabels("");
    yticks(0);
    yticklabels("");
    
    print(fL, fullfile(p,'Left_Axis.pdf'),'-dpdf','-painters');

    %% x-axis generate
    fb=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',(96/72)*position_matrix_in,'InnerPosition',position_matrix_in,'PaperPositionMode', 'manual');

    rectangle("Position",[0 0 (selection_Number_x)+1 1],"FaceColor",[1 1 1],"EdgeColor",[1 1 1])
    axis([0.5 (selection_Number_x)+0.5 0 1]);

    positioning = linspace(0,(selection_Number_x),(selection_Number_x)+1)+1;
    positioning(positioning>(selection_Number_x))=[];

    [x_line_coor]=match_xy_axis(position_matrix_in,y_line_coor);

    for n=1:(selection_Number_x)
        text(positioning(n),0,strcat(data_x_labels{n}),'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',fontsize,'FontName','FixedWdith','Rotation',90);
        line([positioning(n),positioning(n)],x_line_coor,'Color','black');
    end

    xticks(0);
    xticklabels("");
    yticks(0);
    yticklabels("");
    print(fb, fullfile(p,'Bottom_Axis.pdf'),'-dpdf','-painters');

end
end

function [x_line_coor]=match_xy_axis(position_matrix_in,y_line_coor)
%in row column now instead of column row. 
offset = (6/231); % we want an offset that is nominally at the length of BXDFamily name which is 6 ticks of 231. 
x_line_coor=position_matrix_in(3)*(diff(y_line_coor))/position_matrix_in(4); % WE convert the difference along x into a difference on y.
x_line_coor=[offset,offset+x_line_coor];
end