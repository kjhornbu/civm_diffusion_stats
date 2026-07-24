function [status]=process_command_queue(composite_queue)

task_list=composite_queue.values();
condensed_task_list=vertcat(task_list{:});

task_idxs=randperm(numel(condensed_task_list));
task_cells={condensed_task_list(task_idxs).command};
task_count=numel(task_cells);

output={condensed_task_list(task_idxs).outfiles};
input={condensed_task_list(task_idxs).infiles};

status=false(1,task_count);

parfor i_task=1:task_count
    if isa(task_cells{i_task},'char')
        if not( file_time_check(output{i_task},'same',input{i_task}) )
            try
                [s,sout]=system(task_cells{i_task});
                if s~=0
                    warning('task %i/%i failed with error: %s',i_task,task_count,sout);
                else
                    status(i_task)=true;
                end
            catch merr
                warning(merr.identifier,'task %i/%i failed with error: %s',i_task,task_count,merr.message);
            end
        else
            status(i_task)=true;
        end
    end
end

%reorder status back to loading order
status=status(task_idxs);

end