function I=sign_motion_fdr(U,M,N,p,o)

% I=SIGN_MOTION_FDR(U,MOTION,N,PROB,OFFS)
%
% Detect which components of U are significantly connected to the
% motion parameters in MOTION. This significance (FDR corrected) is
% checked between the derivatives of the column-vectors using
% correlation. N is the "effective length" of the vectors, i.e.  the
% estimated length of white-noise vectors producing similar
% null-distribution for correlation values. If not given, N is assumed
% to be size(U,1). PROB is the p-value threshold (default value 0.05)
% against which the significance is checked. OFFS is the list of
% offsets (default [0,1]) to use between the column time-series in U
% and MOTION. Positive offsets allow effects of motion to show up
% later in time in U. A 0/1 vector I is returned and it identifies the
% column-vectors of U showing significant (derivative) correlation by
% respective value 1 in I.
%

if (nargin<3 || length(N)==0), N = size(U,1); end;
if (nargin<4 || length(p)==0), p = 0.05; end;
if (nargin<5 || length(o)==0), o = [0:1]; end;

% compute derivative correlations with given offsets
[mac,l] = mac_deriv(U,M,o);

% effective N
eN = N-2-(N-l);

% max. abs. correlations for columns of U
r = max(mac,[],2)';
t = abs(r).*sqrt(eN./(1-r.^2));

% compute p-value, t-value and correlation threshold
p = p/(2*length(o)); % two-tailed
T = abs(mac(:)).*sqrt(eN./(1-mac(:).^2));
P = sort(tcdf(-T,eN));
T = [1:length(P)]'*p/length(P);
K = find([((P-T)>0); 1],1,'first');
th = -tinv((K+0.5)*p/length(P),eN);

I = (t>th);
