function [ontology_layout] = gen_ontology_ordered(Label_Ontology,parent_structure)
hemisphere=-1;

%Remove the actual stats we don't need from Statistical Results keep only
%the book keeping stuff
ontology_layout=table;

Data_Labels=Label_Ontology(Label_Ontology.hemisphere_assignment==hemisphere,:);
Data_Labels=Data_Labels(Data_Labels.ROI<=180,:);

ontology_layout.ROI=Data_Labels.ROI;
ontology_layout.Structure=Data_Labels.Structure;
ontology_layout.hemisphere_assignment=Data_Labels.hemisphere_assignment;
ontology_layout.parent_structure_id=Data_Labels.parent_structure_id;
ontology_layout.structure_id=Data_Labels.structure_id;
ontology_layout.GN_Symbol=Data_Labels.GN_Symbol;
ontology_layout.ARA_abbrev=Data_Labels.ARA_abbrev;
ontology_layout.id64_fSABI=Data_Labels.id64_fSABI;
   
 
%% for each ROI figure out parentage
for ROI=1:height(ontology_layout)
    if ~isempty(ontology_layout.GN_Symbol{ROI})
        ontology_logical_idx=~cellfun(@isempty,regexpi(Label_Ontology.GN_Symbol,ontology_layout.GN_Symbol(ROI)));
        ontology_positional_idx=find(ontology_logical_idx==1);
    else
        %What to do for the uncharted regions
        ontology_logical_idx=Label_Ontology.structure_id==ontology_layout.structure_id(ROI);
        hemisphere_logical_idx=Label_Ontology.hemisphere_assignment==hemisphere;
        ontology_positional_idx=find(ontology_logical_idx & hemisphere_logical_idx); 
    end

    try
        ontology_layout.id32_fSABI(ROI)=Label_Ontology.id32_fSABI(ontology_positional_idx);
    catch
        ontology_layout.id32_fSABI(ROI)=str2double(Label_Ontology.id32_fSABI{ontology_positional_idx});
    end

    ontology_layout.ontology_volume(ROI)=Label_Ontology.volume_mm3(ontology_positional_idx);
    ontology_layout.centroid_PA(ROI)=Label_Ontology.centroid_PA(ontology_positional_idx);
    ontology_layout.centroid_IS(ROI)=Label_Ontology.centroid_IS(ontology_positional_idx);

    [ancestor,r_idx]=get_ancestor_rows(Label_Ontology,ontology_positional_idx,true);
    ontology_layout.ontology_level(ROI)=numel(r_idx);

    if isempty(r_idx)
    else
        ontology_layout.ontology_order_ROI(ROI,1:numel(r_idx))=fliplr(ancestor.ROI');
        ontology_layout.ontology_order_GN_Symbol{ROI}=ancestor.GN_Symbol;
        ontology_layout.ontology_order_Structure{ROI}=ancestor.Structure;
    end
end

%% Check existing regions in ontology to make sure have 100% coverage of parent structures.
unique_parent_ROIs=unique(ontology_layout.ontology_order_ROI);
unique_parent_ROIs=unique_parent_ROIs(unique_parent_ROIs>0);
unique_parent_ROIs=unique_parent_ROIs(sum(ontology_layout.ROI==unique_parent_ROIs')==0);

%% Add more parents if needed for full coverage
offset=height(ontology_layout);

for ROI=1:numel(unique_parent_ROIs)

    ontology_logical_idx=Label_Ontology.ROI==unique_parent_ROIs(ROI);
    ontology_positional_idx=find(ontology_logical_idx==1);
    [ancestor,r_idx]=get_ancestor_rows(Label_Ontology,ontology_positional_idx,true);

    ontology_layout.ROI(ROI+offset)=Label_Ontology.ROI(ontology_positional_idx);
    ontology_layout.Structure{ROI+offset}=Label_Ontology.Structure{ontology_positional_idx};
    ontology_layout.hemisphere_assignment(ROI+offset)=Label_Ontology.hemisphere_assignment(ontology_positional_idx);
    ontology_layout.GN_Symbol{ROI+offset}=Label_Ontology.GN_Symbol{ontology_positional_idx};
    ontology_layout.ARA_abbrev{ROI+offset}=Label_Ontology.ARA_abbrev{ontology_positional_idx};
    ontology_layout.id64_fSABI{ROI+offset}=Label_Ontology.id64_fSABI{ontology_positional_idx};

    try
        ontology_layout.id32_fSABI(ROI+offset)=Label_Ontology.id32_fSABI(ontology_positional_idx);
    catch
        ontology_layout.id32_fSABI(ROI+offset)=str2double(Label_Ontology.id32_fSABI{ontology_positional_idx});
    end

    ontology_layout.ontology_volume(ROI+offset)=Label_Ontology.volume_mm3(ontology_positional_idx);
    ontology_layout.centroid_PA(ROI+offset)=Label_Ontology.centroid_PA(ontology_positional_idx);
    ontology_layout.centroid_IS(ROI+offset)=Label_Ontology.centroid_IS(ontology_positional_idx);

    ontology_layout.ontology_level(ROI+offset)=numel(r_idx);

    if isempty(r_idx)
    else
        ontology_layout.ontology_order_ROI(ROI+offset,1:numel(r_idx))=fliplr(ancestor.ROI');
        ontology_layout.ontology_order_GN_Symbol{ROI+offset}=ancestor.GN_Symbol;
        ontology_layout.ontology_order_Structure{ROI+offset}=ancestor.Structure;
    end
end

%% Indicate if Structure is Most Child -- ie the most distant leaf
All_Parents=unique(ontology_layout.ontology_order_ROI);
All_Parents(All_Parents==0)=[]; %removing exterior if it leaked in
check_parents=ontology_layout.ROI==All_Parents'; %Find the ROI that are parents
ontology_layout.ontology_most_child=~logical(sum(check_parents,2)); %The things that aren't parents are children

ontology_layout=sortrows(ontology_layout,{'ontology_level','centroid_PA'},{'ascend','ascend'});
ontology_layout=rob_order_fixer(ontology_layout,parent_structure);

end