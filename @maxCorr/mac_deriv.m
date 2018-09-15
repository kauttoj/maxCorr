function [mac,l]=mac_deriv(A,B,offs)

% [MAC,L]=MAC_DERIV(A,B,OFFS)
%
% Maximum absolute correlations between the derivatives (i.e. one-step
% differences) of column-vectors in A and B. Vector OFFS (default [0])
% gives the applied offsets between A and B. Offset is applied to A,
% i.e. +1 takes further down rows and matches them with B. The returned
% matrix MAC of maximum absolute correlation values has the same shape
% as corr(A,B) would produce, i.e. as many rows as A has columns and
% equally many columns to B. The effective length of the correlated
% vectors (after one-step difference and most-extreme offseting) is
% returned in L.
%

if (nargin<3), offs=[0]; end;

% check vector sizes
if (size(A,1)~=size(B,1)),
   error('mac_deriv:mismatch', ...
      sprintf('Vector size mismatch between A and B (%d<>%d)',size(A,1),size(B,1)));
   return;
end

% compute the differences
A = A(2:end,:) - A(1:end-1,:);
B = B(2:end,:) - B(1:end-1,:);

% initialize output matrix
mac = zeros(size(A,2),size(B,2),class(A));

% work with offsets
m=min(offs); M=max(offs); O=max(0,-m); l = size(A,1)-max(0,M)-O;

for i=1:length(offs),
   mac = max(mac, abs(corr(A([1:l]+offs(i)+O,:), B([1:l]+O,:))));
end
