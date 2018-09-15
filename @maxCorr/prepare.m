function obj=prepare(obj,W)
% obj = obj.prepare(W)
%
% Set the voxel-wise weights in W (default = ones) and set up
% internal variable.

% modified 15.9.2018 JanneK
% -allow varying voxel size

if (nargin<2), W=[]; end;

if (size(W,1)>1),
    if (size(W,2)>1), W=diag(W); else W=W'; end;
end

obj.W = W;

if (length(obj.XXt)>0), obj.XXt=[]; end;

data_size = nan(obj.N,2); %% added by JK

for i=1:obj.N,
    obj.data_size = []; %% added by JK (originally before the loop)
    d=obj.getPart(i);
    data_size(i,:) = obj.data_size; %% added by JK
    
    if (isa(d,'msMatrix')),
        tt = d.type;
        d = d.toType();
    else tt=class(d); end;
    %
    if (i==1)
        if (length(W)>0 && length(W)~=size(d,2))
            error('Wrong number of weights, must be %d.',size(d,2));
        end
        obj.XXt = cell(obj.N,1);
    end
    %
    t = d';
    if (length(obj.W)>0), % multiply weights
        d = bsxfun(@times, d, obj.W);
    end;
    if (obj.verb),
        fprintf(1,'Multiplying %dx%d * %dx%d - ',size(d,1),size(d,2),size(t,1),size(t,2));
    end;
    obj.XXt{i} = d*t; 
    if (obj.verb), fprintf(1,'done.\n'); end;
    clear d t;
end

assert(nnz(data_size(:,1) - data_size(1,1) ~= 0)==0); %% added by JK (must have equal timepoints)

obj.data_size = data_size;

return;