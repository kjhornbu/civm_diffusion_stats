function [] = prep_map_4_circos(name,ontology_color,total_Ordering)


ordered_ontology_color=ontology_color(total_Ordering,:);

Level_Name=ordered_ontology_color.level_3;
ABB=ordered_ontology_color.GN_Symbol;
Color(:,1)=ordered_ontology_color.c_r;
Color(:,2)=ordered_ontology_color.c_g;
Color(:,3)=ordered_ontology_color.c_b;

NOT_empty_idx=~cellfun(@isempty,ABB);
NOT_empty_positional_idx=find(NOT_empty_idx);

for n=1:height(NOT_empty_positional_idx)
    Level_Name_OUT(n)=Level_Name(NOT_empty_positional_idx(n));

    temp=strsplit(ABB{NOT_empty_positional_idx(n)},'-');
    hemi_valf{n}=temp{end};
    ABB_OUT{n}=temp{1};

    Color_OUT(n,1)=Color(NOT_empty_positional_idx(n),1);
    Color_OUT(n,2)=Color(NOT_empty_positional_idx(n),2);
    Color_OUT(n,3)=Color(NOT_empty_positional_idx(n),3);
end

single_hemisphere=reg_match(hemi_valf,'L');

map=table(Level_Name_OUT(single_hemisphere)', ABB_OUT(single_hemisphere)', Color_OUT(single_hemisphere,:)); 
writetable(map,fullfile(name,'map.txt'),'Delimiter',' ','WriteVariableNames',0);

end