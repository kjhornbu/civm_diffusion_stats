function [] = create_rectangular_hit_map(save_dir,color_lookup_paths,color_lookup_name,ontology_ordering)
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

[hit_map]=make_hit_map(key_data,color_lookup_name,key_data_size(1));

filename=strjoin(color_lookup_name,'_');
save_hit_map(save_dir,uint8(hit_map),'image');

% This should basically work off off the ontology stuff. use the ontology
% and slice generator to make the
end

function [hit_map] = make_hit_map(data,x_delineation,y_delineation)

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

hit_map=flipud(hit_map);
end

function save_hit_map(filename,hit_map,mode)
% takes one of our hit_map and saves it.
% Expects 3-D input where the 3rd dimension has 3 or 4 elements.
% When there are 4 elements the 4th is used as the alpha mask.
assert( size(hit_map,3) <= 4, 'unexpected image size, only 2-D grey or color supported. Alpha-channel allowed');

[p,n,~]=fileparts(filename);
[out]=figure_out_struct(path_convert_platform(fullfile(p,n),'native'));
height_entry_prior_graph_inches=10.4895833333333/231*height(hit_map);
height_entry_prior_graph_cm=height_entry_prior_graph_inches*2.54;

out_height=height_entry_prior_graph_cm*(72/96);
position_matrix = [0 0 0 0];

%Smallest non color Dim of data is 3.3 repeating inches
slice_size=size(hit_map);
[smallDim,smallDim_idx]=min([slice_size(1),slice_size(2)]);
[bigDim,bigDim_idx]=max([slice_size(1),slice_size(2)]);

%row column flip in imagesc so force a flip here by inverting big and small
position_matrix(smallDim_idx+2)=out_height;
position_matrix(bigDim_idx+2)=(bigDim/smallDim)*out_height;

% force largest dimension to be height cm tall
position_matrix=position_matrix/max(position_matrix)*out_height;

% move it of the bottom corner so its not obscured by doc/start bar
position_matrix(1:2)=4;

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

%hit_map=permute(hit_map,[2 1 3]);
% if ~isempty(alpha_mask)
%     alpha_mask=permute(alpha_mask,[2 1 3]);
% end

if reg_match(mode,'image')
    assert( isa(hit_map,'uint8'), 'Unexpected data type for image mode, expecting color-image compatible 8-bit data.');
    % svg -> png conversion is fraught.
    % IF SVG is NOT specifed, it will NOT have height information;
    save_sliceAsImage(hit_map,out_height,out,alpha_mask);
end
if reg_match(mode,'figure')
    save_sliceAsFigure(hit_map,position_matrix,out,alpha_mask);
end
if reg_match(mode,'plot')
    save_sliceAsPlot(hit_map,position_matrix,out,alpha_mask);
end
end
