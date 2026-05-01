function [] = dimensional_plot(plot_data,save_path,pval_type)

%% -Log10 Plotting
f = figure;
set(gcf,'Paperunits','inches','PaperPosition', [0 0 1 1]*3.3);
hold on

for n=1:height(plot_data)

    plot(plot_data.(strcat(pval_type,'_Dim1'))(n),plot_data.(strcat(pval_type,'_Dim2'))(n),'o','MarkerSize',plot_data.MarkerSize(n),...
        'MarkerFaceColor',[plot_data.MarkerFaceColor_r(n),plot_data.MarkerFaceColor_g(n),plot_data.MarkerFaceColor_b(n)],...
        'MarkerEdgeColor',[plot_data.MarkerEdgeColor_r(n),plot_data.MarkerEdgeColor_g(n),plot_data.MarkerEdgeColor_b(n)]);

    if ~isempty(regexpi(pval_type,'^(NEGLog10_pval)')) && (plot_data.(strcat(pval_type,'_Dim1'))(n)>-log10(0.05/height(plot_data)) || plot_data.(strcat(pval_type,'_Dim2'))(n)>-log10(0.05/height(plot_data)))
        text(plot_data.(strcat(pval_type,'_Dim1'))(n),plot_data.(strcat(pval_type,'_Dim2'))(n),plot_data.GN_Symbol{n},'fontsize',2,'FontName','Arial','HorizontalAlignment','center','VerticalAlignment','middle');
    elseif ~isempty(regexpi(pval_type,'^(NEGLog10_pval_BH)')) && (plot_data.(strcat(pval_type,'_Dim1'))(n)>-log10(0.05) || plot_data.(strcat(pval_type,'_Dim2'))(n)>-log10(0.05))
        text(plot_data.(strcat(pval_type,'_Dim1'))(n),plot_data.(strcat(pval_type,'_Dim2'))(n),plot_data.GN_Symbol{n},'fontsize',2,'FontName','Arial','HorizontalAlignment','center','VerticalAlignment','middle');
    elseif ~isempty(regexpi(pval_type,'^(pval)')) && (plot_data.(strcat(pval_type,'_Dim1'))(n)>(0.05/height(plot_data)) || plot_data.(strcat(pval_type,'_Dim2'))(n)>(0.05/height(plot_data)))
        text(plot_data.(strcat(pval_type,'_Dim1'))(n),plot_data.(strcat(pval_type,'_Dim2'))(n),plot_data.GN_Symbol{n},'fontsize',2,'FontName','Arial','HorizontalAlignment','center','VerticalAlignment','middle');
    elseif ~isempty(regexpi(pval_type,'^(pval_BH)')) && (plot_data.(strcat(pval_type,'_Dim1'))(n)>0.05 || plot_data.(strcat(pval_type,'_Dim2'))(n)>0.05)
        text(plot_data.(strcat(pval_type,'_Dim1'))(n),plot_data.(strcat(pval_type,'_Dim2'))(n),plot_data.GN_Symbol{n},'fontsize',2,'FontName','Arial','HorizontalAlignment','center','VerticalAlignment','middle');
    end
end

if regexpi(pval_type,'^(NEGLog10_pval)$')
    max_round = ceil(max([plot_data.(strcat(pval_type,'_Dim1'));plot_data.(strcat(pval_type,'_Dim2'))]));
    plot(-log10([.05 .05]/height(plot_data)),[0 max_round] ,'--k')
    plot([0 max_round],-log10([.05 .05]/height(plot_data)),'--k')
    axis([0 max_round 0 max_round]);
elseif regexpi(pval_type,'^(NEGLog10_pval_BH)$')
    max_round = ceil(max([plot_data.(strcat(pval_type,'_Dim1'));plot_data.(strcat(pval_type,'_Dim2'))]));
    plot(-log10([.05 .05]),[0 max_round] ,'--k')
    plot([0 max_round],-log10([.05 .05]),'--k')
    axis([0 max_round 0 max_round]);
elseif regexpi(pval_type,'^(pval_BH)$')
    plot([.05 .05],[0 1] ,'--k')
    plot([0 1],[.05 .05],'--k')
    axis([0 1 0 1]);
elseif regexpi(pval_type,'^(pval)$')
    plot([.05 .05]/height(plot_data),[0 1] ,'--k')
    plot([0 1],[.05 .05]/height(plot_data),'--k')
    axis([0 1 0 1]);
end

contrast_value=unique(plot_data.contrast);
source_of_variation_value=unique(plot_data.source_of_variation);
stratification_value_1=unique(plot_data.stratification_Dim1);
stratification_value_2=unique(plot_data.stratification_Dim2);

Parsed_Strat_Name_1 = strsplit(stratification_value_1{1},' ');
Parsed_Strat_Name_2 = strsplit(stratification_value_2{1},' ');

Parsed_Strat_Name_1_nounderscore=strrep(Parsed_Strat_Name_1{2},'_',' ');
Parsed_Strat_Name_2_nounderscore=strrep(Parsed_Strat_Name_2{2},'_',' ');

if regexpi(pval_type,'^(NEGLog10_pval)$')
    pval_Value = '(-log10P nominal)';
elseif regexpi(pval_type,'^(NEGLog10_pval_BH)$')
   pval_Value = '(-log10P BH corrected)';
elseif regexpi(pval_type,'^(pval)$')
    pval_Value = '(P nominal)';
elseif regexpi(pval_type,'^(pval_BH)$')
    pval_Value = '(P BH corrected)';
end

source_of_variation_value_noUnderscore=strrep(source_of_variation_value{1},'_',' '); 
contrast_value_noUnderscore=strrep(contrast_value{1},'_',' '); 

    xlabel(strcat(Parsed_Strat_Name_1_nounderscore,':',32,source_of_variation_value_noUnderscore,32,'Difference for ROIs in',32,contrast_value_noUnderscore,32,pval_Value));
    ylabel(strcat(Parsed_Strat_Name_2_nounderscore,':',32,source_of_variation_value_noUnderscore,32,'Difference for ROIs in',32,contrast_value_noUnderscore,32,pval_Value));
   
set(gca, 'fontsize',6,'FontName','Arial');

print(f, save_path,'-dsvg','-vector');
civm_write_table(plot_data,strrep(save_path,'.svg','.csv'));
end