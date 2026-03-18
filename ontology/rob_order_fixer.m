function [ontology_layout] = rob_order_fixer(ontology_layout,parent_structure)
full=0; % in the case that you want an ontology but fixed with the flipping of the structures that all should be on the BRS but are not change this to a 1. 
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
    adjust_ontology=ontology_layout;

    minlevel=min([temp_MID.ontology_level,temp_HBR.ontology_level,temp_CBX.ontology_level]);

    remove_structures_logical_idx=adjust_ontology.ontology_level>=minlevel;
    adjust_ontology=adjust_ontology(remove_structures_logical_idx,:);
    adjust_ontology.ontology_level=adjust_ontology.ontology_level-minlevel+1;
    adjust_ontology.ontology_order_ROI=adjust_ontology.ontology_order_ROI(:,minlevel+1:end);

    %% Then switch around regions to allow
    % -- but need to get everything in the correct name corrdinates first
    HBR_logical_idx=~cellfun(@isempty,regexpi(adjust_ontology.GN_Symbol,'^(HBR)'));
    HBR_positional_idx=find(HBR_logical_idx==1);

    MID_logical_idx=~cellfun(@isempty,regexpi(adjust_ontology.GN_Symbol,'^(MID)'));
    MID_positional_idx=find(MID_logical_idx==1);

    Average_HBR_MID_idx=round(mean([HBR_positional_idx,MID_positional_idx]));

    temp_Start_to_AverageIDXPlusOne=adjust_ontology(HBR_positional_idx:Average_HBR_MID_idx+1,:);

    CBX_logical_idx=~cellfun(@isempty,regexpi(adjust_ontology.GN_Symbol,'^(CBX)'));
    CBX_positional_idx=find(CBX_logical_idx==1);

    CBN_logical_idx=~cellfun(@isempty,regexpi(adjust_ontology.GN_Symbol,'^(CBN)'));
    CBN_positional_idx=find(CBN_logical_idx==1);

    %% Do actual swapping.
    adjust_ontology(Average_HBR_MID_idx,:)=adjust_ontology(CBX_positional_idx,:);
    adjust_ontology(Average_HBR_MID_idx+1,:)=adjust_ontology(CBN_positional_idx,:);

    adjust_ontology((HBR_positional_idx:Average_HBR_MID_idx+1)-2,:)=temp_Start_to_AverageIDXPlusOne;

    %% pulling out temp ontology for math and adding placeholder to front
    temp_ontology_layout=adjust_ontology;
    temp_ontology_layout.ontology_order_ROI=[repmat(-999,height(temp_ontology_layout),1),temp_ontology_layout.ontology_order_ROI];

    %% Adding full placeholder structure at front
    adjust_ontology.ROI(1)=-999;
    adjust_ontology.GN_Symbol{1}='PlaceHolder';
    adjust_ontology.Structure{1}='PlaceHolder';
    adjust_ontology.ARA_abbrev{1}='PlaceHolder';
    adjust_ontology.ontology_level(1)=0;
    adjust_ontology.ontology_order_ROI(1,1:width(temp_ontology_layout.ontology_order_ROI)) = repmat(0,1,width(temp_ontology_layout.ontology_order_ROI));

    adjust_ontology(2:height(temp_ontology_layout)+1,:)=temp_ontology_layout;

    keep_adjusted_ontology=adjust_ontology;
    %% Select only things we care about
    logical_interesting_things_idx=~cellfun(@isempty,regexpi(adjust_ontology.GN_Symbol,parent_structure));
    postitional_interesting_things_idx=find(logical_interesting_things_idx==1);

    interesting_ROI=adjust_ontology.ROI(postitional_interesting_things_idx);

    keep_ontology(:,1)=adjust_ontology.ROI==-999;
    keep_ontology(:,2)=logical_interesting_things_idx;

    for n=1:numel(interesting_ROI)
        keep_ontology(:,n+2)=sum(adjust_ontology.ontology_order_ROI==interesting_ROI(n),2)>0;
    end

    adjust_ontology=adjust_ontology(sum(keep_ontology,2)>0,:);

    if full
        %% If doing full ontology using this method.

        % Add back in ontology Levels that were removed
        keep_adjusted_ontology.ontology_order_ROI=[repmat(0,height(keep_adjusted_ontology),minlevel-1),keep_adjusted_ontology.ontology_order_ROI];

        % Find the placeholder structure
        logical_placeholder_idx=keep_adjusted_ontology.ROI==-999;
        placeholder_positional_idx=find(logical_placeholder_idx);

        % Find the BRS which is our replacement structure
        BRS_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(BRS)'));
        BRS_positional_idx=find(BRS_logical_idx==1);
        BRS_temp=ontology_layout(BRS_positional_idx,:);

        %replace the placeholder with BRS
        keep_adjusted_ontology(placeholder_positional_idx,:)=BRS_temp;

        % Get all structures that use BRS as a parent in this new system
        Adjusted_BRS_Parent='^(RVG-B|MID-B|HBR-B|CBN-B|CBX-B|DIE-B)$';
        logical_most_interesting_things_idx=~cellfun(@isempty,regexpi(keep_adjusted_ontology.GN_Symbol,Adjusted_BRS_Parent));
        positional_most_interesting_things_idx=find(logical_most_interesting_things_idx);

        for n=1:numel(positional_most_interesting_things_idx)
            keep_adjusted_ontology.ontology_level(positional_most_interesting_things_idx(n))=keep_adjusted_ontology.ontology_level(positional_most_interesting_things_idx(n))+BRS_temp.ontology_level;
            
            keep_adjusted_ontology.ontology_order_ROI(positional_most_interesting_things_idx(n),keep_adjusted_ontology.ontology_order_ROI(positional_most_interesting_things_idx(n),:)==-999)=BRS_temp.ROI;
            keep_adjusted_ontology.ontology_order_ROI(positional_most_interesting_things_idx(n),1:BRS_temp.ontology_level)=BRS_temp.ontology_order_ROI(1:BRS_temp.ontology_level);

            full_GN_symbol={BRS_temp.GN_Symbol{:},BRS_temp.ontology_order_GN_Symbol{:}{:}}';
            keep_adjusted_ontology.ontology_order_GN_Symbol{positional_most_interesting_things_idx(n)}=full_GN_symbol;

            full_Structure={BRS_temp.Structure{:},BRS_temp.ontology_order_Structure{:}{:}}';
            keep_adjusted_ontology.ontology_order_Structure{positional_most_interesting_things_idx(n)}=full_Structure;

            % find all the child structures from this and adjust those
            % children
            logical_child_idx=keep_adjusted_ontology.ontology_order_ROI==keep_adjusted_ontology.ROI(positional_most_interesting_things_idx(n));
            [positional_child_idx,col_positional_child_idx]=find(logical_child_idx);
            if n==1
                keep_logical_child_idx(:,1:width(logical_child_idx))=logical_child_idx;
                offset_keep_child=width(keep_logical_child_idx);
            else
                keep_logical_child_idx(:,offset_keep_child+[1:width(logical_child_idx)])=logical_child_idx;
                offset_keep_child=width(keep_logical_child_idx);
            end

            for m=1:numel(positional_child_idx)
                keep_adjusted_ontology.ontology_level(positional_child_idx(m))=keep_adjusted_ontology.ontology_level(positional_child_idx(m))+BRS_temp.ontology_level;

                keep_adjusted_ontology.ontology_order_ROI(positional_child_idx(m),keep_adjusted_ontology.ontology_order_ROI(positional_child_idx(m),:)==-999)=BRS_temp.ROI;
                keep_adjusted_ontology.ontology_order_ROI(positional_child_idx(m),1:BRS_temp.ontology_level)=BRS_temp.ontology_order_ROI(1:BRS_temp.ontology_level);

            end
        end

        % The other regions in the ontology after this point and we will
        % grab them and adjust them back to where they should be. 

        logical_other_region_idx=~(logical_placeholder_idx|logical_most_interesting_things_idx|(sum(keep_logical_child_idx,2)>0)); 
        positional_other_region_idx=find(logical_other_region_idx);

        for n=1:numel(positional_other_region_idx)

            logical_other_region_mainsheet_idx=ontology_layout.ROI==keep_adjusted_ontology.ROI(positional_other_region_idx(n));
            postional_other_region_mainsheet_idx=find(logical_other_region_mainsheet_idx);

            keep_adjusted_ontology(positional_other_region_idx(n),:)=ontology_layout(postional_other_region_mainsheet_idx,:);
        end

        ontology_layout(remove_structures_logical_idx,:)=keep_adjusted_ontology(2:end,:);

        %Find and remove from ontology CBL -- no longer used because the
        %placeholder is the new parent there. 
        CBL_logical_idx=~cellfun(@isempty,regexpi(ontology_layout.GN_Symbol,'^(CBL)'));
        CBL_positional_idx=find(CBL_logical_idx==1);

        ontology_layout(CBL_positional_idx,:)=[];

    else
        %% If doing partial ontology
        clear ontology_layout;
        ontology_layout=adjust_ontology;
    end

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