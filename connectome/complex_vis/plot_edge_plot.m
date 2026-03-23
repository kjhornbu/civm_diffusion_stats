function [figure_entries,make_Left_Axis] = plot_edge_plot(directory,vertex,matrix_2_print,selection_pull,data_y_labels,ontology_Order,idx_aboveThreshold,make_Left_Axis,idx_inOntologyOrder,max_entry)
width=3;%width=2*3.3;  -- What width do you want the figures to be (at minimum -- if the font doesn't fit on the graph it will make it bigger).
fontsize=8; %apparent final font size in the figure (typically viewed on mac)
tiny_font=4;
%{
The set colors as part of the white yellow orange range
start_color=[1,1,1];
middle_color=[1,1,0];
end_color=[1,0.5,0];

% Components we need to do the shifting
Y_2_O_CG=linspace(1,0.5,128);
W_2_Y_CB=linspace(1,0,128);

%Putting all together channel by channel
color_map_white_yellow_orange(:,1)=ones(1,256,1);

color_map_white_yellow_orange(1:128,2)=ones(1,128,1);
color_map_white_yellow_orange(129:256,2)=Y_2_O_CG;

color_map_white_yellow_orange(1:128,3)=W_2_Y_CB;
color_map_white_yellow_orange(129:256,3)=zeros(1,128,1);
new_colormap=color_map_white_yellow_orange;

%}

%{
Use White Gold and Berry
%}
start_color=[1,1,1];
middle_color=[255, 193,7]/255;
end_color=[216, 27, 96]/255;

% Components we need to do the shifting

W_2_G_CR=linspace(start_color(1),middle_color(1),5);
W_2_G_CG=linspace(start_color(2),middle_color(2),5);
W_2_G_CB=linspace(start_color(3),middle_color(3),5);

G_2_B_CR=linspace(middle_color(1),end_color(1),6);
G_2_B_CG=linspace(middle_color(2),end_color(2),6);
G_2_B_CB=linspace(middle_color(3),end_color(3),6);

color_map_white_gold_berry(1:5,1)=W_2_G_CR;
color_map_white_gold_berry(6:10,1)=G_2_B_CR(2:end);

color_map_white_gold_berry(1:5,2)=W_2_G_CG;
color_map_white_gold_berry(6:10,2)=G_2_B_CG(2:end);

color_map_white_gold_berry(1:5,3)=W_2_G_CB;
color_map_white_gold_berry(6:10,3)=G_2_B_CB(2:end);

new_colormap=color_map_white_gold_berry;

%% Preliminary Setups
if ispc
    printfactor=(72/96);
    print_num=96;
    alt_print_num=72;
    fontsize=fontsize*printfactor;
    tiny_font=tiny_font*printfactor;
end
if ismac
    printfactor=1;
    print_num=72;
    alt_print_num=72; % you are most likely going to be viewing this on a mac in our lab, so you don't need to figure out pixels in pc
end

%Set Vertices below or == threhold to zero
matrix_2_print(:,~idx_aboveThreshold)=0;

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
if size(matrix_2_print,1)>2
    EntryB=((fontsize*2)/alt_print_num)*2*selection_Number*printfactor; %height
else
    EntryB=2*((fontsize*2)/alt_print_num)*2*selection_Number*printfactor; %height
    %Make taller for case of single comparision so it doesn't get messed
    %up, 
end

set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB]);

max_VAL=max(max(matrix_2_print));
imagesc(matrix_2_print/max_VAL);

yticks(1:height(matrix_2_print))
yticklabels(data_y_labels)

xticks(select_vertex)
xticklabels(select_ipsilateral_contra)

colormap(new_colormap);
colorbar;
caxis([0 1]);

figure_entries.figure=directory;
figure_entries.vertex=vertex(1,1);
figure_entries.maxval_inFigure=max_VAL;
figure_entries.maxval_acrossAllFigures=max_entry;
figure_entries.ratio_inversusacross=max_VAL/max_entry;
figure_entries.minval=0;

% these are the lines on the plot originally they were white shifting to
% black for the super white representation.
hold on
plot([(size(matrix_2_print,2)/2)+0.5 (size(matrix_2_print,2)/2)+0.5],[0 size(matrix_2_print,1)+1],'color',[0 0 0]);

for m=1:selection_Number
    if m ~= selection_Number
        plot([0 size(matrix_2_print,2)+1],[(2*m)+0.5 (2*m)+0.5],'color',[0 0 0]);
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

% %% line form vertex annotations
% for vertex_set=1:numel(sort_position)
%     if sort_position(vertex_set)>180
%         if ~isempty(ontology_Order.GN_Symbol{sort_position(vertex_set)-180})
%             name_temp=strsplit(ontology_Order.GN_Symbol{sort_position(vertex_set)-180},{'-B','-L','-R'});
%         else
%             keyboard; %% added to protect for if uncharted leaks in accidently
%         end
%     else
%         if ~isempty(ontology_Order.GN_Symbol{sort_position(vertex_set)})
%             name_temp=strsplit(ontology_Order.GN_Symbol{sort_position(vertex_set)},{'-B','-L','-R'});
%         else
%             keyboard; %% added to protect for if uncharted leaks in accidently
%         end
%     end
% 
%     text(positioning(vertex_set),0.5,name_temp{1},'HorizontalAlignment','center','FontSize',fontsize,'FontName','FixedWidth');
%     line([sort_position(vertex_set),positioning(vertex_set)],[0 0.4-((fontsize-4.5)/alt_print_num)],'LineWidth',0.25);
% end

%% number form vertex annotations
for vertex_set=1:numel(sort_position)
    if sort_position(vertex_set)>180
        if ~isempty(ontology_Order.GN_Symbol{sort_position(vertex_set)-180})
            name_temp=strsplit(ontology_Order.GN_Symbol{sort_position(vertex_set)-180},{'-B','-L','-R'});
        else
            keyboard; %% added to protect for if uncharted leaks in accidently
        end
    else
        if ~isempty(ontology_Order.GN_Symbol{sort_position(vertex_set)})
            name_temp=strsplit(ontology_Order.GN_Symbol{sort_position(vertex_set)},{'-B','-L','-R'});
        else
            keyboard; %% added to protect for if uncharted leaks in accidently
        end
    end
    text(positioning(vertex_set),0.9,num2str(vertex_set),'HorizontalAlignment','center','FontSize',fontsize,'FontName','FixedWidth');
    text(positioning(vertex_set),0.5,name_temp{1},'HorizontalAlignment','center','FontSize',fontsize,'FontName','FixedWidth');

    if mod(vertex_set,5)==0
        text(sort_position(vertex_set),0.3,'o','HorizontalAlignment','center','FontSize',tiny_font,'FontName','FixedWidth');
        line([sort_position(vertex_set),sort_position(vertex_set)],[0 0.2],'LineWidth',0.25,'Color','k');
    else
        line([sort_position(vertex_set),sort_position(vertex_set)],[0 0.2],'LineWidth',0.25,'Color','k');
    end
end

xticks(0);
xticklabels("");
yticks(0);
yticklabels("");

print(f2, fullfile(directory,'annotations',strcat('ANNOTATIONS_ROI_',num2str(vertex(1,1)),'_',Structure,'_Means.svg')),'-dsvg','-vector');
print(f2, fullfile(directory,'annotations',strcat('ANNOTATIONS_ROI_',num2str(vertex(1,1)),'_',Structure,'_Means.eps')),'-depsc','-vector');

close all;

if make_Left_Axis
    make_Left_Axis=false;

    % Make the ontology axis
    middle_break=height(ontology_Order);

    for levels=1:max(ontology_Order.ontology_level)

        [a,~,c]=unique(ontology_Order.(strcat('level',num2str(levels))));

        not_empty_idx=~cellfun(@isempty,a);
        not_empty_pos_idx=find(not_empty_idx);

            f3a=figure;
            EntryA=(width-((45/alt_print_num)/0.775))*printfactor; %width
            EntryB=0.25*printfactor; %height
            set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB],'InnerPosition',[check_size(1) check_size(2) EntryA*print_num EntryB*print_num]); %*0.80625 for 4 inches
            hold on

            axis([0.5 360.5 0 1]);
            line([0,0],[0 1],'Color','w');

        for m=1:numel(not_empty_pos_idx)
            bar_entries=c==not_empty_pos_idx(m);
            idx_bar_entries=find(bar_entries);
            %idx_bar_entries_starts at 1 so -1+0.5 so begins at correct
            %spot
            start_bar_entries=idx_bar_entries(1)-0.5;
            % and end bar is just extended by 0.5
            stop_bar_entries=idx_bar_entries(end)+0.5;

            middle_bar_entries=mean([stop_bar_entries,start_bar_entries]);

            % Ipsa
            rectangle("Position",[start_bar_entries 0 stop_bar_entries-start_bar_entries,1],"FaceColor",[1 1 1],"EdgeColor",[0 0 0])
            text(middle_bar_entries,0.5,a{not_empty_pos_idx(m)},'HorizontalAlignment','center','FontSize',fontsize/2,'FontName','FixedWidth','Rotation', 90);
            %Contra
            rectangle("Position",[middle_break+start_bar_entries 0 stop_bar_entries-start_bar_entries,1],"FaceColor",[1 1 1],"EdgeColor",[0 0 0])
            text(middle_break+middle_bar_entries,0.5,a{not_empty_pos_idx(m)},'HorizontalAlignment','center','FontSize',fontsize/2,'FontName','FixedWidth','Rotation', 90); 
        end

        xticks(0);
        xticklabels("");
        yticks(0);
        yticklabels("");

        print(f3a, fullfile(directory,'annotations',strcat('ontology_Level',num2str(levels),'.svg')),'-dsvg','-vector');
    end
    close all;

    %% All the LEFT AXES

    EntryA=3.3*printfactor; %width
    if size(matrix_2_print,1)>2
        EntryB=((fontsize*2)/alt_print_num)*2*selection_Number*printfactor; %height
    else
        EntryB=2*((fontsize*2)/alt_print_num)*2*selection_Number*printfactor; %height
        %Make taller for case of single comparision so it doesn't get messed
        %up by overlapping...
    end

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