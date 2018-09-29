function [jobname,logfile] = maxCorr_sendjob(filename,paramfile,codepath,funfile)

logfile = [filename,'_log'];

dlmwrite(filename, '#!/bin/sh', '');
dlmwrite(filename, '#SBATCH -p batch','-append','delimiter','');
dlmwrite(filename, '#SBATCH -t 00:30:00','-append','delimiter','');
dlmwrite(filename, '#SBATCH -c 1','-append','delimiter','');
dlmwrite(filename, '#SBATCH --qos=normal','-append','delimiter','');
dlmwrite(filename, ['#SBATCH -o "' logfile '"'],'-append','delimiter','');
dlmwrite(filename, '#SBATCH --mem=25000','-append','delimiter','');
dlmwrite(filename, 'module load matlab','-append','delimiter','');
dlmwrite(filename,sprintf('srun matlab -nosplash -nodisplay -nodesktop -r "cd(''%s'');fprintf('' current path: %%s '',pwd());%s(''%s'');exit;"',codepath,funfile,paramfile),'-append','delimiter','');

[a,b]=unix(['sbatch ' filename]);
s = 'Submitted batch job ';
k = strfind(b,s);
if ~isempty(s)
    jobname = strtrim(b(length(s):end));
else
    jobname = 'unknown';
end
%eval(sprintf('%s(''%s'')',funfile,paramfile));

end

