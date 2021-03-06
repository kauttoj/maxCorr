function [U,S]=separate(obj,W,usageType,limn,tol,NullModel)
% [U,S] = obj.separate(W,limn,tol)
%
% Find the components that separate the chosen data-sets from
% each other. The weights in W (typically -1,0,+1) specify which
% parts (e.g. subjects) are separated. Argument limn, if given,
% limits the maximum number of projected-away components to limn.
% Argument tol (default value 0.3660, equal to 30 degree separation)
% gives the tolerance (in singular value) below which two similar
% components are considered the same (similarity can arise between
% the components forced by setCommonRegressors/setIndividualRegressors
% and the data-driven components).
%
% This function returns the components U and the R-squared (= squared
% correlation) values. The components in U maximize the R-squared
% in the data-sets for which W has positive weights while
% simultaneously setting R-squared below the expected value for a random
% vector in data-sets marked with negative weights in W.
%
% For example, [U,S] = obj.separate([1 -ones(1,obj.N-1)]) returns
% component that correlate well within the first data set and
% minimally (= below expected level) within rest of the data sets.
%

% modified 15.9.2018 JanneK
% -allow varying voxel size
% -allow use of permutation to find shared component count (note: much
% lower than standard parametric estimate, allows higher signal reduction)

if (length(W)==1),
    tmp=W;
    W=-ones(1,obj.N);
    W(tmp)=1;
end

if (length(W)~=obj.N),
    error('W must be an index or %d elements long weight vector',obj.N);
end

wpi=find(W>0);
wni=find(W<0);

if (length(obj.XXt)==0), 
    obj.prepare(); 
end

Nr = obj.data_size(1,1); %% added by JK (this should be always equal)
Nc = round(mean(obj.data_size(wni,2))); %% added by JK (affects in estimation of upper limit of noise component count)
Nv = obj.maxComponents();

if nargin<3
    usageType = 0;
end
if (nargin<4), 
    limn = []; 
else
    limn = round(limn); 
end
if (nargin<5),
    tol = 0.3660; % 30 deg separation
elseif (tol==0.0),
    tol = [];
end
if (nargin<6),
    NullModel = 'parametric';
end

assert(strcmp(NullModel,'nonparametric') || strcmp(NullModel,'parametric'));

% tol, 10 deg -> 0.1233, 20 deg -> 0.2456, 30 deg -> 0.3660
% tol, 5 deg -> 0.0617, 1 deg -> 0.0123, 0.1 deg -> 0.0012
if (length(limn)==0 || limn(1)>Nv) 
    limn = Nv; 
end
limn=limn(1);

if (obj.verb)
    fprintf(1,'Separate(W,%d)\n',limn);
end

% estimate r2 for null distribution (highly conservative, large component
% count)
ND=Nr;
r2=maxCorr.calcER2(ND) * Nc;
% covariance matrix of the subject with non-shared signals (to be removed)
XXtp=zeros(Nr,Nr,class(obj.XXt{1}));
for j=1:length(wpi), 
    XXtp=XXtp+obj.XXt{wpi(j)}*W(wpi(j)); 
end;
% covariance matrix of all other subjects with common signals
% note: With unequal signal count, more signals -> higher covariances -> higher
% importance
XXtn=zeros(Nr,Nr,class(obj.XXt{1}));
for j=1:length(wni), 
    XXtn=XXtn-obj.XXt{wni(j)}*W(wni(j)); 
end;
% Now:
%  XXtp = covariance matrix of the dataset to estimate noise components
%  XXtn = sum of covariance matrices of all other datasets
%
if usageType==1
    [U,S]=svd(XXtn,'econ');
    S=diag(S);
    Ntol = sum(S>abs(tol(1)));
    U = U(:,1:Ntol);  
    S = S(1:Ntol);
    return
end

if strcmp(NullModel,'nonparametric')
    % find common component count (K) using permutations for circularly
    % shifted timeseries
    [U,ss]=svd(XXtn,0);
    ss = diag(ss);
    nullvals=nan(1,1000);
    for iter = 1:1000
        XXtn_null=zeros(Nr,Nr,class(obj.XXt{1}));
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
   % (conservative)
   U=findXXt_strict(XXtn,-sum(W(wni)),r2,limn);
end
% construct "must have" regressors
u=[];
if (length(obj.CR)), 
    u=[u obj.CR]; 
end
if (length(wpi)==1 && length(obj.IR)), 
    u=[u obj.IR(:,:,wpi(1))]; 
end;

% construct rest of the regressors
if (length(u)),
    u=maxCorr.normalizeRegressors(u,false);
    P=eye(size(XXtp,1),size(XXtp,1),class(U))-u*pinv(u);
    [UU,s]=svd(P*U,'econ');
else
    [UU,s]=svd(U,'econ'); % note, U and UU are equal, but just in different order (check using CCA)
end
s = diag(s);
if (length(tol)==0),
    if (isa(U,'msMatrix')), t=U.type(); else t=class(U); end;
    tol=max(size(U))*s(1)*eps(t);
end
Ntol = sum(s>abs(tol(1)));
if (obj.verb)
    fprintf(1,'Using %d/%d projections (tol=%g)\n', Ntol+size(u,2), ...
        length(s)+size(u,2), tol);
end
u=[u UU(:,1:Ntol)]; clear s;
P=eye(size(XXtp,1),size(XXtp,1),class(U))-u*pinv(u);

% project shared projections out from individual projection
XXtp=P*XXtp*P';
% find individual components
[U,S]=svd(XXtp);
S=diag(S)/r2;
% remove the weakest components (typically only interested in first ~10)
U=U(:,1:end-size(u,2));
S=S(1:end-size(u,2));

end

function u=findXXt_strict(XXtn,ns,r2,limn)

[u,s]=svd(XXtn);
s=diag(s);
s=s(1:limn);
n=length(find(s>(r2*ns)));
u=u(:,1:n);
    
end
