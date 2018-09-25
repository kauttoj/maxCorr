function maxCorr_compute_covariance(cfg_file)
% similar to maxCorr.prepare, but for individual subject
    CFG = load(cfg_file);
        
    addpath(CFG.cfg.maxCorr_path);
    
    N = length(CFG.cfg.filenames);
    
    fprintf('starting with subject %i of %i (%s)\n',CFG.cfg.process_index,N,datestr(datetime('now')));   
    
    obj=maxCorr(@maxCorr_fMRI_dataloader,CFG.cfg,N);
    
    d = obj.getPart(CFG.cfg.process_index);

    % compute (unscaled) covariance matrix
    try
        XXt = d*d';
    catch
        blocks = 1000;               
        loops = ceil(data_size(2)/blocks);
        if (isa(d, 'single'))
            XXt = zeros(data_size(1),data_size(1), 'single');
        else
            XXt = zeros(data_size(1),data_size(1));
        end
        endBlock = 0;
        for nblock = 1:loops
            startBlock = endBlock + 1;
            endBlock = min([endBlock + blocks, data_size(2)]);
            XXt = XXt + (d(:,startBlock:endBlock)*d(:,startBlock:endBlock)');
        end
    end
    
    data_size=size(d);
    data_type=class(d);
            
    save(CFG.cfg.filenames(CFG.cfg.process_index).covfile,'XXt','data_size','data_type');
    
    fprintf('finished with subject %i of %i (%s)\n',CFG.cfg.process_index,N,datestr(datetime('now')));      
    
    CFG.stage = 1;
    
    save_cfg(CFG.cfg.filenames(CFG.cfg.process_index).cfgfile,CFG.cfg,CFG.stage);
    
end

function save_cfg(filename,cfg,stage)

save(filename,'cfg','stage','-v7.3');

end

