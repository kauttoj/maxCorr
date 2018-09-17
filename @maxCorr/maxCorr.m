classdef maxCorr < handle
    % Find maximally correlating components.
    %
    % This object is used for finding components that maximise
    % correlation in certain data set(s) (e.g. in a data set for a certain
    % subject) while simultaneously minimizing correlation in some
    % other data sets (e.g. in data sets of the other subjects).
    %
    % The object can be constructed in the following ways:
    % mc = maxCorr(func, udata, N)
    %   func          Function called as mtx=func(udata,i,N,verbose) to
    %                 return the data matrix mtx for i:th subject (e.g. by
    %                 loading the data from disk). Verbose is a true/false
    %                 flag giving the currently set verbose mode of
    %                 the maxCorr object.
    %   udata         User data relayed to the loading-function func.
    %   N             Number of separate data sets (= parts).
    % mc = maxCorr(mtx)
    %   mtx           2D (= single data set) or 3D matrix (= multiple
    %                 data sets indexed by the third dimension).
    %
    % maxCorr class properties:
    %   N             Number of separate data sets, parts (e.g. subjects)
    %
    % maxCorr class methods:
    %   calcER2       Compute the expected R-squared value.
    %   clear         Clear the cache contents.
    %   copyright     Return the copyright string.
    %   getPart       Loads a single part of multi-part data.
    %   maxComponents Return the maximum number of meaningful components.
    %   prepare       Set the voxel-wise weights.
    %   separate      Find separating components.
    %   setCommonRegressors
    %                 Set common regressors removed from all data sets.
    %   setIndividualRegressors
    %                 Set individual regressors removed from data sets.
    %   verbose       Set/get verbose mode.
    %   version       Return the version number of the maxCorr object.
    %
    % Example usage:
    % --------------
    % Create a sample random data set of size 100 x 1000 x 10
    % >> R = random('norm',0,1,100,1000,10);
    % Create a maxCorr object
    % >> mc = maxCorr(R);
    % Find components that maximise the squared correlation in the first
    % (out of 10) "subjects" while minimising the squared correlation
    % through-out the other "subjects".
    % >> [U,S] = mc.separate([1 -ones(1,mc.N-1)]);
    % U(:,1) is the 100-elements long component that maximises
    % the squared correlation, producing value S(1). U(:,2) produces
    % the second largest squared correlation, and so on.
    %
    
    % 15.9.2018 Modified version by Janne K. 
    % -Accepts data with different signal count (e.g., voxels). Estimation of relevant component count is based on mean signal count.
    % -Additional cleaning of code
    
    properties (SetAccess = private)
        N          % Number of blocks/subjects etc.
    end
    properties (SetAccess = private, GetAccess = private)
        loadFunc   % Function handle to load data (userData,i,N,verb)
        userData   % Associated user data
        sdata      % single data set
        data_size  % size of single data set
        data_type  % float type used
        XXt        % Preprocessed data
        CR         % Common regressors
        IR         % Individual regressors
        verb       % Verbose mode
        W          % Weights inside each subject        
    end
    
    methods
        function obj=maxCorr(f,udata,N)
            maxCorr.showCopy();
            obj.verb=false;
            obj.CR = [];
            obj.IR = [];
            obj.W = [];
            obj.data_size = [];
            obj.data_type = 'double';
            if (isa(f,'function_handle'))
                obj.loadFunc = f;
                if (nargin<2) udata = []; end;
                if (nargin<3) N = 1; end;
                obj.userData = udata;
                obj.N = N;
            elseif (isa(f,'maxCorr'))
                error('Don''t know what to do with another maxCorr object.');
            elseif (ndims(f)==3) % 3D matrix
                obj.loadFunc = @maxCorr.load3D;
                obj.userData = f;
                obj.N = size(f,3);
            elseif (isa(f,'msMatrix') || isnumeric(f))
                obj.sdata = f;
                obj.N = 1;
            else
                error('Don''t know what to do with the given data/object.');
            end
        end
        function delete(obj)
            ;
        end
        function v=verbose(obj,v)
            % v = obj.verbose(v)
            %
            % Sets the verbose mode to v (true/false) if given. Returns the
            % current verbose mode.
            if (nargin>1), obj.verb=v; end;
            v=obj.verb;
        end
        function obj=clear(obj)
            % obj = obj.clear()
            %
            % Clears the internal caching.
            obj.XXt = [];
            obj.data_size = [];
            obj.W = [];
        end
        function setCommonRegressors(obj,R)
            % obj.setCommonRegressors(R)
            %
            % Sets the common regressors (in matrix R) already removed from
            % all data sets. This setting guarantees that correlations to
            % these regressors are not introduced in the projections.
            obj.clear();
            obj.CR = obj.normalizeRegressors(R);
        end
        function setIndividualRegressors(obj,R)
            % obj.setIndividualRegressors(R)
            %
            % Set the individual regressors (in 3D matrix R) already
            % removed from the different data-sets. This setting guarantees
            % that correlations to these regressors are not introduced in
            % the projections.
            obj.clear();
            obj.IR = obj.normalizeRegressors(R);
        end
        
        obj = prepare(obj,W);
        d = getPart(obj,i);
        [U,S]=separate(obj,W,limn,tol,NullModel);
        n = maxComponents(obj);
    end
    
    methods (Static)
        d = normalize(d);
        d = normalizeRegressors(d,compr);
        v = version();
        c = copyright();
        r2 = calcER2(ND);
        function d=load3D(mtx,i,N,verbose)
            if (verbose),
                fprintf(1,'Reading data for subject %d/%d (from 3D matrix).\n',i,N);
            end
            d=squeeze(mtx(:,:,i));
        end
    end
    
    methods (Static, Access='private')
        function showCopy()
            persistent initialized;
            if isempty(initialized)
                initialized = true;
                fprintf(1, maxCorr.copyright());
            end
        end
    end
    
end
