function [figure_entries,make_Left_Axis] = plot_blue_plot_get_key_vertex_details(directory,vertex,matrix_2_print,selection_pull,data_y_labels,ontology_Order,make_Left_Axis,idx_inOntologyOrder)
width=3;%width=2*3.3;  -- What width do you want the figures to be (at minimum -- if the font doesn't fit on the graph it will make it bigger).
fontsize=8; %apparent final font size in the figure (typically viewed on mac)

%% Preliminary Setups
if ispc
    printfactor=(72/96);
    print_num=96;
    alt_print_num=72;
    fontsize=fontsize*printfactor;
end
if ismac
    printfactor=1;
    print_num=72;
    alt_print_num=72; % you are most likely going to be viewing this on a mac in our lab, so you don't need to figure out pixels in pc
end

figure_entries=table;

Structure_Temp=strsplit(ontology_Order.Structure{ontology_Order.L_Vertex==vertex},'_');
Structure=strjoin(Structure_Temp(1:end-1),'_'); %Get the structure name to put in the file name but remove the directionality component

selection_Number=size(matrix_2_print,1)/2; %selection number is the number of repeating units we have of data

%These are the count and positions of the top regions in ontology ordering
count_vertex_10pct_noUncharted=sum(idx_inOntologyOrder);
sort_position=find(idx_inOntologyOrder); %This sorts it by increasing ontology positional value

N=15; %How many labels to put on graph
if count_vertex_10pct_noUncharted > N
    num_labels=N;
else
    num_labels=count_vertex_10pct_noUncharted;
end
% Width compare label width to label area neededed
EntryA=(width-((45/alt_print_num)/0.775));
Label_Annotations=((fontsize*(3+1))/alt_print_num)*num_labels;
if EntryA < Label_Annotations
    width=Label_Annotations+((45/alt_print_num)/0.775);
end

if ~exist(directory,'dir')
    mkdir(directory)
end

if ~exist(fullfile(directory,'annotations'),'dir')
    mkdir(fullfile(directory,'annotations'))
end

if ~exist(fullfile(directory,'edge_strength_plot'),'dir')
    mkdir(fullfile(directory,'edge_strength_plot'))
end

%% Where to put the Figure's X Label Things
select_ROI=[100 180.5 1100];

select_vertex(select_ROI>1000)=select_ROI(select_ROI>1000)-1000+180;
select_vertex(select_ROI<1000)=select_ROI(select_ROI<1000);

select_ipsilateral_contra={'ipsilateral','','contralateral'};

%% Make output plots -- Average Mean Plots (Blue)
f=figure;
EntryA=width*printfactor; %width
EntryB=((fontsize*2)/alt_print_num)*2*selection_Number*printfactor; %height

set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB]);

imagesc(matrix_2_print);

yticks(1:height(matrix_2_print))
yticklabels(data_y_labels)

xticks(select_vertex)
xticklabels(select_ipsilateral_contra)

max_VAL=max(max(matrix_2_print));

colormap jet
colorbar;
caxis([0 max_VAL]);

figure_entries.figure=directory;
figure_entries.vertex=vertex(1,1);
figure_entries.maxval=max_VAL;
figure_entries.minval=0;

hold on
plot([(size(matrix_2_print,2)/2)+0.5 (size(matrix_2_print,2)/2)+0.5],[0 size(matrix_2_print,1)+1],'color',[1 1 1]);

for m=1:selection_Number
    if m ~= selection_Number
        plot([0 size(matrix_2_print,2)+1],[(2*m)+0.5 (2*m)+0.5],'color',[1 1 1]);
    end
end

check_size=f.InnerPosition;
set(gca,'FontSize',fontsize,'FontName','Arial','TickDir','out');
print(f, fullfile(directory,'edge_strength_plot',strcat('ROI_',num2str(vertex(1,1)),'_',Structure,'_Means.svg')),'-dsvg','-vector');
close all;

%% Make output plots -- Average Mean Plots (Blue) -- ANNOTATIONS Labels (THE KEY VERTICES!!!).
f2=figure;
EntryA=(width-((45/alt_print_num)/0.775))*printfactor; %width
EntryB=0.5*printfactor; %height

set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB],'InnerPosition',[check_size(1) check_size(2) EntryA*print_num EntryB*print_num]); %*0.80625 for 4 inches

positioning=linspace(0,360,N+1);
positioning=positioning+(positioning(2)-positioning(1))/2;
positioning(positioning>360)=[];

rectangle("Position",[0.5 0 360.5,1],"FaceColor",[1 1 1],"EdgeColor",[1 1 1])
axis([0.5 360.5 0 1]);

line([0,0],[0 1],'Color','w');

for vertex_set=1:numel(sort_position)
    if sort_position(vertex_set)>180
        if ~isempty(ontology_Order.GN_Symbol{sort_position(vertex_set)-180})
            name_temp=strsplit(ontology_Order.GN_Symbol{sort_position(vertex_set)-180},{'-B','-L','-R'});
            text(positioning(vertex_set),0.9,name_temp{1},'HorizontalAlignment','center','FontSize',fontsize,'FontName','FixedWidth');
            line([sort_position(vertex_set),positioning(vertex_set)],[0 0.8-((fontsize-4.5)/alt_print_num)]);
        else
            keyboard; %% added to protect for if uncharted leaks in accidently
        end
    else
        if ~isempty(ontology_Order.GN_Symbol{sort_position(vertex_set)})
            name_temp=strsplit(ontology_Order.GN_Symbol{sort_position(vertex_set)},{'-B','-L','-R'});
            text(positioning(vertex_set),0.9,name_temp{1},'HorizontalAlignment','center','FontSize',fontsize,'FontName','FixedWidth');
            line([sort_position(vertex_set),positioning(vertex_set)],[0 0.8-((fontsize-4.5)/alt_print_num)]);
        else
            keyboard; %% added to protect for if uncharted leaks in accidently
        end
    end
end

xticks(0);
xticklabels("");
yticks(0);
yticklabels("");

print(f2, fullfile(directory,'annotations',strcat('ANNOTATIONS_ROI_',num2str(vertex(1,1)),'_',Structure,'_Means.svg')),'-dsvg','-vector');
close all;

if make_Left_Axis
    make_Left_Axis=false;
    EntryA=3.3*printfactor;
    EntryB=((fontsize*2)/alt_print_num)*2*selection_Number*printfactor;

    %% Make output plots -- Average Mean Plots (Blue) -- Left Super labels for Y axis.
    f3=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB],'InnerPosition',[check_size(1) check_size(2) EntryA*print_num EntryB*print_num]);

    rectangle("Position",[0 0.5 0.5 2*(selection_Number)+0.5],"FaceColor",[1 1 1],"EdgeColor",[1 1 1])
    axis([0 0.5 0.5 2*(selection_Number)+0.5]);

    positioning = linspace(0,2*(selection_Number),(selection_Number)+1)+1;
    positioning(positioning>2*(selection_Number))=[];

    for n=1:(selection_Number)
        text(0.25,positioning(n),strcat(selection_pull{n},'{'),'HorizontalAlignment','right','VerticalAlignment','middle','FontSize',fontsize,'FontName','Arial');
    end

    xticks(0);
    xticklabels("");
    yticks(0);
    yticklabels("");

    print(f3, fullfile(directory,'annotations',strcat('ANNOTATIONS_LEFTAXIS_A_Means.svg')),'-dsvg','-vector');
    close all;

    %% Make output plots -- Average Mean Plots (Blue) -- Left Super labels for Y axis.
    f3=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB],'InnerPosition',[check_size(1) check_size(2) EntryA*print_num EntryB*print_num]);

    rectangle("Position",[0 0.5 0.5 2*(selection_Number)+0.5],"FaceColor",[1 1 1],"EdgeColor",[1 1 1])
    axis([0 0.5 0.5 2*(selection_Number)+0.5]);

    positioning = linspace(0,2*(selection_Number),(selection_Number)+1)+1;
    positioning(positioning>2*(selection_Number))=[];

    for n=1:(selection_Number)
        text(0.25,positioning(n),strcat(selection_pull{n}),'HorizontalAlignment','right','VerticalAlignment','middle','FontSize',fontsize,'FontName','Arial');
    end

    xticks(0);
    xticklabels("");
    yticks(0);
    yticklabels("");

    print(f3, fullfile(directory,'annotations',strcat('ANNOTATIONS_LEFTAXIS_B_Means.svg')),'-dsvg','-vector');
    close all;

    %% Make output plots -- Average Mean Plots (Blue) -- Left Super labels for Y axis.
    f3=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB],'InnerPosition',[check_size(1) check_size(2) EntryA*print_num EntryB*print_num]);

    rectangle("Position",[0 0.5 0.5 2*(selection_Number)+0.5],"FaceColor",[1 1 1],"EdgeColor",[1 1 1])
    axis([0 0.5 0.5 2*(selection_Number)+0.5]);

    positioning = linspace(0,2*(selection_Number),(selection_Number)+1)+1;
    positioning(positioning>2*(selection_Number))=[];

    for n=1:(selection_Number)
        text(0.25,positioning(n),strcat(selection_pull{n}),'HorizontalAlignment','right','VerticalAlignment','middle','FontSize',fontsize,'FontName','Arial');
        line([0.25,0.3],[positioning(n),positioning(n)-0.5])
        line([0.25,0.3],[positioning(n),positioning(n)+0.5])
    end

    xticks(0);
    xticklabels("");
    yticks(0);
    yticklabels("");

    print(f3, fullfile(directory,'annotations',strcat('ANNOTATIONS_LEFTAXIS_C_Means.svg')),'-dsvg','-vector');
    close all;
end
end