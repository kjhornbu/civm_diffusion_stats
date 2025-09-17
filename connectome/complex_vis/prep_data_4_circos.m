function [] = prep_data_4_circos(name,raw_as_percent,Seed_ABB,ontology,total_Ordering,threshold)

raw_as_percent_gt1p=raw_as_percent>threshold;

%convert data to nose to butt ordering
Data_reordered=raw_as_percent(total_Ordering);
Data_reordered_gt1p=raw_as_percent_gt1p(total_Ordering);

%Get abbrevations for other end of path and values
ABB=ontology.GN_Symbol(Data_reordered_gt1p(1:180));
length_ABB=length(ABB);

temp=ontology.GN_Symbol(Data_reordered_gt1p(180+(1:180)));
ABB(length_ABB+(1:height(temp)))=temp;
Value=Data_reordered(Data_reordered_gt1p);

% remove non-abbrevation regions
Empty_Entries=cellfun(@isempty,ABB);

Value=Value(~Empty_Entries);
ABB=ABB(~Empty_Entries);

Long_Seed_ABB=repmat({Seed_ABB},height(ABB),1);


for n=1:length(Long_Seed_ABB)
    temp=strsplit(Long_Seed_ABB{n},'-');
    Seed{n,1}=temp{1};
    Seed_hemi{n,1}='l';
    temp=strsplit(ABB{n},'-');
    dees{n,1}=temp{1};

    if n<length_ABB
        dees_hemi{n,1}='l';
    else
        dees_hemi{n,1}='r';
    end

    Connect_value(n,1)=Value(n);
    flag_color(n,1)=1;
end

map_link=table(Seed_hemi, Seed, dees_hemi,dees,flag_color,Connect_value);
writetable(map_link,fullfile(name,'map.links.txt'),'Delimiter',' ','WriteVariableNames',0);

end