function data_out = maxCorr_fMRI_dataloader(cfg,index,N_subj,verbose,cleaned_data,var_red_ratio)
% NIFTI data loading and saving function for maxCorr
% input and output data is TIMEPOINTS x VOXELS (inside mask)

% paths specific to your set-up
addpath('/m/nbe/scratch/braindata/shared/toolboxes/bramila/bramila');
addpath('/m/nbe/scratch/braindata/shared/toolboxes/NIFTI');

assert(length(cfg.filenames)==N_subj);

datafile_in = cfg.filenames(index).sourcefile;
datafile_out = cfg.filenames(index).targetfile;

% which mask we should use (noise or full data)
if ischar(verbose) && strcmp(verbose,'real')
    maskfile = cfg.filenames(index).data_maskfile;
else
    maskfile = cfg.filenames(index).maskfile;
end

assert(~isempty(maskfile));

if cfg.useUntouchNifti==1
    nii_mask=load_untouch_nii(maskfile);
else
    nii_mask=load_nii(maskfile);
end

mask=nii_mask.img;
maskID=find(mask>0);

assert(length(maskID)>100); % there should be 100+ voxels in mask!

data_out=[];
if nargin<5
    % data loading mode
    if cfg.useUntouchNifti==1
        nii=load_untouch_nii(datafile_in);
    else
        nii=load_nii(datafile_in);
    end
    data=nii.img;
    
    siz = size(data);
    data  = vol2mat(data,siz);
    data_out = data(:,maskID);    
    if cfg.N_timepoints>0
        data_out((cfg.N_timepoints+1):end,:)=[]; % remove excess timepoints
    end
else
    % data saving mode   
    if cfg.useUntouchNifti==1    
        nii=load_untouch_nii(datafile_in);
    else
        nii=load_nii(datafile_in);
    end
    data=nii.img;
    
    siz = size(data);
    data  = vol2mat(data,siz);
    if cfg.N_timepoints>0
        data((cfg.N_timepoints+1):end,:)=[]; % remove excess timepoints
        siz(4) = cfg.N_timepoints;
    end        
    data(:,maskID) = cleaned_data;
    data = mat2vol(data,siz);
    nii.img = data;
    if cfg.useUntouchNifti==1  
        save_untouch_nii(nii,datafile_out);
    else
        save_nii(nii,datafile_out);
    end
    
    % try to save map of variance reduction (cleaning process)
    try
        datafile_out_varmap = [datafile_out(1:end-4),'_VarianceReductionMap.nii'];
        var_red_ratio_map = nan(size(mask));
        var_red_ratio_map(maskID) = var_red_ratio;
        nii_mask.img = single(var_red_ratio_map);
        nii_mask.hdr.dime.bitpix=16;
        nii_mask.hdr.dime.datatype=16;	        
        if cfg.useUntouchNifti==1
            save_untouch_nii(nii_mask,datafile_out_varmap);
        else
            save_nii(nii_mask,datafile_out_varmap);
        end
    catch err
        warning('FAILED to save variance reduction Nifti map: %s',err.message);
    end
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