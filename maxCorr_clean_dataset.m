function maxCorr_clean_dataset(cfg_file)
% similar to maxCorr.separate, but for an individual subject

    CFG = load(cfg_file);
    
    %fprintf('starting with subject %i of %i (%s)\n',subj_iter,obj.N,datestr(datetime('now')));
    
    addpath(CFG.cfg.maxCorr_path);
    
    N_subj = length(CFG.cfg.filenames);
    
    subj_iter = CFG.cfg.process_index;
    
    obj=maxCorr(@maxCorr_fMRI_dataloader,CFG.cfg,N_subj);
    
    %fprintf('starting with subject %i of %i (%s)\n',subj_iter,obj.N,datestr(datetime('now')));
        
    W=-ones(1,obj.N);
    W(subj_iter)=1;
    
    wpi=find(W>0);
    wni=find(W<0);
    
    data_size = nan(obj.N,2);
    for j = 1:obj.N
        A = load(CFG.cfg.filenames(j).covfile,'data_size','data_type');
        data_size(j,:)=A.data_size;
        data_type = A.data_type;
    end
    A=[];
    
    % signals (average)
    Nc = round(mean(data_size(wni,2))); %% added by JK (affects in estimation of upper limit of noise component count)
    Nr = data_size(1,1); %% added by JK (this should be always equal)
    Nv = data_size(1,1)-1; %% simply set to maximum timepoints - 1

    if ~isfield(CFG.cfg,'NullModel')
        NullModel = 'parametric';
    else
        NullModel=CFG.cfg.NullModel;
    end
    assert(strcmp(NullModel,'nonparametric') || strcmp(NullModel,'parametric'));   

    if ~isfield(CFG.cfg,'limn')
        limn = [];
    else
        limn = round(CFG.cfg.limn);
    end

    if ~isfield(CFG.cfg,'tol')
       tol = 0.3660; % 30 deg separation
    else
       tol = CFG.cfg.tol;
    end
    if (tol==0.0)
        tol = [];
    end        
    % tol, 10 deg -> 0.1233, 20 deg -> 0.2456, 30 deg -> 0.3660
    % tol, 5 deg -> 0.0617, 1 deg -> 0.0123, 0.1 deg -> 0.0012
    if (length(limn)==0 || limn(1)>Nv)
        limn = Nv;
    end
    limn=limn(1);
    
    % estimate r2 for null distribution (highly conservative, large component
    % count)
    ND=Nr;
    r2=maxCorr.calcER2(ND) * Nc;
    % covariance matrix of the subject with non-shared signals (to be removed)
    XXtp=zeros(Nr,Nr,data_type);
    for j=1:length(wpi)
        A = load(CFG.cfg.filenames(wpi(j)).covfile,'XXt');
        XXtp=XXtp+A.XXt*W(wpi(j));
    end
    A=[];
    % covariance matrix of all other subjects with common signals
    % note: With unequal signal count, more signals -> higher covariances -> higher
    % importance
    XXtn=zeros(Nr,Nr,data_type);
    for j=1:length(wni)
        A = load(CFG.cfg.filenames(wni(j)).covfile,'XXt');
        XXtn=XXtn-A.XXt*W(wni(j));
    end
    A=[];
    % Now:
    %  XXtp = covariance matrix of the dataset to estimate noise components
    %  XXtn = sum of covariance matrices of all other datasets
    %
    if 0% strcmp(NullModel,'nonparametric') SKIP it for now - experimental with risk of real signal removal
        fprintf('...%i: starting permutations (%s)\n',subj_iter,datestr(datetime('now')));
        % find common component count (K) using permutations for circularly
        % shifted timeseries
        [U,ss]=svd(XXtn,0);
        ss = diag(ss);
        nullvals=nan(1,1000);
        for iter = 1:1000
            XXtn_null=zeros(Nr,Nr,data_type);
            for j=1:length(wni),
                perm = circshift(1:ND,[0,randi(ND-1)]);
                % permuting covariance matrix rows & cols equals to permuting original
                % timeseries
                XXtn_null=XXtn_null-obj.XXt{wni(j)}(perm,perm)*W(wni(j));
            end;
            [~,s]=svds(XXtn_null,1);
            nullvals(iter)=s;
        end
        % retain components that surpass 1% of top null values
        % lower and hence more aggressive than parametric estimates
        U=U(:,find(ss>prctile(nullvals,1)));
    else
        % find common component count (K) using parametric estimate
        % More conservative default option (in paper)
        U=findXXt_strict(XXtn,-sum(W(wni)),r2,limn);
    end
    N_common_space = size(U,2);
    
    % construct "must have" regressors
    u=[];
    if (length(obj.getCR())),
        u=[u obj.getCR()];
    end
    if (length(wpi)==1 && length(obj.getIR())),
        temp = obj.getIR();
        u=[u temp(:,:,wpi(1))];
    end;
    
    % construct rest of the regressors
    if (length(u)),
        u=maxCorr.normalizeRegressors(u,false);
        P=eye(size(XXtp,1),size(XXtp,1),data_type)-u*pinv(u);
        [UU,s]=svd(P*U,'econ');
    else
        [UU,s]=svd(U,'econ');
    end
    s = diag(s);
    
    if (length(tol)==0),
        if (isa(U,'msMatrix')), t=U.type(); else t=data_type; end;
        tol=max(size(U))*s(1)*eps(t);
    end
    Ntol = sum(s>abs(tol(1)));

    u=[u UU(:,1:Ntol)]; 
    s=[];
    P=eye(size(XXtp,1),size(XXtp,1),data_type)-u*pinv(u);
    
    % project shared projections out from individual projection
    XXtp=P*XXtp*P';
    % find individual components
    [U,S]=svd(XXtp);
    S=diag(S)/r2;
    % remove the weakest components (typically only interested in first <11)
    U=U(:,1:end-size(u,2));
    S=S(1:end-size(u,2));
    
    fprintf('...%i: loading data (%s)\n',subj_iter,datestr(datetime('now')));  
    % get original data
    data = obj.loadFunc(CFG.cfg,subj_iter,obj.N,0);
    assert(data_size(subj_iter,2)==size(data,2));
	fprintf('...%i: data has %i signals with %i timepoints (%s)\n',subj_iter,size(data,2),size(data,1),datestr(datetime('now')));
    % design matrix of noise for this subject
    X = U(:,1:CFG.cfg.N_MaxCorr_components);
    % add constant just in case
    X = [ones(size(X,1),1),X];
    % regress out via pseudoinverse, retain means
    orig_var = var(data);
	% store means
    m = mean(data);
    data = bsxfun(@minus,data,m);
    data = data - X*pinv(X)*data;
	% add means back
    data = bsxfun(@plus,data,m);
    new_var = var(data);
    var_red_ratio = 1 - (new_var./orig_var);
    var_red_summary = 100*(1-sum(new_var)/sum(orig_var));
    fprintf('...%i: stats: %i common-space comps (out of %i), total var reduced by %.2f%% (with %i comps)\n',subj_iter,N_common_space,min(Nv,Nc),var_red_summary,CFG.cfg.N_MaxCorr_components);
    % save cleaned data
    fprintf('...%i: saving data (%s)\n',subj_iter,datestr(datetime('now')));
	% by entering 5th input, we save the cleaned data
    obj.loadFunc(CFG.cfg,subj_iter,obj.N,0,data,var_red_ratio);    
    fprintf('...%i: done! (%s)\n',subj_iter,datestr(datetime('now')));
    
    CFG.stage = 2;
    
    save_cfg(CFG.cfg.filenames(CFG.cfg.process_index).cfgfile,CFG.cfg,CFG.stage,var_red_summary,var_red_ratio,data_size(subj_iter,:));
    
end

function save_cfg(filename,cfg,stage,variance_reduction_total_prc,variance_reduction_ratio,data_size)

save(filename,'cfg','stage','variance_reduction_total_prc','variance_reduction_ratio','data_size','-v7.3');

end

function u=findXXt_strict(XXtn,ns,r2,limn)

    [u,s]=svd(XXtn);
    s=diag(s);
    s=s(1:limn);
    n=length(find(s>(r2*ns)));
    u=u(:,1:n);

end
