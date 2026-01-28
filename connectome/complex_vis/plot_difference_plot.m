function [figure_entries] = plot_difference_plot(directory,difference_criteria,vertex,y_label_information,matrix_2_print_onlyKeyRegions,LUT,ontology_Order,positional_idx_regions)
width=3; %width=2*3.3; -- What width do you want the figures to be (at minimum -- if the font doesn't fit on the graph it will make it bigger).
fontsize=8; %apparent final font size in the figure (typically viewed on mac)

if ~exist(directory,'dir')
    mkdir(directory)
end

if ~exist(fullfile(directory,difference_criteria),'dir')
    mkdir(fullfile(directory,difference_criteria))
end

%% Preliminary Setups -- set font factors
if ispc
    printfactor=(72/96);
    print_num=96;
    alt_print_num=72;
    fontsize=fontsize*printfactor;

end
if ismac
    printfactor=1;
    print_num=72;
    alt_print_num=72;
end

%check width with annotation size
EntryA=(width-((45/alt_print_num)/0.775));
Label_Annotations=((fontsize*(3+1))/alt_print_num)*numel(positional_idx_regions);
if EntryA < Label_Annotations
    width=Label_Annotations+((45/alt_print_num)/0.775);
end

figure_entries=table;

Structure_Temp=strsplit(ontology_Order.Structure{ontology_Order.L_Vertex==vertex},'_');
Structure=strjoin(Structure_Temp(1:end-1),'_'); %Get the structure name to put in the file name

selection_Number=size(matrix_2_print_onlyKeyRegions,1); %selection number is the number of repeating units we have of data -- because difference each set == 1 row

%% Figures
f=figure;
EntryA=width*printfactor; %width
EntryB=((fontsize*1.5)/alt_print_num)*selection_Number*printfactor; %height

set(gcf,'Units', 'inches','PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB],'Position',[0 0 EntryA EntryB]);
hold on

f.PaperPosition(4)=f.PaperPosition(4)+0.4;
f.Position(4)=f.Position(4)+0.4;

for m=1:selection_Number
    for n=1:numel(positional_idx_regions)
        rectangle('Position',[n,((m-1)/selection_Number), 1, 1/selection_Number],'FaceColor',[LUT.c_r(m,n),LUT.c_g(m,n),LUT.c_b(m,n)],'EdgeColor',[1 1 1]);
    end
end

axis([1 numel(positional_idx_regions)+1 0 1 ]);

figure_entries.figure=directory;
figure_entries.vertex=vertex(1,1);
figure_entries.maxval=max(max(matrix_2_print_onlyKeyRegions));
figure_entries.minval=min(min(matrix_2_print_onlyKeyRegions));

%% Regions on Bottom, Contra/Ipsilateral on Bottom
%% get all the x axis label entries
for vertex_set=1:numel(positional_idx_regions)
    if positional_idx_regions(vertex_set)>180
        if ~isempty(ontology_Order.GN_Symbol{positional_idx_regions(vertex_set)-180})
            name_temp=strsplit(ontology_Order.GN_Symbol{positional_idx_regions(vertex_set)-180},{'-B','-L','-R'});
            select_location(vertex_set)=vertex_set+0.5;
            select_region{vertex_set}=name_temp{1};
        end
    else
        if ~isempty(ontology_Order.GN_Symbol{positional_idx_regions(vertex_set)})
            name_temp=strsplit(ontology_Order.GN_Symbol{positional_idx_regions(vertex_set)},{'-B','-L','-R'});
            select_location(vertex_set)=vertex_set+0.5;
            select_region{vertex_set}=name_temp{1};
        end
    end
end

hemisphere_logical=([0,diff(positional_idx_regions>180)])>0;

if sum(hemisphere_logical)>0
    plot([find(hemisphere_logical) find(hemisphere_logical)],[0 size(matrix_2_print_onlyKeyRegions,1)+1],'color',[0 0 0]);
    select_ROI=[mean(0.5+[1:find(hemisphere_logical)-1]) find(hemisphere_logical) mean(0.5+[find(hemisphere_logical):length(hemisphere_logical)])];
    select_ipsilateral_contra={'ipsilateral','','contralateral'};
else
    select_ROI=mean(0.5+[1:numel(positional_idx_regions)]);
    select_ipsilateral_contra={'ipsilateral'};
end

%% Add x axis things to plot
ax=gca;
ax.Units='inches';
rangeX=xlim;
innerax=ax.InnerPosition;

for vertex_set=1:numel(positional_idx_regions)
    text(innerax(3)*((select_location(vertex_set)-rangeX(1))/(rangeX(2)-rangeX(1))),-(fontsize/print_num),select_region{vertex_set},'FontSize',fontsize,'FontName','FixedWidth','Units','inches','HorizontalAlignment','center');
end

for ROI_set=1:numel(select_ROI)
    text(innerax(3)*((select_ROI(ROI_set)-rangeX(1))/(rangeX(2)-rangeX(1))),-2.25*(fontsize/print_num),select_ipsilateral_contra{ROI_set},'FontSize',fontsize,'FontName','Arial','Units','inches','HorizontalAlignment','center');
end

%% Add dummy Legend to scale things
figure_pos=f.Position;
ax=gca;
ax_pos=ax.Position;

l=legend('Location','southoutside');
l_pos=l.Position;

new_ax_pos=ax.Position;
fig_shift=new_ax_pos - ax_pos;

set(f, 'position', figure_pos - [ 0 0 0 fig_shift(4)]);
set(l,'position',l_pos);
set(gca,'position',ax_pos + [ 0 fig_shift(2) 0 0 ]);

%% Y Axis, Finish X Axis and Saving

yticks(((1/selection_Number)/2)+0:1/selection_Number:1)
yticklabels(y_label_information)
set(gca,'FontSize',fontsize,'FontName','Arial');

xticks(0);
xticklabels("");

legend("off");

print(f, fullfile(directory,difference_criteria,strcat('ROI_',num2str(vertex(1,1)),'_',Structure,'_Difference_via_',difference_criteria,'_Key_Edges.svg')),'-dsvg','-vector');
close all

end