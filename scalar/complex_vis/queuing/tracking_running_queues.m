function [function_success] = tracking_running_queues(plot_queue,composite_queue)


function_success=process_function_queue(plot_queue);
fraction_success=sum(function_success)./numel(function_success);

stop_too_many=5;
while any(~function_success) && stop_too_many>0 && fraction_success>0.7
    function_success=process_function_queue(plot_queue);
    fraction_success=sum(function_success)./numel(function_success);
    stop_too_many=stop_too_many-1;
end

warning('deactivated all svg checking and copositing because of inkscape conversion fails');
return;

% put command success in output once running this.

command_success=process_command_queue(composite_queue);
fraction_success=sum(command_success)./numel(command_success);

stop_too_many=5;
while any(~command_success) && stop_too_many>0 && fraction_success>0.7
    command_success=process_command_queue(composite_queue);
    fraction_success=sum(command_success)./numel(command_success);
    stop_too_many=stop_too_many-1;
end

end