function maxCorr_clean_group_data_SLURM(cfg)
% run maxCorr for a group with grid processing

assert(cfg.N_MaxCorr_components>0 && cfg.N_MaxCorr_components<15);

if ~isfield(cfg,'NullModel')
    cfg.NullModel = 'parametric';
end
assert(strcmp(cfg.NullModel,'nonparametric') || strcmp(cfg.NullModel,'parametric'));   

if ~isfield(cfg,'limn')
    cfg.limn = []; % default is empty
end

if ~isfield(cfg,'tol')
    cfg.tol = 0.3660; % 30 deg separation is default
end

if isfield(cfg,'output_folder')
   assert(exist(cfg.output_folder,'dir')>0);
else
   cfg.output_folder='';
end

if ~isfield(cfg,'recompute_all')
   cfg.recompute_all=0;
end

cfg_filename = sprintf('maxCorr_group_cfg_%s.mat',datetime('now','Format','yyyy_MM_dd-HH_mm_ss'));

stage = 0; % current stage stored in cfg's
N=length(cfg.filenames);
for i = 1:N
    [filepath,filename] = fileparts(cfg.filenames(i).sourcefile);
    if ~isempty(cfg.output_folder)
        filepath = cfg.output_folder;
        id = ['_subject',num2str(i)];
    else
        id=''; 
    end
    cfg.filenames(i).cfgfile = [filepath,filesep,sprintf('maxCorr_cfg_subject%i.mat',i)];    
    cfg.filenames(i).jobfile1 = [filepath,filesep,sprintf('maxCorr_COV_jobfile_subject%i',i)];
    cfg.filenames(i).jobfile2 = [filepath,filesep,sprintf('maxCorr_cleaning_jobfile_subject%i',i)];
    cfg.filenames(i).covfile = [filepath,filesep,filename,sprintf('_COV%s.mat',id)];
    cfg.filenames(i).targetfile = [filepath,filesep,filename,sprintf('_maxCorr%icomp%s.nii',cfg.N_MaxCorr_components,id)];
    save(cfg.filenames(i).cfgfile,'cfg','stage','-v7.3');
end
for i = 1:N
    cfg.process_index = i;
    save(cfg.filenames(i).cfgfile,'cfg','stage','-v7.3');
end

save(cfg_filename,'cfg','-v7.3');

% STAGE 1: compute covariance matrices
fprintf('\nStarting maxCorr group processing (%s).\n\nComputing covariance matrices...\n',datestr(datetime('now')));
stage=1;
jobnames = cell(1,N);
lognames = jobnames;
cfgfiles = jobnames;
jobfiles = jobnames;
wait_for=true(1,N);
for i = 1:N
    cfgfiles{i} = cfg.filenames(i).cfgfile;
    jobfiles{i} = cfg.filenames(i).jobfile1;
    cfg.process_index = i;
    if cfg.recompute_all || ~exist(cfg.filenames(i).covfile,'file')
       [jobnames{i},lognames{i}] = maxCorr_sendjob(cfg.filenames(i).jobfile1,cfg.filenames(i).cfgfile,cfg.maxCorr_path,'maxCorr_compute_covariance');
    else
       wait_for(i)=false;
       save(cfg.filenames(i).cfgfile,'cfg','stage');    
    end
end
fprintf('total %i jobs submitted (%s)...\n',sum(wait_for),datestr(datetime('now')));
wait_for_jobs(cfgfiles(wait_for),jobnames(wait_for),jobfiles(wait_for),lognames(wait_for),stage);

% STAGE 2: create nuisance regressors and clean data
fprintf('\nCleaning datasets (%s)...\n',datestr(datetime('now')));
stage=2;
jobnames = cell(1,N);
lognames = jobnames;
cfgfiles = jobnames;
jobfiles = jobnames;
wait_for=true(1,N);
for i = 1:N,
    cfgfiles{i} = cfg.filenames(i).cfgfile;
    jobfiles{i} = cfg.filenames(i).jobfile2;
    cfg.process_index = i;
    if cfg.recompute_all || ~exist(cfg.filenames(i).targetfile,'file')
       [jobnames{i},lognames{i}] = maxCorr_sendjob(cfg.filenames(i).jobfile2,cfg.filenames(i).cfgfile,cfg.maxCorr_path,'maxCorr_clean_dataset');
    else
       wait_for(i)=false;
       save(cfg.filenames(i).cfgfile,'cfg','stage','-v7.3'); 
    end
end
fprintf('total %i jobs submitted (%s)...\n',sum(wait_for),datestr(datetime('now')));
wait_for_jobs(cfgfiles(wait_for),jobnames(wait_for),jobfiles(wait_for),lognames(wait_for),stage);

% finally save the variances into a convenient vector format
try
    variance_reduction = nan(1,N);
    for i = 1:N,
        A = load(cfg.filenames(i).cfgfile); 
        variance_reduction(i) = A.variance_reduction;
    end
    save(cfg_filename,'cfg','variance_reduction','-v7.3');
end

fprintf('\n----------- MaxCorr finished! (%s)-------------\n',datestr(datetime('now')));

end