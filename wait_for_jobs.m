function wait_for_jobs(CONFIGFILES,jobnames,jobfiles,STAGE)

if ~iscell(CONFIGFILES)
    temp{1} = CONFIGFILES;
    CONFIGFILES = temp;
end

N_files = length(CONFIGFILES);

if N_files==0
    return;
end

done_files = zeros(1,N_files);
resubmit_count = zeros(1,N_files);

pause(30);

POLL_DELAY = 30;
TIMES_TO_TRY = 10;
RESUBMIT_DELAY = 60;
resubmit_delays = zeros(1,N_files);
PRINTOUT = 2*60;

starttime = tic;

TOT_time = 0;
while 1
    pause(POLL_DELAY);
    TOT_time = TOT_time + POLL_DELAY;
    ISDONE=1;
    for i = 1:N_files
        count = 0;
        while 1
            try
                count = count + 1;
                A=load(CONFIGFILES{i});
                break;
            catch err
                pause(3);
                if count>10
                    error('Failed to read CFG file ''%s'' (%s)!',CONFIGFILES{i},err.message);
                end
            end
        end
        if A.stage < STAGE
            ISDONE=0;
        else
            done_files(i) = 1;       
        end
    end
    for i = 1:N_files
        
        if done_files(i)==0
            
            FAILED=0;
            [job_state,job_message]=system(['qstat -f ',jobnames{i}]);
            
            if job_state==153
                FAILED = 1; % job is not complete and not in queue, it has failed
            end
            
            if FAILED>0
                if resubmit_count(i)<TIMES_TO_TRY
                    if resubmit_delays(i)+toc(starttime) > RESUBMIT_DELAY
                        resubmit_count(i)=resubmit_count(i)+1;
                        fprintf('FAILED code was %i, job state code was %i, resubmitting job for file %i (%ith time, delay %is)\n',FAILED,job_state,i,resubmit_count(i),round(resubmit_delays(i)));
                        [notused,jobnames{i}] = system(['qbatch ' jobfiles{i}]);
                        resubmit_delays(i)=-toc(starttime);
                    end
                else
                    error('Tried to submit job %s over %i times, cannot continue processing!',jobfiles{i},TIMES_TO_TRY);
                end
            end
        end
    end
    
    if ISDONE==1
        break;
    end
    if TOT_time/60/60 > 2
        error('Aborted after waiting over 2h for jobs to finish :(');
    end
    if PRINTOUT/60 > 5
        fprintf('...%i jobs completed and %i jobs resubmitted (of total %i)\n',nnz(done_files),nnz(resubmit_count),N_files);
        PRINTOUT = 0;
    else
        PRINTOUT = PRINTOUT + POLL_DELAY;
    end
end

fprintf('... All %i jobs completed!\n',nnz(done_files));

end

