function [ ] = Plot_N_Save_Pval_from_Rcode(save_dir,csv_out,group,subgroup,defined_formula,stratification_name)
%If R Figure Did not save run this file(save_dir,csv_out,df);

% readtable treats empty values as NaN or '', depending on column datatype

Statistical_Test_Result=readtable(csv_out);

if ~isempty(stratification_name)
    Statistical_Test_Result.stratification=repmat({strcat('stratification=',stratification_name)},height(Statistical_Test_Result),1);
end

%Clean Source of Variation
[source_of_variation_entry,~,source_of_variation_idx]=unique(Statistical_Test_Result.source_of_variation,'stable');

for n=1:numel(source_of_variation_entry)
%THIS ONLY WORKS RIGHT NOW WITH Defined matrix!

    check_for_interactions=strsplit(source_of_variation_entry{n},':');

    if isempty(regexpi(source_of_variation_entry{n},'NaN|Residuals'))
        if numel(check_for_interactions)==1
            [corrected_grouping_name] = clean_general_entries_in_source_of_variation(group,subgroup,source_of_variation_entry(n));
            Statistical_Test_Result.source_of_variation(source_of_variation_idx==n)=corrected_grouping_name;
        else
            [corrected_grouping_name] = clean_general_entries_in_source_of_variation(group,subgroup,check_for_interactions);
            Statistical_Test_Result.source_of_variation(source_of_variation_idx==n)={strjoin(corrected_grouping_name,':')};
        end
        %BH Correction considering each source of variation separately
        Statistical_Test_Result.pval_BH(source_of_variation_idx==n)=mafdr(Statistical_Test_Result.pval(source_of_variation_idx==n),'BHFDR',true);

    end
end

logical_idx=~cellfun(@isempty,regexpi(source_of_variation_entry,'NaN|Residuals'));
positional_idx=find(logical_idx);
logical_idx_all=sum(source_of_variation_idx==positional_idx',2)>0;

Statistical_Test_Result(logical_idx_all,:)=[];

%update the entry and idx stuff
[source_of_variation_entry,~,source_of_variation_idx]=unique(Statistical_Test_Result.source_of_variation,'stable');

if size(source_of_variation_entry,1)~=numel(source_of_variation_idx)
    %If we have multiple vertex (which is when we have N*Source of
    %variation) we need to do something instead of the global case

    %Clean Vertex into ROI since they mean basically the same thing  here
    Statistical_Test_Result.Properties.VariableNames{~cellfun(@isempty,regexpi(Statistical_Test_Result.Properties.VariableNames,'vertex'))}='ROI';

    %Get Atlas Label Directory and Pull the Proper Label Names from Rob
    %workstation_data_path=getenv("WORKSTATION_DATA");
    %atlas_label_lookup=fullfile(workstation_data_path,"atlas\symmetric15um\labels\RCCF\symmetric15um_RCCF_labels_lookup.txt");
    atlas_label_lookup=fullfile(getenv('WORKSTATION_DATA'),'atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt');
    look_up_table=civm_read_table(atlas_label_lookup);
    %remove exterior
    look_up_table(look_up_table.ROI==0,:)=[];
    look_up_matrix=Statistical_Test_Result.ROI==look_up_table.ROI';

    %Put some interesting data on the Statistical Test Results
    for n=1:size(look_up_matrix,1)
        Statistical_Test_Result.Structure(n)=look_up_table.Structure(look_up_matrix(n,:));
        Statistical_Test_Result.GN_Symbol(n)=look_up_table.GN_Symbol(look_up_matrix(n,:));
        Statistical_Test_Result.ARA_abbrev(n)=look_up_table.ARA_abbrev(look_up_matrix(n,:));
        Statistical_Test_Result.structure_id(n)=look_up_table.structure_id(look_up_matrix(n,:));

    end

    separated_defined_formula=strsplit(defined_formula,'+');
    for n=1:numel(separated_defined_formula)
         check_for_interactions=strsplit(separated_defined_formula{n},':');
         if numel(check_for_interactions)==1
             [corrected_defined_formula(n)] = clean_general_entries_in_source_of_variation(group,subgroup,separated_defined_formula(n));
         else
             [temp_corrected_name] = clean_general_entries_in_source_of_variation(group,subgroup,check_for_interactions);
             corrected_defined_formula(n)={strjoin(temp_corrected_name,':')};
         end

    end

    combined_corrected_defined_formula=strjoin(corrected_defined_formula,'+');

    Statistical_Test_Result.study_model=repmat({combined_corrected_defined_formula},size(look_up_matrix,1),1); %Need to convert to normal real names
    Statistical_Test_Result.statistical_test=repmat({'N-Way MANOVA in R'},size(look_up_matrix,1),1);

    Statistical_Test_Result=column_reorder(Statistical_Test_Result, {'ROI','structure_id','Structure','GN_Symbol','ARA_abbrev','study_model','statistical_test','source_of_variation','DF','approxF','pval','cohenF','cohenFSquared','eta2','omega2','order_pval','pval_BH'});

    %resave the Pval with the correct format
    writetable(Statistical_Test_Result,csv_out)

    [source_of_variation_entry,~,source_of_variation_idx]=unique(Statistical_Test_Result.source_of_variation,'stable');

    %If the entry numbers is the same as the number of values with those
    %entriese it means we are in the global version so don't plot
    for n=1:numel(source_of_variation_entry)
        source_of_variation_entry{n}=strrep(source_of_variation_entry{n},'*','x');
        source_of_variation_entry{n}=strrep(source_of_variation_entry{n},':','x');

        if isempty(regexpi(source_of_variation_entry{n},'NaN'))

            size_df=size(Statistical_Test_Result(source_of_variation_idx==n,:),1);

            %rough plot 1
            fig1=figure;
            box on;
            set(gcf,'Paperunits','inches','PaperPosition', [0 0 1 1]*3.3);
            set(gca, 'fontsize',8);
            hold on

            semilogy(log10(Statistical_Test_Result.pval(source_of_variation_idx==n)),'ok');
            semilogy(log10(Statistical_Test_Result.pval_BH(source_of_variation_idx==n)),'--g');

            semilogy([1 size_df], log10([0.05 0.05]),'--r');
            semilogy([1 size_df], log10([0.05 0.05]/size(Statistical_Test_Result,1)),'--b'); %the whole Test Set not just the source of variation we are plotting.

            xlabel('Rank Ordered ROIs');
            ylabel('log(Pval)')

            legend('Pval','adjusted(BH)','Pval=0.05','Bonferroni','location','best');

            try
                axis([ 0 size_df floor(min(min([log10(Statistical_Test_Result.pval(:)) log10(Statistical_Test_Result.pval_BH(:))]))) 0])
            catch
                axis([ 0 size_df -2 0])
            end

            print(fig1,fullfile(save_dir,strcat('RankOrder_Pvalues_across_allROI_for_',source_of_variation_entry{n},'.png')),'-dpng','-r600')

            %rough plot 2
            fig2=figure;
            box on;
            set(gcf,'Paperunits','inches','PaperPosition', [0 0 1 1]*3.3);
            set(gca, 'fontsize',8);
            hold on

            semilogy(log10(Statistical_Test_Result.pval((Statistical_Test_Result.ROI<1000)&(source_of_variation_idx==n))),'-k');
            semilogy(log10(Statistical_Test_Result.pval((Statistical_Test_Result.ROI>1000)&(source_of_variation_idx==n))),'-g');

            semilogy(log10(Statistical_Test_Result.pval_BH((Statistical_Test_Result.ROI<1000)&(source_of_variation_idx==n))),'ok');
            semilogy(log10(Statistical_Test_Result.pval_BH((Statistical_Test_Result.ROI>1000)&(source_of_variation_idx==n))),'og');


            semilogy([1 size_df], log10([0.05 0.05]),'--r');
            semilogy([1 size_df], log10([0.05 0.05]/size(Statistical_Test_Result,1)),'--b'); %the whole Test Set not just the source of variation we are plotting.

            xlabel('Rank Ordered ROIs');
            ylabel('log(Pval)')

            legend('Pval-L','Pval-R','PvalBH-L','PvalBH-R','Pval=0.05','Bonferroni','location','best');

            try
                axis([ 0 size_df/2 floor(min(min([log10(Statistical_Test_Result.pval(:)) log10(Statistical_Test_Result.pval_BH(:))]))) 0])
            catch
                axis([ 0 size_df/2 -2 0])
            end

            print(fig2,fullfile(save_dir,strcat('RankOrder_Pvalues_across_ROI_LEFTRIGHTSPLIT_for_',source_of_variation_entry{n},'.png')),'-dpng','-r600')

        end
    end
    close all
else

    %there is no vertex for global
    Statistical_Test_Result= removevars(Statistical_Test_Result,{'vertex'});

    %resave the Pval with the correct format
    writetable(Statistical_Test_Result,csv_out)
end
end
