% clear all
% close all;

Path_to_Ontology={"Z:\All_Staff\18.gaj.42\FullAnalysis_20260505\Scalar_and_Volume\anovan_1000010000100001\AgeClass_Strain_Perfusionat_Sex\Non_Erode\Bilateral\complex_figures_EstimatedPower-260709_FromCohenF\ontology_layouts\CEN_CCX_ontology_layout.csv"};

ontology_layout = civm_read_table(Path_to_Ontology);
ontology_layout.length_of_bar=[];
ontology_layout.start_of_bar=[];
idx=reg_match(ontology_layout.Structure,'BRS__Brain');
remove_row=ontology_layout(idx,:);

% Find remove row within the full layout so we can start to index through
% and fix it. 
idx_remove_withinFullBRN_Ontology=ontology_layout.ontology_order_ROI==remove_row.ROI;
for n=1:height(ontology_layout)
    indiv_idx=idx_remove_withinFullBRN_Ontology(n,:);
    pos_indiv_idx=find(indiv_idx);

    if nnz(indiv_idx)>0
        %repair pathing if something is there
        %keyboard;
        ontology_layout.ontology_level(n)=ontology_layout.ontology_level(n)-1;
        ontology_layout.ontology_order_ROI(n,pos_indiv_idx:(end-1))=ontology_layout.ontology_order_ROI(n,(pos_indiv_idx+1):end);
        ontology_layout.ontology_order_GN_Symbol{n}=erase(ontology_layout.ontology_order_GN_Symbol{n},strcat("'",remove_row.GN_Symbol,"';"));
        ontology_layout.ontology_order_Structure{n}=erase(ontology_layout.ontology_order_Structure{n},strcat("'",remove_row.Structure,"';"));
    end
end

ontology_layout=sortrows(ontology_layout,'ontology_level','ascend');
[ontology_layout] = coordinate_positioning(ontology_layout);

ontology_layout.ontology_order_ROI=[];
ontology_layout.ontology_order_Structure=[];

%Fix offset issue at start of the ontology
idx=ontology_layout.start_of_bar==0;
pos_idx=find(idx);

ontology_layout.start_of_bar(ontology_layout.start_of_bar>0)=ontology_layout.start_of_bar(ontology_layout.start_of_bar>0)+numel(pos_idx);
ontology_layout.start_of_bar(pos_idx)=pos_idx;

for n=1:height(ontology_layout)
    temp=double(ontology_layout.ontology_order_GN_Symbol{n});
    find_quote=temp==39;
    temp(find_quote)=[];

    find_semicolon=temp==59;
    temp(find_semicolon)=32;

    char_temp=char(temp);

    ontology_layout.ontology_order_GN_Symbol{n}=strrep(char_temp,'-B','');
    ontology_layout.ontology_order_GN_Symbol{n}=strrep(ontology_layout.ontology_order_GN_Symbol{n},' ','-');
end

ontology_layout=sortrows(ontology_layout,'start_of_bar','descend');

%Soemthing is messed up with the length of the bar here... there are 166
%regions of a bar with 0 lenght... this should not be happening. 

ontology_layout.L_Vertex=ontology_layout.ROI;
ontology_layout.R_Vertex=ontology_layout.L_Vertex+180;

civm_write_table(ontology_layout,'Ontology_Layout_DMBA_20260716_RobFixedOrder-Scalar.txt')
