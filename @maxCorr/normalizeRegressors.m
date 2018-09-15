function d = normalizeRegressors(d, compr)
% d = obj.normalizeRegressors(d, compr)
%
% Normalises regressors to unit length. Compresses them (i.e. removes
% redundancies) if compr is true (default = false).
%

if (size(d,2)==0), return; end;

if (isa(d,'msMatrix')), t=d.type(); else t=class(d); end;

if (size(d,2)>size(d,1)), d=d'; end

if (nargin<2), compr = false; end;

if (compr && size(d,2)>1),
   [u,s,v]=svd(d,'econ'); s = diag(s); clear v;
   tol=max(size(u))*s(1)*eps(t);
   Ntol = sum(s>tol);
   d = u(:,1:Ntol);
else
   for j=1:size(d,3),
      l = sum(d(:,:,j).^2,1);
      for i=1:length(l),
	 if (l(i)>eps(t)), l(i) = 1.0/sqrt(l(i)); else l(i)=1.0; end;
      end
      d(:,:,j) = bsxfun(@times, d(:,:,j), l);
   end
end

return;


   
