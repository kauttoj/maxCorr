function data_out = maxCorr_fMRI_dataloader(cfg,index,N_subj,verbose,cleaned_data)
% NIFTI data loading and saving function for maxCorr
% input and output data is TIMEPOINTS x VOXELS (inside mask)

% paths specific to your set-up
addpath('/m/nbe/scratch/braindata/shared/toolboxes/bramila/bramila');
addpath('/m/nbe/scratch/braindata/shared/toolboxes/NIFTI');

assert(length(cfg.filenames)==N_subj);

datafile_in = cfg.filenames(index).sourcefile;
datafile_out = cfg.filenames(index).targetfile;
maskfile = cfg.filenames(index).maskfile;

nii=load_nii(maskfile);
mask=nii.img;
maskID=find(mask>0);

assert(length(maskID)>1000); % there should be a least 1000+ voxels!

data_out=[];
if nargin<5
    % data loading mode
    nii=load_nii(datafile_in);
    data=nii.img;
    
    siz = size(data);
    data  = vol2mat(data,siz);
    data_out = data(:,maskID);
    
else
    % data saving mode   
    nii=load_nii(datafile_in);
    data=nii.img;
    
    siz = size(data);
    data  = vol2mat(data,siz);
    data(:,maskID) = cleaned_data;
    data = mat2vol(data,siz);
    nii.img = data;
    save_nii(nii,datafile_out);
end

end

function voldata = vol2mat(voldata,siz) 
    % prepare the 4D data to be regressed  
    voldata=reshape(voldata,prod(siz(1:3)),siz(4))';
end

function tsdata = mat2vol(tsdata,siz)
    % prepare the 4D data to be regressed
    tsdata=reshape(tsdata',siz);
end