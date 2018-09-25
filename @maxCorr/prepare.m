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
<<<<<<< HEAD

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
=======
    %
    t = d';
    if (length(obj.W)>0), % multiply weights
        d = bsxfun(@times, d, obj.W);
    end;
    if (obj.verb),
        fprintf(1,'Multiplying %dx%d * %dx%d - ',size(d,1),size(d,2),size(t,1),size(t,2));
    end;
    
    % compute (unscaled) covariance matrix
    try
        obj.XXt{i} = d*t;
    catch
        blocks = 1000;               
        loops = ceil(data_size(i,2)/blocks);
        if (isa(t, 'single'))
            obj.XXt{i} = zeros(data_size(i,1),data_size(i,1), 'single');
        else
            obj.XXt{i} = zeros(data_size(i,1),data_size(i,1));
        end
        endBlock = 0;
        for nblock = 1:loops
            startBlock = endBlock + 1;
            endBlock = min([endBlock + blocks, data_size(i,2)]);
            obj.XXt{i} = obj.XXt{i} + (d(:,startBlock:endBlock)*t(startBlock:endBlock, :));
        end
    end
    
    if (obj.verb), fprintf(1,'done.\n'); end;
    clear d t;
end

assert(nnz(data_size(:,1) - data_size(1,1) ~= 0)==0); %% added by JK (must have equal timepoints count)
>>>>>>> 17d3129fa76097129e0a4bbe82b0175c6b0d76e8

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


<<<<<<< HEAD
=======
end


>>>>>>> 17d3129fa76097129e0a4bbe82b0175c6b0d76e8
