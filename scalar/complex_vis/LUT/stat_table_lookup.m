function LUT = stat_table_lookup(data_table, column, color_table, ontology, output)
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

color_table.bin_start(1)=-inf;
color_table.bin_stop(end)=inf;

l_colors=column_find(color_table,'^[rgba]$');

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

cols_data_meta=column_find(data_table,'gn_Symbol|abbrev|hemisphere_assignment');
LUT=data_table(:,[t_colors,cols_data_meta]);

t_l=LUT;
t_l.hemisphere_assignment=repmat(-1,height(t_l),1);
t_l.GN_Symbol=strrep(t_l.GN_Symbol,'-B','-L'); %Make Left Case
t_r=LUT;
t_r.hemisphere_assignment=repmat(-1,height(t_r),1);
t_r.GN_Symbol=strrep(t_r.GN_Symbol,'-B','-R'); %Make Right Case

LUT=[t_l;t_r;LUT];
clear t_l t_r;
%LUT=join(LUT,ontology,'Keys','GN_Symbol','RightVariables',{'ROI','Structure','id_64fsABI','structure_id','parent_structure_id'});

ontology.idx_ontology=( 1:height(ontology) )';

LUT=join(LUT,ontology,'Keys','GN_Symbol','RightVariables',{'ROI','Structure','idx_ontology'});

%idx_u_rows=row_find(ontology,'Structure','uncharted');
%LUT=outerjoin(LUT,ontology(idx_u_rows,:),'Keys','GN_Symbol','RightVariables',{'ROI','Structure'});

required_cols = list2cell('ROI Structure GN_Symbol ARA_abbrev');

idx_ontology_labels = row_find(ontology,'voxel_presence','full');
cols_ontology_roi_st=column_find(ontology,sprintf('^(%s)$', strjoin(required_cols,'|') ));
ontology_sub=ontology(idx_ontology_labels,cols_ontology_roi_st);
cols_lut_roi_st=column_find(LUT, sprintf('^(%s)$', strjoin(required_cols,'|') ));
lut_sub=LUT(:,cols_lut_roi_st);
[~,idx_missing_labels]=setdiff(ontology_sub,lut_sub);

ontology_sub.idx_ontology=idx_ontology_labels;
missing_labels=ontology_sub(idx_missing_labels,:);
missing_labels.hemisphere_assignment=zeros(height(missing_labels),1);

idx_r=reg_match(missing_labels.Structure,'_right$');
idx_l=reg_match(missing_labels.Structure,'_left$');
missing_labels.hemisphere_assignment(idx_r)=1;
missing_labels.hemisphere_assignment(idx_l)=-1;

idx_offset=height(LUT);
idx_insert=idx_offset + (1:height(missing_labels));

for col_name=missing_labels.Properties.VariableNames
    n=uncell(col_name);
    LUT.(n)(idx_insert) = missing_labels.(n);
end

%% use idx_insert to find the remaining missing structures and update their color with an approprate value

l_colors=column_find(LUT,'^[rgba]$');
for idx_lut=idx_insert
    % line for teting to increment 
    %idx_lut=idx_lut+1
    
    idx_ontology=LUT.idx_ontology(idx_lut);
    ancestors = get_ancestor_rows(ontology,idx_ontology,true);
    if ~isempty(ancestors)
        % we have ancestors if a is not empty
        for idx_a=1:height(ancestors)
            idx_lut_a = find( LUT.idx_ontology == ancestors.idx_ontology(idx_a) );
            
            lut_color=LUT(idx_lut_a,l_colors);
            bad_parent_color=all(table2array(lut_color)==0);
            good_parent_color=~bad_parent_color;

            if good_parent_color
                LUT(idx_lut,l_colors)=LUT(idx_lut_a,l_colors);
                break;
            else
                continue;
            end
        end
    end
end

LUT.sep=repmat({'#'},height(LUT),1);
LUT=column_reorder(LUT,list2cell('ROI Structure r g b a sep GN_Symbol ARA_abbrev'));
LUT.Properties.VariableNames([3,4,5,6])=list2cell('c_r c_g c_b c_a');

if exist('output','var')
    civm_write_table(LUT,output,false,true,{},'quiet');
end
end
