function n = maxComponents(obj)
% n = obj.maxComponents()
%
% Return the maximum number of meaningful components.

if (length(obj.XXt)==0), obj.prepare(); end;

Nr = obj.data_size(1,1); %% added by JK (this should be always equal)
Nc = round(mean(obj.data_size(:,2))); %% added by JK
t = obj.data_type;

T=ones(Nr,1);
if (length(obj.CR)), T=[T obj.CR]; end;
if (length(obj.IR) && obj.N==1), T=[T obj.IR]; end;

[~,s]=svd(T,'econ'); s = diag(s);
tol=max(size(T))*s(1)*eps(t);
Ntol = sum(s>tol);

n = min(Nr-Ntol,Nc*obj.N);

end


