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
dataroot = '/m/nbe/scratch/alex/private/janne/preprocessed_ini_data';
subjects = {'b1k','d3a','d4w','d6i','e6x','g3r','i2p','i7c','m3s','m8f','n5n','n5s','n6z','o9e','p5n','p9u','q4c','t9u','v1i','v5b','y6g'};
sessions = [2     3     5     7     8]; % or runs

cfg=[];
cfg.recompute_all = 0; % set 1 if want to recompute all results (otherwise skips existing)
%cfg.output_folder = '/m/nbe/scratch/alex/private/janne/preprocessed_ini_data/testing'; % put all new files here (for TESTING)
cfg.maxCorr_path = '/m/nbe/scratch/braindata/kauttoj2/code/maxCorr';
cfg.N_MaxCorr_components = 5; % how many individual "noise" components to remove (5-10 ok)
%% following three parameters are optional, comment out for defaults (safest option)
%cfg.limn_in=0; % maximum component limit
%cfg.tol_in=0.25; % angular separation
%cfg.NullModel='parametric'; % estimation method of common components (parametric is more conservative)

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
        filename = sprintf('%s/%s/run%i/detrended.nii',dataroot,sub,ses);
        cfg.filenames(s).sourcefile = filename;

        % assumed form and name of the mask. This should be a "loose" mask for brain
        % voxels and surrounding space where we obtain relevant signals
        filename = sprintf('%s/%s/run%i/mask.nii',dataroot,sub,ses);
        cfg.filenames(s).maskfile = filename;        
    end      
    % run maxCorr for this session/run
    maxCorr_clean_group_data_SLURM(cfg);
end
