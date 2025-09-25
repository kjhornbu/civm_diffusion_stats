function [dataframe] = dataframe_convert(dataframe,varargin)
%converts dataframe paths from windows to mac and back given you give the
%folders corresponding... typically need working directory, atlas archive,
%and where the label lookup path exists. Order doesn't matter just needs to
%be multiple cells of what exists in dF now; where the folder is in the system you are
%converting it to. Follow example below:
%{

[dataframe_out] = dataframe_convert(dataframe,...
    {'/Volumes/dusom_civm-atlas/24.niehs.01/research/';'A:\24.niehs.01\research\'},...
    {'/Volumes/dusom_civm-kjh60/All_Staff/';'Z:\All_Staff\'},...
    {'/Volumes/workstation/static_data/atlas/';'C:\workstation\static_data\atlas\'});
%}

for n=1:numel(varargin)
    findInDF{n}=varargin{n}{1};
    convertToInDF{n}=varargin{n}{2};
end

if ~istable(dataframe)
    dataframe_path=dataframe;
    dataframe=civm_read_table(dataframe_path);
end

if ~isfile(dataframe.connectome_file{1})
    convert_paths=list2cell('connectome_file stat_path stat_path_erode label_lookup_path label_path');
    for m=1:numel(convert_paths)
        keep_slash_for=reg_match(dataframe.(convert_paths{m}){1},'/');
        keep_slash_back=reg_match(dataframe.(convert_paths{m}){1},'\');
        use_this_N_idx=~cellfun(@isempty,regexpi(dataframe.(convert_paths{m}){1},findInDF));
        use_this_N=find(use_this_N_idx);

        dataframe.(convert_paths{m})=strrep(dataframe.(convert_paths{m}),findInDF{use_this_N}, convertToInDF{use_this_N});
        if keep_slash_for
            dataframe.(convert_paths{m})=strrep(dataframe.(convert_paths{m}),'/','\');
        elseif keep_slash_back
            dataframe.(convert_paths{m})=strrep(dataframe.(convert_paths{m}),'\','/');
        end
    end
end
end