% ------
% subfunction to select VM metrics
% ------
% Input:
%   vm_stats_data: VM metrics data
%   results_col: Applicaiton data variable
%   time_variance: time variance between the VM and node
% Output:
%   vm_statistics_mean: Average VM metrics
%   vm_statistics_sum: Cumulative VM metrics

function [vm_statistics_mean,vm_statistics_sum] = sub_get_vm_stats_v2_release(vm_stats_data,results_col,time_variance)
vm_stats_data_sep = {};
vm_statistics_mean = [];
vm_statistics_sum = [];

for i = 1:length(results_col(:,1))
    vm_ts = find(vm_stats_data(:,1)/1e9>(results_col(i,1)+time_variance),1);
    vm_te = find(vm_stats_data(:,1)/1e9>(results_col(i,2)+time_variance),1);
    
    margin_time = 6;
    find_note_ts = find(vm_stats_data(vm_ts-margin_time:vm_ts+margin_time,2)>10,1);
    vm_ts_stats = vm_ts-margin_time+find_note_ts-1;
    
    %Change margin_time for small execution time tasks
    if vm_te - vm_ts < 12
        margin_time = round(0.5*(vm_te - vm_ts));
    end
    find_note_te = find(vm_stats_data(vm_te-margin_time:vm_te+margin_time,2)<10,1);
    vm_te_stats = vm_te-margin_time+find_note_te-1-1;
    
    vm_stats_data_sep{i,1} = vm_stats_data(vm_ts_stats:vm_te_stats,:);
%     plot(vm_stats_data(vm_ts_stats:vm_te_stats,2))
%     pause(0.01)
    vm_statistics_mean(end+1,:) = mean(vm_stats_data_sep{i},1);
    vm_statistics_sum(end+1,:) = sum(vm_stats_data_sep{i},1);
end
end