function slicer_LUT = stat_table_lookup(data_table, column, color_table, ontology, output)
% function LUT = stat_table_lookp(stat_table, column, stat_lookup, ontology_lookup, output)
% add stat-lookup colors to stat table for given column, using ontology
% lookup to resolve missing data in stat table
%
% stat table is either path or table object
% column is either number or name
% stat lookup is either path or table. stat_lookups must have at least
%     r,g,b,a,bin_start,bin_stop
% ontology_lookup is either loaded ontology_table from slicer-loookup or
% path to it. 
% output is where to save the output civm-slicer-lookup.

if ~isnumeric(column)
    column=column_find(data_table,sprintf('^%s$',column));
end

assert(numel(column)==1,'error picking column number');

if ~istable(color_table)
    color_table=civm_read_table(color_table);
end

color_table.bin_start(1)=-inf;
color_table.bin_stop(end)=inf;

l_colors=column_find(color_table,'^[rgba]$');

%First Put a mask in the data -- if it is NaN this will stay and be a cool
%masked out area so we can put whatever color we want for that criteria.
for c='rgba'
    data_table.(c)=zeros(height(data_table),1);
end
t_colors=column_find(data_table,'^[rgba]$');

for idx_color=1:height(color_table)
    
    lt_start= color_table.bin_start(idx_color) < data_table.(column) ;
    lt_stop=data_table.(column) <= color_table.bin_stop(idx_color);
    
    idx_row=find(lt_start&lt_stop);
    data_table(idx_row,t_colors)=repmat( color_table(idx_color,l_colors) ,numel(idx_row),1);
end


% Create separate Table called slicer_LUT from the found colors
cols_data_meta=column_find(data_table,'gn_Symbol|abbrev|hemisphere_assignment');
slicer_LUT=data_table(:,[t_colors,cols_data_meta]);

t_l=slicer_LUT;
t_l.hemisphere_assignment=repmat(-1,height(t_l),1);
t_l.GN_Symbol=strrep(t_l.GN_Symbol,'-B','-L'); %Make Left Case

t_r=slicer_LUT;
t_r.hemisphere_assignment=repmat(1,height(t_r),1); %Correct to +1
t_r.GN_Symbol=strrep(t_r.GN_Symbol,'-B','-R'); %Make Right Case

% ADD Left and Right Hemisphere entries but with the same color as the
% Bilateral
slicer_LUT=[t_l;t_r;slicer_LUT];
clear t_l t_r;

%This is not really idx ontology as in the proper ordering, this is the index as in looking up in ontology
ontology.idx_ontology=( 1:height(ontology) )'; 

slicer_LUT=join(slicer_LUT,ontology,'Keys','GN_Symbol','RightVariables',{'ROI','Structure','idx_ontology'});
required_cols = list2cell('ROI Structure GN_Symbol ARA_abbrev');

% Select the cannonical atlas out of the full atlas ontology
idx_ontology_labels = row_find(ontology,'voxel_presence','full');
cols_ontology_roi_st=column_find(ontology,sprintf('^(%s)$', strjoin(required_cols,'|') ));
ontology_cannonical=ontology(idx_ontology_labels,cols_ontology_roi_st);

%see if we have everything in the slicer LUT that is in the cannonical
%atlas
cols_lut_roi_st=column_find(slicer_LUT, sprintf('^(%s)$', strjoin(required_cols,'|') ));
lut_sub=slicer_LUT(:,cols_lut_roi_st);
[~,idx_missing_labels]=setdiff(ontology_cannonical,lut_sub);

ontology_cannonical.idx_ontology=idx_ontology_labels;
missing_labels=ontology_cannonical(idx_missing_labels,:);
missing_labels.hemisphere_assignment=zeros(height(missing_labels),1);

idx_r=reg_match(missing_labels.Structure,'_right$');
idx_l=reg_match(missing_labels.Structure,'_left$');
idx_b=~(idx_l|idx_r);

missing_labels.hemisphere_assignment(idx_r)=1;
missing_labels.hemisphere_assignment(idx_l)=-1;

adjusted_missing_labels=table;
offset=height(adjusted_missing_labels);

%check that the missing structures to be added are the same across all hemispheres
%using count
required_cols = list2cell('ROI Structure GN_Symbol ARA_abbrev idx_ontology');
cols_ontology_roi_st=column_find(ontology,sprintf('^(%s)$', strjoin(required_cols,'|') ));

if (sum(idx_r)==sum(idx_l))&(sum(idx_b)~=sum(idx_l))
    [a,~,c]=unique(missing_labels.ARA_abbrev,'stable');
    for n=1:numel(a)
        temp_labels=missing_labels(c==n,:);
        if height(temp_labels)<3
            if nnz(temp_labels.ROI~=0)
                separate_name=strsplit(temp_labels.Structure{1},'_');
                if regexpi(separate_name{end-1},'^(uncharted)$')
                    idx_a=reg_match(ontology.Structure,strcat('^(',separate_name{1},')'));
                    idx_b=reg_match(ontology.Structure,separate_name{end-1});
                    all_region_idx=and(idx_a,idx_b);
                else
                    all_region_idx=reg_match(ontology.Structure,strcat('^(',separate_name{1},')'));
                end

                temp_labels=ontology(all_region_idx,cols_ontology_roi_st);
                % Do I need to repair the ROI numbers here???? 
                idx_r=reg_match(temp_labels.Structure,'_right$');
                idx_l=reg_match(temp_labels.Structure,'_left$');

                temp_labels.hemisphere_assignment=zeros(height(temp_labels),1);
                temp_labels.hemisphere_assignment(idx_r)=1;
                temp_labels.hemisphere_assignment(idx_l)=-1;
            end
            adjusted_missing_labels(offset+[1:height(temp_labels)],:)=temp_labels;
            offset=height(adjusted_missing_labels);
        end
    end
    missing_labels=adjusted_missing_labels;
end

idx_offset=height(slicer_LUT);
idx_insert=idx_offset + (1:height(missing_labels));

for col_name=missing_labels.Properties.VariableNames
    n=uncell(col_name);
    slicer_LUT.(n)(idx_insert) = missing_labels.(n);
end

%% use idx_insert to find the remaining missing structures and update their color with an approprate value

l_colors=column_find(slicer_LUT,'^[rgba]$');
for idx_lut=idx_insert
    % line for teting to increment 
    %idx_lut=idx_lut+1
    
    idx_ontology=slicer_LUT.idx_ontology(idx_lut);
    ancestors = get_ancestor_rows(ontology,idx_ontology,true);
    if ~isempty(ancestors)
        % we have ancestors if a is not empty
        for idx_a=1:height(ancestors)
            idx_lut_a = find( slicer_LUT.idx_ontology == ancestors.idx_ontology(idx_a) );
            
            lut_color=slicer_LUT(idx_lut_a,l_colors);
            bad_parent_color=all(table2array(lut_color)==0);
            good_parent_color=~bad_parent_color;

            if good_parent_color
                slicer_LUT(idx_lut,l_colors)=slicer_LUT(idx_lut_a,l_colors);
                break;
            else
                continue;
            end
        end
    end
end

slicer_LUT.sep=repmat({'#'},height(slicer_LUT),1);
slicer_LUT=column_reorder(slicer_LUT,list2cell('ROI Structure r g b a sep GN_Symbol ARA_abbrev'));
slicer_LUT.Properties.VariableNames([3,4,5,6])=list2cell('c_r c_g c_b c_a');

if exist('output','var')
    civm_write_table(slicer_LUT,output,false,true,{},'quiet');
end
end
