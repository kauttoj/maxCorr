function wait_for_jobs(CONFIGFILES,jobnames,jobfiles,lognames,STAGE)
% This function monitors progress of jobs and resubmits failed jobs if
% necessary. Status of each cfg file must be valid to mark it completed. If
% there are too many failed submissions, we crash (check logs to solve).

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

POLL_DELAY = 20;
TIMES_TO_TRY = 5;
RESUBMIT_DELAY = 30;
resubmit_delays = zeros(1,N_files);

starttime = tic();
LAST_PRINTOUT = 0;

while 1
    pause(POLL_DELAY);
    for i = 1:N_files
        done_files(i) = check_stage(i,CONFIGFILES,STAGE);
    end
    for i = 1:N_files        
        if done_files(i)==0
            FAILED=0;
            [job_state,job_message]=system(['qstat -f ',jobnames{i}]);            
            if job_state==153
                FAILED = 1; % job is not complete and not in queue, it has failed
            end            
            if FAILED>0
                % due to delays, check the status again
                done_files(i) = check_stage(i,CONFIGFILES,STAGE);
                if done_files(i)==0
                    if resubmit_count(i)<TIMES_TO_TRY
                        d = resubmit_delays(i)+toc(starttime);
                        if d > RESUBMIT_DELAY
                            resubmit_count(i)=resubmit_count(i)+1;
                            fprintf('FAILED with state code %i, resubmitting job ''%s'' (message: %s, %ith time, delay %is)\n',job_state,jobfiles{i},job_message,resubmit_count(i),round(d));

							copyfile(lognames{i},[lognames{i},'_failed_nr',num2str(resubmit_count(i))]);

                            [notused,jobnames{i}] = system(['sbatch ' jobfiles{i}]);
                            resubmit_delays(i)=-toc(starttime);
                        end
                    else
                        error('Tried to submit job %s over %i times, cannot continue processing!',jobfiles{i},TIMES_TO_TRY);
                    end
                end
            end
        end
    end
    
    if sum(done_files)==length(done_files)
        break;
    end
    TOT_time = toc(starttime);
    if TOT_time/60/60 > 2
        error('Aborted after waiting over 2h for jobs to finish :(');
    end
    if TOT_time - LAST_PRINTOUT > 60
        fprintf('...%i jobs completed and %i jobs resubmitted (of total %i)\n',nnz(done_files),nnz(resubmit_count),N_files);
        LAST_PRINTOUT=TOT_time;
    end
end

fprintf('... All %i jobs completed!\n',nnz(done_files));

end

function ISDONE = check_stage(i,CONFIGFILES,STAGE)

    count = 0;
    ISDONE = 0;
    while 1
        try
            count = count + 1;
            A=load(CONFIGFILES{i});
            break;
        catch err
            pause(2);
            if count>5
                error('Failed to read CFG file ''%s'' (%s)!',CONFIGFILES{i},err.message);
            end
        end
    end
    if A.stage == STAGE
        ISDONE=1;
    end

end

