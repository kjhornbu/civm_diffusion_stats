function save_sliceAsImage(image_matrix,height,out,alpha_mask)
% this is effectively an internal function to slice_saver.
% simple png save (optional embed in svg, which requiers workstation perl+supporting programs).
am={};
if exist('alpha_mask','var') && ~isempty(alpha_mask)
    am={'Alpha',alpha_mask};
end
imwrite(image_matrix,out.png,am{:});
if isfield(out,'svg')
    % customized perl code to wrap the png into an svg (That is all matlab
    % is doing too, but they're probably compressing which I've not figured
    % out yet.) (im_height, im_width are required in windows to avoid
    % imagemagick, which i didnt a good way to install.)
    cmd=sprintf('png2svg --im_height %i --im_width %i --in %s --out %s --height %g --units cm',...
        size(image_matrix,1),size(image_matrix,2),out.png,out.svg,height);
    if ispc
        % I thought rad_mat preseved the command line vars, but its not
        % currently working. This is hack around that. It works because the
        % bash shell IS found, the bash shell then runs our linuxy perl
        % code normally.
        cmd=sprintf('bash -c "%s"', cmd);
    end
    [s,sout]=system(cmd);
    assert(s==0,'Command failed, error: %s\ncommand:%s\n',sout,cmd);
end
