function [graphs] = load_graph(df)

% should only be used as an override on request.
% IF we've already baked it into our dataframe(which is the plan) we avoid
% reloading by cleverly checking if we've loaded before.
%atlas_lookup_path=fullfile(getenv('WORKSTATION_DATA'),'atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt');

%{
look_up_table=civm_read_table(atlas_label_lookup);
%}

lookups=struct;
for n=1:size(df,1)
    lookup_path=df.label_lookup_path{n};
    md5_p=sprintf('L%s',strmd5(df.label_lookup_path{n}));
    if ~isfield(lookups,md5_p)
        look_up_table=civm_read_table(lookup_path);
        lookups.(md5_p)=look_up_table;
    else
        look_up_table=lookups.(md5_p);
    end
%for n=1:size(df,1)
    %typically call all the connectome files as either connectome_file or file
    required_rois=look_up_table.ROI;
    required_rois(required_rois==0|isnan(required_rois))=[];
    try
        [~,~,ext]=fileparts(df.connectome_file{n});
        x='connectome_file';
    catch
        [~,~,ext]=fileparts(df.file{n});
        x='file';
    end

    switch ext
        case  '.txt'
            temp_connectome=readtable(df.(x){n});
            [connectivity] = add_missing_roi_text_file_extension(temp_connectome,look_up_table);
            graphs(n,:,:)=connectivity(:,:);

        case '.mat'
            %load(df.(x){n});

            try
                temp_connectome=dsiconnectivity(df.(x){n},required_rois);
                %[connectivity] = add_missing_roi_mat_file_extension(temp_connectome,look_up_table);
                graphs(n,:,:)=temp_connectome.connectivity(:,:);
            catch
                error('Make sure you have the directory holding the connectome files loaded!!!')
                %graphs(n,:,:)=-1*ones(360,360); % a flag for telling if the data is bad after loading... see if there are patterns to the badness

                %keyboard;
            end

        case '.xlsx'
            connectivity = xlsread(df.(x){n}, 'Connectivity', 'B4:ZZ2000');
            assert(all(size(connectivity)==[df.vcount(n) df.vcount(n)]), 'you messed up, rick')
            graphs(n,:,:)=connectivity;

        otherwise
            error('File extension Not Found');
    end
end
disp('Loading finished')
%graphs=double(graphs);
end