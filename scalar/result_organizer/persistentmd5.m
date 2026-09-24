function md5=persistentmd5(varargin)
try
    md5=GetMD5(varargin{:});
catch merr
    [~,n,e]=fileparts(varargin{1});
    t=fullfile(tempdir,sprintf('%s%s',n,e));
    copyfile(varargin{1},t);
    varargin{1}=t;
    md5=GetMD5(varargin{:});
    delete(t);
end
end