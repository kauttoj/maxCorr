% This template script runs maxCorr for multiple sessions and subjects.
% Each session is processed parallel as individual jobs over all subjects.
% Result files, job scripts and logs are saved into the folders of
% functional NIFTI source files.
% Every functional file results into a new NIFTI file with filename
% *_maxCorrXcomp.nii, where X is the number of noise components.
% At moment, supports only basic usage without additional regressors or complex weighting schemes

% NOTE: You should include all subjects of interest. Cleaning results
% depends on the whole group. Any change in data or subjects requires a new
% maxCorr computation!

clearvars;
close all;
clc;

% we assume that NIFTI data is stored as /dataroot/subject/run/*.nii
dataroot = [pwd,filesep,'TESTDATA'];
subjects = {'sub-19' 'sub-22' 'sub-37' 'sub-25' 'sub-35' 'sub-44'};
sessions = [1]; % or runs

cfg=[];
cfg.recompute_all = 1; % set 1 if want to recompute all results (otherwise skips all existing results)
cfg.output_folder = [pwd,filesep,'TESTDATA']; % put all new files here (useful for TESTING)
cfg.maxCorr_path = pwd;
cfg.useUntouchNifti = 0; % use UNTOUCH nifti read/write mode, recommended only for native space data!
% cfg.N_timepoints = 100; % if set, only take fixed number of timepoints (useful if there are excess data at the end)
cfg.N_MaxCorr_components = 5; % how many individual "noise" components to remove (~5-10 typically ok)
cfg.removeCommon = 1; % if yes, we do REVERSE maxCorr by removing maximal common components in aim is to boost individual signal power
cfg.doLocalSerial = 1; % if 1, using local computing instead of submitting jobs to SLURM, ONLY FOR DEBUGGING!
cfg.TR=2.4;

%% following three parameters are optional, comment out for defaults (safest option)
%cfg.limn_in=0; % maximum component limit
%cfg.tol_in=0.25; % angular separation

% Every subjects needs input functional data and mask as NIFTI files
% cfg.filenames(s).sourcefile = functional NIFTI (multiple slices)
% cfg.filenames(s).maskfile = mask NIFTI (only clean data using these voxels) 

% process sessions in serial fashion
addpath(cfg.maxCorr_path);
for ses = sessions, 
    cfg.filenames=[];
    % process subjects in parallel
    for s = 1:length(subjects),       
        sub = subjects{s};        
        
        % assumed form of datapath
        % NOTE: Also a folder to save all results and tempfiles for this subject
        filename = sprintf('%s\\%s_mask_detrend_fullreg_filtered_smoothed.nii',dataroot,sub);
        cfg.filenames(s).sourcefile = filename;

        % OPTIONAL: You can separate data and noise masks, i.e., get signals from noise mask and apply cleaning to data mask
        % If not set, the same mask is used for noise and cleaning (default function)
        %% data mask whose voxels signals are cleaned
        %filename = sprintf('%s/%s/run%i/data_mask.nii',dataroot,sub,ses);
        %cfg.filenames(s).data_maskfile = filename;     
        
        % assumed form and name of the mask. This should be a "loose" mask for brain
        % voxels and surrounding space where we obtain relevant signals
        filename = sprintf('%s\\grand_analysis_mask.nii',dataroot);
        cfg.filenames(s).maskfile = filename;           
    end      
    % run maxCorr for this session/run
    maxCorr_clean_group_data_SLURM(cfg);
end
