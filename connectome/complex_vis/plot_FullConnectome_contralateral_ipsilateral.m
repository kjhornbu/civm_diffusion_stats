function [] = plot_FullConnectome_contralateral_ipslateral(directory,output_connectome,total_Ordering)
fontsize=8;
width=3;

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
               setup_connectome(re_index,:)=output_connectome.data{total_Ordering_half_hemi(re_index)}(total_Ordering);
            end


            f=figure;

            EntryA=width*printfactor; %width
            EntryB=width*printfactor*1/2; %height

            set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 EntryA EntryB]);

            imagesc(log10(setup_connectome));

            yticks(0)
            yticklabels('')

            xticks(select_vertex)
            xticklabels(select_ipsilateral_contra)

            colormap('jet');
            
            set(gca,'FontSize',fontsize,'FontName','Arial','TickDir','out');

            print(f, fullfile(directory,strcat('SquareConnectomeof_',value_selection{n},'_',value_compare{m},'NoColorBar.svg')),'-dsvg','-vector');
            print(f, fullfile(directory,strcat('SquareConnectomeof_',value_selection{n},'_',value_compare{m},'NoColorBar.eps')),'-depsc','-vector');

            colorbar;

            print(f, fullfile(directory,strcat('SquareConnectomeof_',value_selection{n},'_',value_compare{m},'.svg')),'-dsvg','-vector');
            print(f, fullfile(directory,strcat('SquareConnectomeof_',value_selection{n},'_',value_compare{m},'.eps')),'-depsc','-vector');

        else
            continue;
        end


    end
end


end