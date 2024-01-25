% ------
% process dynamic experinments and get data for future analysis
% ------
% Input:
%     None
% Output(data files for the 5 dynamic experiments):
%     data_app_vm_stats_dynexp08.mat
%     data_app_vm_stats_dynexp10.mat
%     data_app_vm_stats_dynexp11.mat
%     data_app_vm_stats_dynexp12.mat
%     data_app_vm_stats_dynexp13.mat

function get_data_dyn_exp_release()

% Experimental reuslts directory
dir_name_exps_all = ["./exp_results_dyn/exp_v08/";...
"./exp_results_dyn/exp_v10/";...
"./exp_results_dyn/exp_v11/";...
"./exp_results_dyn/exp_v12/";...
"./exp_results_dyn/exp_v13/"];

for i_exp = 1:length(dir_name_exps_all)

dir_name_exps = dir_name_exps_all(i_exp);
listing = dir(dir_name_exps);
dir_name_machine = string([]);
for i = 1:length(listing)
    if listing(i).isdir == 1
        dir_name_machine = [dir_name_machine;listing(i).name];
    end
end

% This is the time difference between VMs and the node, it is based on
% observation and manualy gegenerated
load data/data_mean_time_diff.mat


% Initialize results colection cell variable
results_col_ws_all = {};
results_col_ds_all = {};
results_col_inmem_all = {};
results_col_ms_all = {};
results_col_redis_all = {};

for vm_index = 1:5
    
    time_diff = mean_time_diff(vm_index);
    results_col_ws = [];
    results_col_ds = [];
    results_col_inmem = [];
    results_col_ms = [];
    results_col_redis = [];
    
    vm_dir = strcat(dir_name_exps,dir_name_machine(vm_index+3),'/');
    listing_vm01 = dir(strcat(vm_dir,'vm*'));
    
    i = 1;
    while i < length(listing_vm01)
        name_list = listing_vm01(i).name;
        name_split = split(name_list,["_","."]);

        if strcmp(name_split{4},'app01') %WS
            %Result processing
            stats_file_name = listing_vm01(i+2).name;
            S = readstruct(strcat(vm_dir,stats_file_name));
            name_split = split(stats_file_name,["_","."]);
            ts_config = str2num(name_split{2, 1}(3:end));
            te_config = str2num(name_split{3, 1}(3:end));
            %Result collection
            if S.driverSummary.responseTimes.operation(3).nameAttribute == "PostSelfWall"
                results_ws = [ts_config,...
                    te_config,...
                    S.driverSummary.users,...
                    S.driverSummary.responseTimes.operation(3).avg,...
                    S.driverSummary.responseTimes.operation(3).max,...
                    S.driverSummary.responseTimes.operation(3).sd,...
                    S.benchSummary.metric.Text];
            else
                error('Cannot find PostSelfWall');
            end
            %Result collection
            results_col_ws(end+1,:) = results_ws;
            %Increase i
            i = i+3;
        elseif strcmp(name_split{4},'app02') %MS
            string_to_find = 'Request rate:';
            stats_file_name = listing_vm01(i+7).name; %last one
            ts_config = str2num(name_split{2, 1}(3:end));
            te_config = str2num(name_split{3, 1}(3:end));
            find_note=[];
            fid = fopen(strcat(vm_dir,stats_file_name));
            tline = fgetl(fid);
            while ischar(tline)
                find_note=strfind(tline, string_to_find);
                if isempty(find_note)
                    tline = fgetl(fid);
                else
                    break
                end
            end
            fclose(fid);
            results_line_break = split(tline," ");
            result = str2num(results_line_break{3, 1});
            %Result collection
            results_col_ms(end+1,:) = [ts_config, te_config, result];
            %Increase i
            i = i+8;
        elseif strcmp(name_split{4},'app03') % InMem
            string_to_find = 'Benchmark execution time:';
            ts_config = str2num(name_split{2, 1}(3:end));
            te_config = str2num(name_split{3, 1}(3:end));
            find_note=[];
            fid = fopen(strcat(vm_dir,name_list));
            tline = fgetl(fid);
            while ischar(tline)
                find_note=strfind(tline, string_to_find);
                if isempty(find_note)
                    tline = fgetl(fid);
                else
                    break
                end
            end
            fclose(fid);
            if tline ~= -1
                results_line_break = split(tline," ");
                result = str2num(results_line_break{4, 1}(1:end-2));
                %Result collection
                results_col_inmem(end+1,:) = [ts_config, te_config, result];
            else
                warning('Bad inmem statistic data')
                disp(name_list);
            end
            %Increase i
            i = i+1;
        elseif strcmp(name_split{4},'app04') %DS
            %Result processing
            string_to_find = '[OVERALL], RunTime(ms)';
            operation_count_config = str2num(name_split{5, 1}(3:end));
            ts_config = str2num(name_split{2, 1}(3:end));
            te_config = str2num(name_split{3, 1}(3:end));
            find_note=[];
            fid = fopen(strcat(vm_dir,name_list));
            tline = fgetl(fid);
            while ischar(tline)
                find_note=strfind(tline, string_to_find);
                if isempty(find_note)
                    tline = fgetl(fid);
                else
                    break
                end
            end
            fclose(fid);
            results_line_break = split(tline,",");
            result = str2num(results_line_break{3, 1});
            %Result collection
            results_col_ds(end+1,:) = [ts_config, te_config, operation_count_config, result];
            %Increase i
            i = i+1;
        elseif strcmp(name_split{4},'app05') %Redis
            %Result processing
            result = [];
            string_to_find = 'requests per second';
            ts_config = str2num(name_split{2, 1}(3:end));
            te_config = str2num(name_split{3, 1}(3:end));
            find_note=[];
            fid = fopen(strcat(vm_dir,name_list));
            tline = fgetl(fid);
            while ischar(tline)
                find_note=strfind(tline, string_to_find);
                if ~isempty(find_note)
                    results_line_break = split(tline," ");
                    result(end+1) = str2num(results_line_break{1, 1});
                end
                tline = fgetl(fid);
            end
            fclose(fid);
            
            %Result collection
            results_col_redis(end+1,:) = [ts_config, te_config, mean(result)];
            %Increase i
            i = i+1;
        else
            error('Wrong app type')
        end
    end
    
    results_col_ws_all{vm_index,1} = results_col_ws;
    results_col_ds_all{vm_index,1} = results_col_ds;
    results_col_inmem_all{vm_index,1} = results_col_inmem;
    results_col_ms_all{vm_index,1} = results_col_ms;
    results_col_redis_all{vm_index,1} = results_col_redis;
    
    vm_stats = importdata(strcat(dir_name_exps,dir_name_machine(3),'/output_hdr/node1_vm0',num2str(vm_index),'_dr_stat.csv'));
    vm_stats_data = vm_stats.data;
    disp(strcat('vm',num2str(vm_index),':','ws'))
    [results_col_ws_all{vm_index,2},results_col_ws_all{vm_index,3}] = sub_get_vm_stats_v2_release(vm_stats_data,results_col_ws,time_diff);
    disp(strcat('vm',num2str(vm_index),':','ds'))
    [results_col_ds_all{vm_index,2},results_col_ds_all{vm_index,3}] = sub_get_vm_stats_v2_release(vm_stats_data,results_col_ds,time_diff);
    disp(strcat('vm',num2str(vm_index),':','inmem'))
    [results_col_inmem_all{vm_index,2},results_col_inmem_all{vm_index,3}] = sub_get_vm_stats_v2_release(vm_stats_data,results_col_inmem,time_diff);
    disp(strcat('vm',num2str(vm_index),':','ms'))
    [results_col_ms_all{vm_index,2},results_col_ms_all{vm_index,3}] = sub_get_vm_stats_v2_release(vm_stats_data,results_col_ms,time_diff);
    disp(strcat('vm',num2str(vm_index),':','redis'))
    [results_col_redis_all{vm_index,2},results_col_redis_all{vm_index,3}] = sub_get_vm_stats_v2_release(vm_stats_data,results_col_redis,time_diff);
    
end
dir_name_exps_char = char(dir_name_exps);
save(strcat('data_app_vm_stats_dynexp',dir_name_exps_char(end-2:end-1),'.mat'),'results_col_*_all')

end
