function [ontology_layout] = rob_order_fixer(ontology_layout,parent_structure)

%% 1 -- Put CEN and Bottom of CCX
CEN_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(CEN)'));
CEN_positional_idx=find(CEN_logical_idx==1);
temp_CEN=ontology_layout(CEN_positional_idx,:);

CCX_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(CCX)'));
CCX_positional_idx=find(CCX_logical_idx==1);
temp_CCX=ontology_layout(CCX_positional_idx,:);

%[Full_Parent] = parentage_checking(temp_CEN,temp_CCX);

ontology_layout(CEN_positional_idx,:)=ontology_layout(CCX_positional_idx,:);
ontology_layout(CCX_positional_idx,:)=temp_CEN;

%% 2 -- Put Cerebellum between Midbrain and Hindbrain
HBR_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(HBR)'));
HBR_positional_idx=find(HBR_logical_idx==1);
temp_HBR=ontology_layout(HBR_positional_idx,:);


MID_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(MID)'));
MID_positional_idx=find(MID_logical_idx==1);
temp_MID=ontology_layout(MID_positional_idx,:);

Average_HBR_MID_idx=round(mean([HBR_positional_idx,MID_positional_idx]));

%[Full_Parent] = parentage_checking(temp_MID,temp_HBR);

CBX_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(CBX)'));
CBX_positional_idx=find(CBX_logical_idx==1);
temp_CBX=ontology_layout(CBX_positional_idx,:);

CBN_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(CBN)'));
CBN_positional_idx=find(CBN_logical_idx==1);
temp_CBN=ontology_layout(CBN_positional_idx,:);

%[Full_Parent] = parentage_checking(temp_CBX,temp_CBN);
%[Full_Parent] = parentage_checking(temp_CBX,temp_HBR); % This Full_Parentage == 0

if strcmp(parent_structure,'^(RVG-B|MID-B|HBR-B|CBN-B|CBX-B)$')
    %% Chop ontology to only the level working on and beyond
    remove_structures_logical_idx=ontology_layout.ontology_level>=min([temp_MID.ontology_level,temp_HBR.ontology_level,temp_CBX.ontology_level]);
    ontology_layout=ontology_layout(remove_structures_logical_idx,:);
    ontology_layout.ontology_level=ontology_layout.ontology_level-min([temp_MID.ontology_level,temp_HBR.ontology_level,temp_CBX.ontology_level])+1;
    ontology_layout.ontology_order_ROI=ontology_layout.ontology_order_ROI(:,min([temp_MID.ontology_level,temp_HBR.ontology_level,temp_CBX.ontology_level])+1:end);

    %% Then switch around regions to allow 
    % -- but need to get everything in the correct name corrdinates first

    HBR_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(HBR)'));
    HBR_positional_idx=find(HBR_logical_idx==1);

    MID_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(MID)'));
    MID_positional_idx=find(MID_logical_idx==1);

    Average_HBR_MID_idx=round(mean([HBR_positional_idx,MID_positional_idx]));

    temp_Start_to_AverageIDXPlusOne=ontology_layout(HBR_positional_idx:Average_HBR_MID_idx+1,:);

    CBX_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(CBX)'));
    CBX_positional_idx=find(CBX_logical_idx==1);

    CBN_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(CBN)'));
    CBN_positional_idx=find(CBN_logical_idx==1);

    %% Do actual swapping.
    ontology_layout(Average_HBR_MID_idx,:)=ontology_layout(CBX_positional_idx,:);
    ontology_layout(Average_HBR_MID_idx+1,:)=ontology_layout(CBN_positional_idx,:);

    ontology_layout((HBR_positional_idx:Average_HBR_MID_idx+1)-2,:)=temp_Start_to_AverageIDXPlusOne;

    %% pulling out temp ontology for math and adding placeholder to front
    temp_ontology_layout=ontology_layout;
    temp_ontology_layout.ontology_order_ROI=[repmat(-999,height(temp_ontology_layout),1),temp_ontology_layout.ontology_order_ROI];

    %% Adding full placeholder structure at front
    ontology_layout.ROI(1)=-999;
    ontology_layout.GN_Symbol{1}='PlaceHolder';
    ontology_layout.Structure{1}='PlaceHolder';
    ontology_layout.ARA_abbrev{1}='PlaceHolder';
    ontology_layout.ontology_level(1)=0;
    ontology_layout.ontology_order_ROI(1,1:width(temp_ontology_layout.ontology_order_ROI)) = repmat(0,1,width(temp_ontology_layout.ontology_order_ROI));

    ontology_layout(2:height(temp_ontology_layout)+1,:)=temp_ontology_layout;

    %% Select only things we care about
    logical_interesting_things_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,parent_structure));
    postitional_interesting_things_idx=find(logical_interesting_things_idx==1);
 
    interesting_ROI=ontology_layout.ROI(postitional_interesting_things_idx);

    keep_ontology(:,1)=ontology_layout.ROI==-999;
    keep_ontology(:,2)=logical_interesting_things_idx;

    for n=1:numel(interesting_ROI)
        keep_ontology(:,n+2)=sum(ontology_layout.ontology_order_ROI==interesting_ROI(n),2)>0;
    end

    ontology_layout=ontology_layout(sum(keep_ontology,2)>0,:);
    
end

%% 3 -- Put HYP under Thalamus (THA)
THA_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(THA)'));
THA_positional_idx=find(THA_logical_idx==1);
temp_THA=ontology_layout(THA_positional_idx,:);

HYP_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(HYP)'));
HYP_positional_idx=find(HYP_logical_idx==1);
temp_HYP=ontology_layout(HYP_positional_idx,:);

%[Full_Parent] = parentage_checking(temp_THA,temp_HYP);

ontology_layout(HYP_positional_idx,:)=ontology_layout(THA_positional_idx,:);
ontology_layout(THA_positional_idx,:)=temp_HYP;

end