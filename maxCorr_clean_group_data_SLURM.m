function maxCorr_clean_group_data_SLURM(cfg)
% run maxCorr for a group using grid processing (one job/subject)

assert(cfg.N_MaxCorr_components>0 && cfg.N_MaxCorr_components<16,'Component count must be between 1 and 15 (comment out this line to override this limitation!)');

if ~isfield(cfg,'removeCommon')
    cfg.removeCommon=0;
end

if ~isfield(cfg,'NullModel')
    cfg.NullModel = 'parametric';
end
assert(strcmp(cfg.NullModel,'nonparametric') || strcmp(cfg.NullModel,'parametric'));   

if ~isfield(cfg,'limn')
    cfg.limn = []; % default is empty
end

if ~isfield(cfg,'doLocalSerial')
    cfg.doLocalSerial = 0; % do serial computing (SLOW, only for testing
end

if ~isfield(cfg,'print_diagnostics')
    cfg.print_diagnostics = 1; % default 1
end

if ~isfield(cfg,'TR')
    cfg.TR = -1;
end

if ~isfield(cfg,'N_timepoints')
    cfg.N_timepoints=-1;
end

if ~isfield(cfg,'useUntouchNifti')
    cfg.useUntouchNifti=0; % use normal reading mode by default
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
    cfg.filenames(i).diagnosticfile = [filepath,filesep,sprintf('maxCorr_diagnostics_%icomp_subject%i',cfg.N_MaxCorr_components,i)];     
    cfg.filenames(i).cfgfile = [filepath,filesep,sprintf('maxCorr_cfg_%icomp_subject%i.mat',cfg.N_MaxCorr_components,i)];    
    cfg.filenames(i).jobfile1 = [filepath,filesep,sprintf('maxCorr_COV_jobfile_%icomp_subject%i',cfg.N_MaxCorr_components,i)];
    cfg.filenames(i).jobfile2 = [filepath,filesep,sprintf('maxCorr_cleaning_jobfile_%icomp_subject%i',cfg.N_MaxCorr_components,i)];
    cfg.filenames(i).covfile = [filepath,filesep,filename,sprintf('_COV%s.mat',id)];
    if cfg.removeCommon
        cfg.filenames(i).targetfile = [filepath,filesep,filename,sprintf('_REVERSEmaxCorr%icomp%s.nii',cfg.N_MaxCorr_components,id)];
    else
        cfg.filenames(i).targetfile = [filepath,filesep,filename,sprintf('_maxCorr%icomp%s.nii',cfg.N_MaxCorr_components,id)];        
    end
    
    if ~isfield(cfg.filenames(i),'data_maskfile') || (isfield(cfg.filenames(i),'data_maskfile') && isempty(cfg.filenames(i).data_maskfile))
        cfg.filenames(i).data_maskfile = cfg.filenames(i).maskfile;
    end
    
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
       [jobnames{i},lognames{i}] = maxCorr_sendjob(cfg.filenames(i).jobfile1,cfg.filenames(i).cfgfile,cfg.maxCorr_path,'maxCorr_compute_covariance',cfg.doLocalSerial);
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
       [jobnames{i},lognames{i}] = maxCorr_sendjob(cfg.filenames(i).jobfile2,cfg.filenames(i).cfgfile,cfg.maxCorr_path,'maxCorr_clean_dataset',cfg.doLocalSerial);
    else
       wait_for(i)=false;
       save(cfg.filenames(i).cfgfile,'cfg','stage','-v7.3'); 
    end
end
fprintf('total %i jobs submitted (%s)...\n',sum(wait_for),datestr(datetime('now')));
wait_for_jobs(cfgfiles(wait_for),jobnames(wait_for),jobfiles(wait_for),lognames(wait_for),stage);

fprintf('\nGathering group results and plotting diagnostics (%s)\n',datestr(datetime('now')));

% finally collect some group stats and save into main config file
variance_reduction_total_prc = nan(1,N);
noise_design = cell(1,N);
for i = 1:N
    A = load(cfg.filenames(i).cfgfile);
    variance_reduction_total_prc(i) = A.variance_reduction_total_prc;
    noise_design{i} = A.noise_design;
    % if requested, try to plot diagnostic image
    if cfg.print_diagnostics
        try
            fig = plot_noise_timeseries(noise_design{i},cfg.TR,variance_reduction_total_prc(i));
            saveas(fig,[cfg.filenames(i).diagnosticfile,'.png']);
            saveas(fig,[cfg.filenames(i).diagnosticfile,'.fig']);
            close(fig);
        catch err
            warning('Failed to create diagnostic image for subject %i: %s',i,err.message);
        end
    end        
end
save(cfg_filename,'cfg','variance_reduction_total_prc','noise_design','-v7.3');

fprintf('\n----------- MaxCorr finished! (%s)-------------\n',datestr(datetime('now')));

end

function fig = plot_noise_timeseries(noise_design,TR,variance_reduction_total_prc)

fig = figure('position',[0,0,800,1000],'visible','on');

for i=[1,3]
    subplot(3,1,i);hold on;
    box on;
end

% if TR is not set, assume TR=1 sec
if TR<=0
    TR=1;
end

leg1=[];
leg2=[];

Fs = 1/TR;                    % Sampling frequency
T = 1/Fs;                     % Sample time
L = size(noise_design,1);                % Length of signal
t = (0:L-1)*T;                % Time vector
% Sum of a 50 Hz sinusoid and a 120 Hz sinusoid
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
f = Fs/2*linspace(0,1,NFFT/2+1);

fft_power_mat = zeros(size(noise_design,2),length(f));

for i=1:size(noise_design,2)
    y=zscore(noise_design(:,i));
    
    Y = fft(y,NFFT)/L;
    
    subplot(3,1,1);
    plot(t,y+(i-1)*5);
    
    leg1{i}=sprintf('comp%i',i);
    
    %subplot(3,1,2);
    % Plot single-sided amplitude spectrum.
    yy = 2*abs(Y(1:NFFT/2+1));
    %plot(f,yy);
    [~,k]=max(yy);
    fft_power_mat(i,:)=yy;
    leg2{i}=sprintf('%i, peak %0.2fHz)',i,f(k));
    
    subplot(3,1,3);
    % Plot single-sided amplitude spectrum (smoothed)
    yy = smooth(yy,10);
    %[~,k]=max(yy);
    plot(f,yy);        
    %leg3{i}=sprintf('comp%i (peak %0.2fHz)',i,f(k));
end

subplot(3,1,1);
title(sprintf('Noise design (%i comps), total var. red. %0.1f%%',size(noise_design,2),variance_reduction_total_prc));
ylabel('z-scored (shifted)');
xlabel('Time (sec)');
axis tight;
legend(leg1,'location','northeastoutside');

subplot(3,1,3);
title('Single-Sided Amplitude Spectrum, smoothed (span 10)')
xlabel(sprintf('Frequency (Hz) for TR=%0.2fsec',TR));
ylabel('|Y(f)|')
legend(leg2,'location','northeast');
xtick_label = get(gca,'xtick');
xlims = get(gca,'xlim');
xtick_pos = (xtick_label - xtick_label(1))/range(xtick_label);
axis tight;

subplot(3,1,2);
imagesc(fft_power_mat);colorbar;
colormap jet
title('Single-Sided Amplitude Spectrum')
xlabel(sprintf('Frequency (Hz) for TR=%0.2fsec',TR));
ylabel('Component')
%legend(leg2,'location','northeastoutside');
xlims = get(gca,'xlim');
xtick = xtick_pos*range(xlims) + xlims(1);
set(gca,'xtick',xtick,'xticklabel',xtick_label,'ytick',1:size(noise_design,2));
axis tight;

end