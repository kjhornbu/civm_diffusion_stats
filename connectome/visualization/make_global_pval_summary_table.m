function [slidedata] = make_global_pval_summary_table(ppt,global_pval_table)
import mlreportgen.ppt.*;

title=strjoin({'Global: ',studymodel},'');
anova_summary_table = removevars(global_pval_table,["order_pval","pval_BH"]);

% remove underscore change pval to P - Value
logical_idx_underscore=~cellfun(@isempty,regexpi(anova_summary_table.Properties.VariableNames,'_'));
pos_idx_underscore=find(logical_idx_underscore);
for n=1:numel(pos_idx_underscore)
    anova_summary_table.Properties.VariableNames{pos_idx_underscore(n)}=strrep(anova_summary_table.Properties.VariableNames{pos_idx_underscore(n)},'_',' ');
end

logical_idx_pval=~cellfun(@isempty,regexpi(anova_summary_table.Properties.VariableNames,'[Pp]val'));
pos_idx_pval=find(logical_idx_pval);
data_name=anova_summary_table.Properties.VariableNames{pos_idx_pval};
for n=1:numel(pos_idx_underscore)
    anova_summary_table.Properties.VariableNames{pos_idx_pval(n)}=strrep(anova_summary_table.Properties.VariableNames{pos_idx_pval(n)},data_name,'P-Value');
end

slidedata = add(ppt,"Title and Content");
replace(slidedata,"Title",title);
replaces(slidedata,"Content",anova_summary_table);

end