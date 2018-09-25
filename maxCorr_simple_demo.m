% Script demonstrates usage and results of MaxCorr with toy data and varying "voxel" counts
%
% Note that this toy data is linearly separable by construct, hence MaxCorr is optimal in separating noise
% Real data always contains nonlinearity, which violates MaxCorr key assumptions of linearity
%
% 15.9.2018 Janne Kauttonen

clearvars;
close all;
clc;

s = RandStream('mt19937ar','Seed',1);
RandStream.setGlobalStream(s);

% data dimensions
N_subj = 12; % subjects
N_voxels = 1000+randi(100,1,N_subj); % randomize voxel count per subject
T = 300; % timepoints
N_common_signals = 15; % how many common signals
N_unique_signals = 30; % how many unique/individual signals
N_MaxCorr_components = 10; % how many noise components to remove

% create common signals (stimulus driven)
common_signals = randn(T,N_common_signals);

data=[];
data_var=[];
for i=1:N_subj
    fprintf('Creating data for subject %i\n',i);
    
    subject_name{i} = sprintf('subject%i',i);
    
    % common signals, which we want to retain
    common_part{i} = randn(N_voxels(i),N_common_signals)*common_signals';
    
    % unique noise signals, e.g., motion and respiration. This has to go!
    unique_signals{i} = randn(N_unique_signals,T);
    unique_part{i} = randn(N_voxels(i),N_unique_signals)*unique_signals{i};
    
    % random noise, e.g., data acquistion instrument noise
    noise_part{i} = 0.5*randn(N_voxels(i),T);
    
    % linear summation of signals
    data{i} = common_part{i} + unique_part{i} + noise_part{i};
    % data must be time x voxels
    data{i} = data{i}';    
    % remove linear trends of not interest
    data{i} = detrend(data{i},'linear');
    
    % how much variance each part can explain?
    data_var(i,:) = [...
        sum(var(common_part{i}'*pinv(common_part{i}')*data{i})),...
        sum(var(unique_part{i}'*pinv(unique_part{i}')*data{i})),...
        sum(var(noise_part{i}'*pinv(noise_part{i}')*data{i}))...
        ];
end

% Create maxCorr object

% METHOD 1: Use anonymous function call (recommended)
% function will be called with 4 parameters: fun(subject_name,index,N,verbose_flag)
data_function = @(x1,x2,x3,x4) data{x2};  % here we only need the index, could also use subject name and structs
obj=maxCorr(data_function,subject_name,N_subj);

% % METHOD 2: create big 3D datamatrix where we set missing data as NaN. Wasteful with varying signal counts!
% alldata = nan(T,max(N_voxels),N_subj);
% for i=1:N_subj
%     alldata(:,1:N_voxels(i),i)=data{i};
% end
% obj=maxCorr(alldata);

% compute unique (noise) components
fprintf('\n\n');
canoncorr_results=[];
U=[];
S=[];
for i=1:N_subj
    w = -ones(1,N_subj);
    w(i) = 1;
    % U = time x component, subject-dependent noise signals
    % S = 1 x component, eigenvalue
    fprintf('Computing regressors for subject %i\n',i);
    %[U{i},S{i}] = obj.separate(w,[],[],'nonparametric'); % use nonparametric component count estimation (experimental, heavy cleaning)
    [U{i},S{i}] = obj.separate(w);% use standard parametric estimation (recommended, light cleaning)
    
    % test how well U can explain different parts of original signals
    fprintf('..separation result for subject %i\n',i);
    [A,B,r1] = canoncorr(U{i}(:,1:N_MaxCorr_components),common_signals);
    fprintf('.... CCA with common signals (should be LOW): %s\n',num2str(r1));
    [A,B,r2] = canoncorr(U{i}(:,1:N_MaxCorr_components),unique_signals{i}');
    fprintf('.... CCA with unique signals (should be HIGH): %s\n',num2str(r2));
    
    canoncorr_results(i,:) = [mean(r1),mean(r2)]; % simply get mean correlation
end

% clean data by regressing out invidual components
clean_data=[];
clean_data_var=[];
for i=1:N_subj
    % design matrix of noise for this subject
    X = U{i}(:,1:N_MaxCorr_components);
    % add constant just in case
    X = [ones(size(X,1),1),X];
    % regress out via pseudoinverse
    clean_data{i} = data{i} - X*pinv(X)*data{i};

%    % alternative way
%     clean_data{i} = nan(size(data{i}));
%     for k=1:size(data{i},2)
%         [~,~,clean_data{i}(:,k)]=regress(data{i}(:,k),X);
%     end
%     
    % compute how much signal is left for each part
    clean_data_var(i,:) = [...
        sum(var(common_part{i}'*pinv(common_part{i}')*clean_data{i})),...
        sum(var(unique_part{i}'*pinv(unique_part{i}')*clean_data{i})),...
        sum(var(noise_part{i}'*pinv(noise_part{i}')*clean_data{i}))...
        ];
end
clean_ratio = clean_data_var./data_var;

% some plotting
figure('position',[11    92   935   435]);

subplot(1,2,2);
bar(clean_ratio);
legend({'Shared','Individual','Noise'},'location','best')
xlabel('Subject')
ylabel('Variance ratio CLEAN/RAW')
title(sprintf('MaxCorr with %i components',N_MaxCorr_components));
axis tight;

subplot(1,2,1);
bar(canoncorr_results);
legend({'Shared','Individual'},'location','best')
xlabel('Subject')
ylabel('Average CCA correlation (removed signal)')
title(sprintf('MaxCorr with %i components',N_MaxCorr_components));
axis tight;


