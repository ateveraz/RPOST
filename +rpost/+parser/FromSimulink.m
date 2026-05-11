classdef FromSimulink

    properties (Access = public)
        dataset
    end

    properties (Access = private)
        json_settings
        var_names_cell
        exp_names_cell
        exp_datas_cell
        colors_cell
        labels_cell
        lineStyle_cell
        bus_name
    end
    
    methods (Access = public)
        function obj = FromSimulink(options)
            arguments
                options.var_names_json string = ""
                options.exp_datas_cell cell = {}
                options.bus_name string = ""
            end

            if isempty(options.var_names_json)
                error("Please provide a JSON file with the variable names to extract from the Simulink output.");
            end

            if isempty(options.exp_datas_cell)
                error("Please provide a cell array with the data of the experiments corresponding to the Simulink outputs.");
            end
 
            obj = readJson(obj, options.var_names_json); 

            if length(obj.exp_names_cell) ~= length(options.exp_datas_cell)
                error("The number of experiment names must match the number of Simulink outputs provided.");
            end
            obj.bus_name = options.bus_name;            
            obj.dataset = obj.loadBatch(options.exp_datas_cell); 

        end
    end

    methods (Access = private)
        function dataset = loadBatch(obj, datas_cell)
            n_exp = length(obj.exp_names_cell);
            
            dataset = struct;

            use_bus_name = ~isempty(obj.bus_name);
            
            for i = 1:n_exp
                data_exp = struct;
                exp_name = obj.exp_names_cell{i};
                if use_bus_name
                    data_exp.data = getFromSimulinkBus(obj, datas_cell{i}, obj.bus_name);
                else
                    data_exp.data = getFromSimulinkOutput(obj, datas_cell{i});
                end    
                data_exp.metadata = getMetadata(obj, i);
                dataset.(exp_name) = data_exp;
            end
        end

        function data = getFromSimulinkOutput(obj, simu)
                N = length(obj.var_names_cell);
                data = struct;

                data.('t') = simu.tout;
                
                for i = 1:N
                    try 
                        temp = squeeze(getElement(simu.logsout,obj.var_names_cell{i}).Values.Data);
                        [n,m,z] = size(temp);
                        
                        if z > n && z > m
                            temp = permute(temp, [3, 1, 2]);
                            temp = reshape(temp, z, n*m);
                            [n,m] = size(temp);
                        end

                        if m > n
                            temp = temp';
                        end
                        data.(obj.var_names_cell{i}) = temp;
                    catch
                        warning("Variable '%s' not found in Simulink output. Skipping.", obj.var_names_cell{i});
                    end
                end
        end

        function data = getFromSimulinkBus(obj, simOut, busName)
            % 1. Get the main bus structure
            try
                busSignal = simOut.yout.get(busName);
                mainStruct = busSignal.Values;
            catch
                error('Bus "%s" not found in out.yout', busName);
            end
            
            % 2. Loop through requested variables
            foundTimeVector = false;
            
            for i = 1:length(obj.var_names_cell)
                targetName = obj.var_names_cell{i};
                
                % Recursively search for the signal anywhere in the struct
                foundObj = obj.findRecursive(mainStruct, targetName);
                
                if ~isempty(foundObj)

                    % Extract Time (only need to do this once)
                    if ~foundTimeVector
                        data.t = foundObj.Time;
                        foundTimeVector = true;
                    end

                    % Extract data
                    data.(targetName) = squeeze(foundObj.Data);

                    % The data must be a vector NxM, where N is the number of time steps and M is the number of variables (M=1 for scalar signals). If it is a matrix, we need to reshape it to be NxM.
                    [n,m,z] = size(data.(targetName));
                    if z > n && z > m
                        data.(targetName) = permute(data.(targetName), [3, 1, 2]);
                        data.(targetName) = reshape(data.(targetName), z, n*m);
                        warning('Data for variable "%s" was 3D. Reshaping to 2D with size [%d x %d].', targetName, z, n*m);
                    end

                    if m > n && z == 1
                        data.(targetName) = permute(data.(targetName), [2, 1]);
                    end

                else
                    warning('Variable "%s" was not found in any sub-bus of "%s".', ...
                        targetName, busName);
                    data.(targetName) = [];
                end
            end
        end

        function result = findRecursive(obj, currentStruct, targetName)
            % Helper function to search deeply through nested structs
            result = [];
            
            % 1. Check if the target is a direct field of the current struct
            if isfield(currentStruct, targetName)
                candidate = currentStruct.(targetName);
                % Ensure it is a timeseries (a leaf), not a sub-bus (struct)
                if isa(candidate, 'timeseries')
                    result = candidate;
                    return;
                end
            end
            
            % 2. If not found, dive into every field that is a struct (sub-bus)
            fieldNames = fieldnames(currentStruct);
            for k = 1:numel(fieldNames)
                fieldVal = currentStruct.(fieldNames{k});
                
                if isstruct(fieldVal)
                    % RECURSION: Dive deeper
                    result = obj.findRecursive(fieldVal, targetName);
                    
                    % If found in the deep dive, stop looking and return it
                    if ~isempty(result)
                        return;
                    end
                end
            end
        end

        function obj = readJson(obj, json_path)
            obj.json_settings = jsondecode(fileread(json_path));
            obj.var_names_cell = obj.json_settings.var_names;
            obj.exp_names_cell = obj.json_settings.exp_names;
            obj.colors_cell = obj.json_settings.colors;
            obj.labels_cell = obj.json_settings.labels;
            obj.lineStyle_cell = obj.json_settings.lineStyles;
        end

        function metadata = getMetadata(obj, i)
            metadata = struct;
            metadata.color = obj.colors_cell{i};
            metadata.label = obj.labels_cell{i};
            metadata.LineStyle = obj.lineStyle_cell{i};
        end



    end
end