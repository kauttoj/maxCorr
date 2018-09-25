function r2=calcER2(ND)
% r2 = calcER2(N)
%
% Compute the expected R-squared value for data-vector length N.
%
r=[-1:0.001:1];
pt=tpdf(r.*sqrt((ND-2)./(1-r.^2)),ND-2);
r2=sum(pt.*(r.^2))/sum(pt);

return;
