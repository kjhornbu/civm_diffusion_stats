
function [Full_Content] = Increase_Decrease_Text(Full_Content,data_table,cohenF_Threshold)
if (height(data_table)>10)
    [Full_Content]=do_assign_text(Full_Content,data_table(1:10,:),cohenF_Threshold);
else
    [Full_Content]=do_assign_text(Full_Content,data_table,cohenF_Threshold);
end
end

function [Full_Content]=do_assign_text(Full_Content,data_table,cohenF_Threshold)
import mlreportgen.ppt.*

if height(data_table)>0
    GN_selected=data_table.GN_Symbol(1:height(data_table));
    CohenF_selected=data_table.cohenF(1:height(data_table));

    abb_regions_identified=GN_selected;

    text_bold=strjoin(abb_regions_identified(CohenF_selected>cohenF_Threshold),', ');
    t=Text(text_bold);
    t.Style = {Bold(true)};
    append(Full_Content,t);

    text_normal=strjoin(abb_regions_identified(CohenF_selected<=cohenF_Threshold),', ');
    if ~isempty(text_normal)
        if ~isempty(text_bold)
            append(Full_Content,Text(', '));
        end
    end
    t=Text(text_normal);
    t.Style = {Bold(false)};
    append(Full_Content,t);
else

end

end