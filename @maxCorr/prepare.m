function obj=prepare(obj,W)
% obj = obj.prepare(W)
%
% Set the voxel-wise weights in W (default = ones) and set up
% internal variable.

% modified 15.9.2018 JanneK
% -allow varying voxel size
% -use parfor

if (nargin<2), W=[]; end;

if (size(W,1)>1),
    if (size(W,2)>1), W=diag(W); else W=W'; end;
end

obj.W = W;

if (length(obj.XXt)>0), obj.XXt=[]; end;

obj.XXt = cell(obj.N,1);
obj.data_size=[];
obj.data_type=[];

for i=1:obj.N,
    XXt{i}=[];
    data_size{i} = nan(1,2); %% added by JK
    dtype{i} = [];
end

%for i=1:obj.N,
for i=1:obj.N,
    
    d = obj.getPart(i);
    
    dtype{i} = class(d);
    data_size{i} = size(d); %% added by JK
    
    if (isa(d,'msMatrix')),
        tt = d.type;
        d = d.toType();
    else tt=class(d); end;
    
    if (length(W)>0 && length(W)~=size(d,2))
        error('Wrong number of weights, must be %d.',size(d,2));
    end

    %   
    if (length(W)>0), % multiply weights
        d = bsxfun(@times, d,W);
    end
    
    % compute (unscaled) covariance matrix
    try
        XXt{i} = d*d';
    catch
        blocks = 1000;               
        loops = ceil(data_size{i}(2)/blocks);
        if (isa(d, 'single'))
            XXt{i} = zeros(data_size{i}(1),data_size{i}(1), 'single');
        else
            XXt{i} = zeros(data_size{i}(1),data_size{i}(1));
        end
        endBlock = 0;
        for nblock = 1:loops
            startBlock = endBlock + 1;
            endBlock = min([endBlock + blocks, data_size{i}(2)]);
            XXt{i} = XXt{i} + (d(:,startBlock:endBlock)*d(:,startBlock:endBlock)');
        end
    end    
    d =[];    
end

dsize = nan(obj.N,2);
for i=1:obj.N,
    obj.XXt{i} = XXt{i};
    dsize(i,:) = data_size{i};
end
data_size=dsize;
assert(nnz(data_size(:,1) - data_size(1,1) ~= 0)==0); %% added by JK (must have equal timepoints count)
obj.data_size = data_size;
obj.data_type=dtype{1};

end


