function [ontology_Order,total_Ordering] = find_proper_ontology_order(ontology_Order,data_middle_idx)
%clean and remove the missing 175 region

ontology_Order=sortrows(ontology_Order,'ROI');
ontology_Order(ontology_Order.ROI<=0,:)=[];
idx_postion_before=find(diff(ontology_Order.ROI)>1); %This is the position (which is really an ROI since we only have one hemisphere marked in the order) where we miss

ontology_Order=sortrows(ontology_Order,'start_of_bar','descend');
Just_Before=find((ontology_Order.L_Vertex==idx_postion_before)==1);
temp_before=ontology_Order(1:Just_Before,:);
temp_after=ontology_Order(Just_Before+1:end,:);

clear ontology_Order

ontology_Order=temp_before;
ontology_Order.L_Vertex(Just_Before+1)=idx_postion_before+1;
ontology_Order.R_Vertex(Just_Before+1)=(idx_postion_before+1)+data_middle_idx;

currentHeight=height(ontology_Order);
ontology_Order(currentHeight+(1:height(temp_after)),:)=temp_after;

total_Ordering=[ontology_Order.L_Vertex;ontology_Order.R_Vertex];

end