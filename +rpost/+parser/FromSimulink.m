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
    end
    
    methods (Access = public)
        function obj = FromSimulink(options)
            arguments
                options.var_names_json string = ""
                options.exp_datas_cell cell = {}
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

            obj.dataset = obj.loadBatch(options.exp_datas_cell); 

        end
    end

    methods (Access = private)
        function dataset = loadBatch(obj, datas_cell)
            n_exp = length(obj.exp_names_cell);
            
            dataset = struct;
            
            for i = 1:n_exp
                data_exp = struct;
                exp_name = obj.exp_names_cell{i};
                data_exp.data = getFromSimulinkOutput(obj, datas_cell{i});
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