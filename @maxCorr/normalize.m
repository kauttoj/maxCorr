function d=normalize(d)
% d = obj.normalize(d)
%
% Normalized the data in d for correlation computation (i.e. removes
% mean and scales to unit length).
%

d=bsxfun(@minus,d,mean(d)); % remove mean
   
if (isa(d,'msMatrix')), 
    ss = d.sqSum();
else
    ss=sum(d.^2);
end

d=bsxfun(@times,d,1./sqrt(max(ss,1e-16))); % scale to unit length

end
