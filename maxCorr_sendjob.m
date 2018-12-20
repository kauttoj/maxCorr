function [jobname,logfile] = maxCorr_sendjob(filename,paramfile,codepath,funfile,doLocal)
% write and send job (or run locally)

if nargin<5
    doLocal=0;
end

logfile = [filename,'_log'];

dlmwrite(filename, '#!/bin/sh', '');
dlmwrite(filename, '#SBATCH -p batch','-append','delimiter','');
dlmwrite(filename, '#SBATCH -t 03:00:00','-append','delimiter','');
dlmwrite(filename, '#SBATCH -N 1','-append','delimiter','');
dlmwrite(filename, '#SBATCH -n 1','-append','delimiter','');
dlmwrite(filename, '#SBATCH --qos=normal','-append','delimiter','');
dlmwrite(filename, ['#SBATCH -o "' logfile '"'],'-append','delimiter','');
dlmwrite(filename, '#SBATCH --mem-per-cpu=25000','-append','delimiter','');
dlmwrite(filename, 'hostname; date;','-append','delimiter','');
dlmwrite(filename, 'module load matlab','-append','delimiter','');
dlmwrite(filename,sprintf('srun matlab -nosplash -nodisplay -nodesktop -r "cd(''%s'');fprintf('' current path: %%s '',pwd());%s(''%s'');exit;"',codepath,funfile,paramfile),'-append','delimiter','');

jobname = 'unknown';

if doLocal==1
    %%%% FOR TESTING AND DEBUGGING ONLY - run locally in serial manner
    command = sprintf('%s(''%s'');',funfile,paramfile);
    eval(command);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    [a,b]=unix(['sbatch ' filename]);
    s = 'Submitted batch job ';
    k = strfind(b,s);
    if ~isempty(k)
        jobname = strtrim(b(length(s):end));
    end
end

end

