classdef FromFlAIR
    % FromFlAIR is a class that loads the data from the FlAIR datalog and computes the metrics and energy.
    
    properties (Access = public)
        dataset
    end

    properties (Access = private)
        path_file_txt
        path_file_csv

        folder_name
        json_settings
        nicknames
        logging

        experiments

        useWorldFrame
    end
    
    methods
        function obj = FromFlAIR(settings, options)
            arguments
                settings string
                options.use_world_frame logical = false
            end
            obj.json_settings = jsondecode(fileread(settings));

            obj.logging = obj.json_settings.logging;
            obj.experiments = obj.json_settings.experiments;
            obj.nicknames = fieldnames(obj.logging);
            obj.useWorldFrame = options.use_world_frame;

            obj.dataset = obj.loadBatch();
        end

        function data = load(obj, folder_name, params)
            if nargin < 2
                params = struct;
                params.offset = 0;
            end

            obj = define_paths(obj, folder_name);
            data = getRequiredSignals(obj, params);

            data.rpy = getRPY(obj, data);
        end

        function batch = loadBatch(obj)

            batch = struct;

            for i = 1:length(obj.experiments)
                data_experiment = struct;
                data_experiment.data = load(obj, obj.experiments(i).folder_path, obj.experiments(i));

                if(obj.useWorldFrame)
                    data_experiment.data = hardConvertWorldFrame(obj, data_experiment.data);
                end

                data_experiment.metadata = obj.experiments(i);
                batch.(obj.experiments(i).name) = data_experiment;
            end
        end
    end

    methods (Access = private)
        function obj = define_paths(obj, folder_name)
            obj.folder_name = folder_name;
            obj.path_file_txt = strcat(folder_name,'/all_logs.txt');
            obj.path_file_csv = strcat(folder_name,'/all_logs.csv');
        end

        function desiredSignals = getDesiredSignals(obj)
            num_signals = length(obj.nicknames);

            desiredSignals = cell(1,num_signals);

            for i = 1:num_signals
                desiredSignals{i} = obj.logging.(obj.nicknames{i});
            end

            desiredSignals = cat(1, desiredSignals{:});
        end

        function data_raw = readLogging(obj)
            desired_signals = getDesiredSignals(obj);

            num_signals = length(desired_signals);

            [all_labels, all_values] = obj.readFiles();

            textAsCells = regexp(all_labels, '\n', 'split');

            size_raw = size(all_values);
            data_raw = zeros(size_raw(1),num_signals);
            
            for i = 1:num_signals
                try 
                    mask = ~cellfun(@isempty, strfind(textAsCells, desired_signals{i}));
                    the_one_line = textAsCells(mask);
                    b = regexp(the_one_line{1},'\d*','Match');
                    data_raw(:,i) = all_values(:,str2double(b(1)));
                catch
                    error('Signal %s not found in the log files.', desired_signals{i});
                end
            end
        end

        function [all_labels, all_values] = readFiles(obj)
            all_labels = fileread(obj.path_file_txt);
            all_values = readmatrix(obj.path_file_csv);
        end

        function data = getRequiredSignals(obj, params)

            data_raw = readLogging(obj);

            data = struct;

            init = 1;
            first = true;
            %mask_time = [];

            for i = 1:length(obj.nicknames)
                signal_size = length(obj.logging.(obj.nicknames{i})); 
                if first
                    data.(obj.nicknames{i}) = (data_raw(:,1) - data_raw(1,1))/1e6 - params.offset(1);

                    if params.customTime(1)
                        if params.end(1) < params.start(1)
                            params.end(1) = data.(obj.nicknames{i})(end);
                        end
                        mask_time = data.(obj.nicknames{i}) >= params.start(1) & data.(obj.nicknames{i}) <= params.end(1);
                        data.(obj.nicknames{i}) = data.(obj.nicknames{i})(mask_time) - params.start(1);
                    end
                    first = false;
                else
                    if params.customTime(1)
                        data.(obj.nicknames{i}) = [data_raw(mask_time,init:init+signal_size-1)];
                    else
                        data.(obj.nicknames{i}) = [data_raw(:,init:init+signal_size-1)];
                    end
                end
                init = init + signal_size;
            end
        end

        function data = hardConvertWorldFrame(obj, data)
            % Convert the position and velocity to the world frame by inverting the y and z axes.
            data.x(:,2) = -data.x(:,2); % Invert y-axis for position
            data.x(:,3) = -data.x(:,3); % Invert z-axis for position
        end

        function metrics = computeMetrics(~, t, error)
            % Compute the metrics given the time and the error. 
            metrics = struct;

            dt = mean(diff(t));

            metrics.iae = cumsum(sum(abs(error),2).*dt);
            metrics.ise = cumsum(sum(error.^2,2).*dt);
            metrics.itae = cumsum(sum(t.*abs(error),2).*dt);
            metrics.itse = cumsum(sum(t.*error.^2,2).*dt);
        end

        function energy = computeEnergy(~, t, u, w)
            % Compute the energy given the time and the control input. 
            energy = struct;

            dt = mean(diff(t));

            energy.control = cumsum(sum(u.^2,2).*dt);
            energy.total = cumsum(sum(abs(u.*w),2).*dt);
        end     
        
        function output = getRPY(~, data)
            [n, ~] = size(data.q);
            rpy = zeros(n, 3);

            for i = 1:n
                rpy(i,:) = quat2rpy(data.q(i,:));
                temp = quat2rpy(data.q_v(i,:));
                rpy(i,3) = temp(3);
            end

            output = rpy*180/pi;
        end
    end
end
