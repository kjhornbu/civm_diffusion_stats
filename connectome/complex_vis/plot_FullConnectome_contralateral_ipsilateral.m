function [] = plot_FullConnectome_contralateral_ipsilateral(directory,output_connectome,total_Ordering,ontology_Order)
fontsize=8;
width=3;
make_Axis=1;

directory_full=fullfile(directory,'connectome_plot');

if ~exist(directory_full,'dir')
    mkdir(directory_full);
end


% Preliminary Setups -- set font factors
if ispc
    %printfactor=(72/96);
    printfactor=1;
    printfactor=(96/72);
    printfactor=(1+(72/96))/2;
    print_num=96;
    alt_print_num=72;
    %fontsize=fontsize*printfactor;

end
if ismac
    printfactor=1;
    print_num=72;
    alt_print_num=72;
end

select_ROI=[100 180.5 1100];

select_vertex(select_ROI>1000)=select_ROI(select_ROI>1000)-1000+180;
select_vertex(select_ROI<1000)=select_ROI(select_ROI<1000);

select_ipsilateral_contra={'ipsilateral','','contralateral'};

[value_compare,~,idx_compare]=unique(output_connectome.compare_group);
[value_selection,~,idx_selection]=unique(output_connectome.selection_group);

length_of_data=[numel(output_connectome.data{1})/2,numel(output_connectome.data{1})];
total_Ordering_half_hemi=total_Ordering(1:length_of_data(1));


for m=1:numel(value_compare)
    for n=1:numel(value_selection)
        logical_idx=and(idx_compare==m,idx_selection==n);
        positional_idx=find(logical_idx);

        if ~isempty(positional_idx) && numel(positional_idx)==length_of_data(1)
            setup_connectome=zeros(length_of_data);

            for re_index=1:length_of_data(1)
                setup_connectome(re_index,:)=output_connectome.data{positional_idx(total_Ordering_half_hemi(re_index))}(total_Ordering);
            end

            f=figure;

            EntryA=width*printfactor; %width
            EntryB=width*printfactor*1/2; %height

            set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB],'PaperPositionMode', 'manual');

            imagesc(log10(setup_connectome));

            yticks(0)
            yticklabels('')

            xticks(select_vertex)
            xticklabels(select_ipsilateral_contra)

            colormap('jet');
            caxis([-1 5.5]);

            check_size=f.InnerPosition;
            set(gca,'FontSize',fontsize,'FontName','Arial','TickDir','out');
            print(f, fullfile(directory_full,strcat('SquareConnectomeof_',value_selection{n},'_',value_compare{m},'NoColorBar.eps')),'-depsc','-vector');

            colorbar;
            print(f, fullfile(directory_full,strcat('SquareConnectomeof_',value_selection{n},'_',value_compare{m},'.eps')),'-depsc','-vector');

        else
            continue;
        end

        if make_Axis
            make_Axis=false;
            % Make the ontology axis
            middle_break=height(ontology_Order);

            for levels=1:max(ontology_Order.ontology_level)

                [a,~,c]=unique(ontology_Order.(strcat('level',num2str(levels))));

                not_empty_idx=~cellfun(@isempty,a);
                not_empty_pos_idx=find(not_empty_idx);

                f3a=figure;
                EntryA=width*printfactor; %width
                EntryB=0.25*printfactor; %height
                set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB],'InnerPosition',[check_size(1) check_size(2) EntryA*print_num EntryB*print_num],'PaperPositionMode', 'manual'); %*0.80625 for 4 inches
                hold on

                axis([0.5 360.5 0 1]);
                line([0,0],[0 1],'Color','w');

                for position=1:numel(not_empty_pos_idx)
                    bar_entries=c==not_empty_pos_idx(position);
                    idx_bar_entries=find(bar_entries);
                    %idx_bar_entries_starts at 1 so -1+0.5 so begins at correct
                    %spot
                    start_bar_entries=idx_bar_entries(1)-0.5;
                    % and end bar is just extended by 0.5
                    stop_bar_entries=idx_bar_entries(end)+0.5;

                    middle_bar_entries=mean([stop_bar_entries,start_bar_entries]);

                    % Ipsa
                    rectangle("Position",[start_bar_entries 0 stop_bar_entries-start_bar_entries,1],"FaceColor",[1 1 1],"EdgeColor",[0 0 0])
                    text(middle_bar_entries,0.5,a{not_empty_pos_idx(position)},'HorizontalAlignment','center','FontSize',fontsize/2,'FontName','FixedWidth','Rotation', 90);
                    %Contra
                    rectangle("Position",[middle_break+start_bar_entries 0 stop_bar_entries-start_bar_entries,1],"FaceColor",[1 1 1],"EdgeColor",[0 0 0])
                    text(middle_break+middle_bar_entries,0.5,a{not_empty_pos_idx(position)},'HorizontalAlignment','center','FontSize',fontsize/2,'FontName','FixedWidth','Rotation', 90);
                end

                xticks(0);
                xticklabels("");
                yticks(0);
                yticklabels("");

                print(f3a, fullfile(directory_full,strcat('ontology_Level',num2str(levels),'_forConnectomePlot.eps')),'-depsc','-vector');
            end
        end
    end
end

close all;

end