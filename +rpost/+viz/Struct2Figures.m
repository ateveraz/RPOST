classdef Struct2Figures
    properties(Access = private)
        line_width = 2;
        font_size = 15;
        colororder = 'sail';
        background_color = 0.94;
        grid_alpha = 0.9;
        axisFontSize = 10;
        grid_color = 1.0;

        xlabel_str  = 'Time [s]';
    end

    methods
        function obj = Struct2Figures(options)
            arguments
                options.line_width double = 2
                options.font_size double = 15
                options.background_color double = 0.94
                options.grid_alpha double = 0.9
                options.axisFontSize double = 10
                options.grid_color double = 1.0
            end

            obj.line_width = options.line_width;
            obj.font_size = options.font_size;
            obj.background_color = options.background_color;
            obj.grid_alpha = options.grid_alpha;
            obj.grid_color = options.grid_color;
            obj.axisFontSize = options.axisFontSize;
        end

        function obj = compare_variable(obj, axis_handle, dataset, experiment_names, var_str, options)
            %, var_dim, compute_norm, invert_y, compute_integral)
            arguments
                obj
                axis_handle % Axis handle where to plot
                dataset     % Dataset structure
                experiment_names % Cell array of experiment names to compare
                var_str     % Variable name string to plot
                options.ydim (1,:) double = 1 % Dimension of variable to plot
                options.compute_norm logical = false % Whether to compute norm of vector variable
                options.invert_y double = 1 % Whether to invert y-axis
                options.compute_integral logical = false % Whether to compute integral of variable
                options.xdata string = 't' % Optional x vector to use instead of time
                options.xdim double = 1 % Dimension of xdata to use
                options.markerStyle string = 'none' % Marker style for plots
                options.markerSkip double = 1 % Marker skip for plots
                options.same_duration logical = true % Whether to align all experiments to the shortest duration
            end

            n_experiments = length(experiment_names);
            t_min = 1e8;

            for i = 1:n_experiments
                exp_name = experiment_names{i};
                experiment = dataset.(exp_name);
                t_min = min([t_min experiment.data.t(end)]);
                signal = experiment.data.(var_str);
                y_data = signal(:, options.ydim);
                if options.compute_norm
                    norm_data = obj.compute_norm(y_data(:,options.ydim));
                    if options.compute_integral
                        dt = mean(diff(experiment.data.t));
                        norm_data = obj.compute_integral(norm_data, dt);
                    end
                    y_data = norm_data;
                end
                x_data = experiment.data.(options.xdata);
                x_data = x_data(:, options.xdim);
                obj = obj.add_1Dsignal(axis_handle, x_data, options.invert_y*y_data, experiment.metadata.label, options.markerStyle, options.markerSkip, experiment.metadata.color, experiment.metadata.LineStyle);
            end
            if options.same_duration
                xlim(axis_handle, [0 t_min]);
            end
        end

        function obj = plotXY(obj, axis_handle, dataset, experiment_names, options)
            arguments
                obj
                axis_handle
                dataset
                experiment_names
                options.xydim (1,2) double = [1 2] % Dimensions for x and y variables
                options.markerStyle string = 'none' % Marker style for plots
                options.markerSkip double = 1 % Marker skip for plots
                options.show_legend logical = true % Whether to show legend or not
            end

            n_experiments = length(experiment_names);

            hold(axis_handle, 'on');
            for i = 1:n_experiments
                exp_name = experiment_names{i};
                experiment = dataset.(exp_name);
                xy_signal = experiment.data.('x');
                x_data = xy_signal(:, 1);
                y_data = xy_signal(:, 2);
                plot(axis_handle, x_data(1:options.markerSkip:end), y_data(1:options.markerSkip:end), 'LineStyle', experiment.metadata.LineStyle, 'Color', experiment.metadata.color, 'LineWidth', obj.line_width, 'DisplayName', experiment.metadata.label);
            end

            xlabel(axis_handle, 'x [m]', 'Interpreter', 'latex', 'FontSize', obj.font_size);
            ylabel(axis_handle, 'y [m]', 'Interpreter', 'latex', 'FontSize', obj.font_size);
            grid(axis_handle, 'on');

            if options.show_legend
                legend(axis_handle, 'Interpreter', 'latex', 'FontSize', obj.font_size, 'Location', 'northeast');
            end
            
        end

        function obj = add_signals(obj, axis_handle, experiment, var_str, options)
            arguments
                obj
                axis_handle
                experiment
                var_str
                options.ydim (1,:) double = 1 % Dimension of variable to plot
                options.compute_norm logical = false % Whether to compute norm of vector variable
                options.invert_y double = 1 % Whether to invert y-axis
                options.compute_integral logical = false % Whether to compute integral of variable
                options.xdata string = 't' % Optional x vector to use instead of time
                options.xdim double = 1 % Dimension of xdata to use
                options.markerStyle string = 'none' % Marker style for plots
                options.markerSkip double = 1 % Marker skip for plots
                options.customColors cell = {} % Custom colors for multiple signals
                options.customStyleLine cell = {} % Custom line styles for multiple signals
            end

            signal = experiment.data.(var_str);
            y_data = signal(:, options.ydim);
            if options.compute_norm
                if isscalar(options.ydim)
                    norm_data = sqrt(y_data.^2);
                else
                    norm_data = obj.compute_norm(y_data(:,options.ydim));
                end
                if options.compute_integral
                    dt = mean(diff(experiment.data.t));
                    norm_data = obj.compute_integral(norm_data, dt);
                end
                y_data = norm_data;
            end
            x_data = experiment.data.(options.xdata);
            x_data = x_data(:, options.xdim);

            if ~isempty(options.customColors)
                n_signals = length(options.ydim);
                lineStyle = experiment.metadata.LineStyle;
                for j = 1:n_signals
                    if ~isempty(options.customStyleLine)
                        lineStyle = options.customStyleLine{j};
                    end
                   colorSignal = options.customColors{j};
                    obj = obj.add_1Dsignal(axis_handle, x_data, options.invert_y*y_data(:,j), experiment.metadata.label, options.markerStyle, options.markerSkip, colorSignal, lineStyle);
                end
                xlim(axis_handle, [0 x_data(end)])
                return;
            end

            obj = obj.add_1Dsignal(axis_handle, x_data, options.invert_y*y_data, experiment.metadata.label, options.markerStyle, options.markerSkip, experiment.metadata.color, experiment.metadata.LineStyle);
            xlim(axis_handle, [0 x_data(end)]);
        end

        function obj = compareWithBoxPlot(obj, axis_handle, dataset, experiment_names, var_str, options)
            % Create grouped boxplots for a given variable across experiments.
            % Signals are re-sampled to a common time-range (overlap) with
            % the same number of samples to ensure fair comparison.
            arguments
                obj
                axis_handle
                dataset
                experiment_names
                var_str
                options.ydim (1,1) double = 1
                options.timeRange double = [] % [t0 t1] override automatic overlap
                options.nSamples (1,1) double = 100 % number of samples per experiment after resampling
                options.metricFcn function_handle = @(x) x % function to compute the metric from the signal
                options.title (1,:) string = ''
                options.ylabel (1,:) string = 'Error [deg]'
                options.labels cell = {} % custom labels for experiments
                options.showComfort logical = true % draw +/-3 comfort lines
                options.comfortLevel double = 3 % comfort level value
                options.boxplotColors char = 'k'
                options.colors cell = {} % cell array of colors per experiment (hex or RGB)
                options.boxFaceAlpha double = 0.7
                options.markerStyle char = 'o'
                options.markerSize double = 6
            end

            n_experiments = length(experiment_names);

            % Collect time vectors and determine overlap range
            t_starts = zeros(n_experiments,1);
            t_ends = zeros(n_experiments,1);
            for i = 1:n_experiments
                exp_name = experiment_names{i};
                exp = dataset.(exp_name);
                t = exp.data.t;
                t_starts(i) = t(1);
                t_ends(i) = t(end);
            end

            if isempty(options.timeRange)
                t0 = max(t_starts);
                t1 = min(t_ends);
            else
                t0 = options.timeRange(1);
                t1 = options.timeRange(2);
            end

            if t1 <= t0
                error('No overlapping time range found across experiments. Provide a valid ''timeRange'' option.');
            end

            % Common time vector for resampling
            t_common = linspace(t0, t1, options.nSamples)';

            group_data = [];
            group_labels = {};

            for i = 1:n_experiments
                exp_name = experiment_names{i};
                exp = dataset.(exp_name);
                sig = exp.data.(var_str);
                y = sig(:, options.ydim);
                t = exp.data.t;

                % Interpolate to common time grid
                % interp1 requires unique sample points. Handle duplicates
                % by averaging values that share the same timestamp.
                % Remove rows with NaNs in time or signal
                valid_rows = ~isnan(t) & ~any(isnan(y), 2);
                t_valid = t(valid_rows);
                y_valid = y(valid_rows, :);

                if isempty(t_valid)
                    % No valid data for this experiment in the overlap
                    y_interp = nan(length(t_common), size(y,2));
                else
                    [t_u, ~, ic] = unique(t_valid);
                    % Average values that map to the same unique time
                    y_u = zeros(length(t_u), size(y_valid,2));
                    for col = 1:size(y_valid,2)
                        y_u(:,col) = accumarray(ic, y_valid(:,col), [], @mean);
                    end

                    if length(t_u) == 1
                        % Constant-time vector: replicate value across t_common
                        y_interp = repmat(y_u(1,:), length(t_common), 1);
                    else
                        % Ensure monotonic increasing t_u for interp1
                        [t_u_sorted, sortIdx] = sort(t_u);
                        y_u_sorted = y_u(sortIdx, :);
                        y_interp = interp1(t_u_sorted, y_u_sorted, t_common, 'linear');
                    end
                end

                % Remove NaNs that could appear if t_common extends outside
                % the data range for a particular experiment
                valid_idx = ~isnan(y_interp);
                if ismatrix(valid_idx) && size(valid_idx,2) > 1
                    % For multi-column signals, keep rows where ANY column is valid
                    valid_rows_interp = any(valid_idx, 2);
                else
                    valid_rows_interp = valid_idx;
                end
                y_interp = y_interp(valid_rows_interp, :);

                % Apply metric (identity by default)
                metric_vec = options.metricFcn(y_interp);

                % Append to grouped vector
                group_data = [group_data; metric_vec(:)];

                % Determine label for this experiment
                if ~isempty(options.labels)
                    lbl = options.labels{i};
                else
                    try
                        lbl = exp.metadata.label;
                    catch
                        lbl = exp_name;
                    end
                end

                group_labels = [group_labels; repmat({lbl}, length(metric_vec), 1)];
            end

            % Create figure/axis if needed
            if isempty(axis_handle) || ~isgraphics(axis_handle)
                fig = figure('Color', 'w', 'Position', [100 100 800 400]);
                ax = axes('Parent', fig);
            else
                ax = axis_handle;
                axes(ax); %#ok<LAXES>
            end

            % Draw boxchart grouped by categorical labels so we can style each
            % group independently (face color, alpha, marker etc.).
            % Ensure categories follow the experiment order
            if ~isempty(options.labels)
                categories = options.labels(:)';
            else
                categories = cell(1, n_experiments);
                for k = 1:n_experiments
                    en = experiment_names{k};
                    try
                        categories{k} = dataset.(en).metadata.label;
                    catch
                        categories{k} = en;
                    end
                end
            end

            cat_groups = categorical(group_labels, categories);

            try
                h = boxchart(ax, cat_groups, group_data);
            catch
                % Fallback: if older matlab does not support boxchart, use boxplot
                h = boxplot(group_data, group_labels,'Symbol', '+r', 'Colors', options.boxplotColors, 'Parent', ax);
            end

            % If boxchart returned an array of BoxChart objects, style them
            if exist('h','var') && isa(h, 'matlab.graphics.chart.primitive.BoxChart') || (isgraphics(h) && all(arrayfun(@(x) isa(x,'matlab.graphics.chart.primitive.BoxChart'), h)))
                % h may be a scalar if single group, or vector; normalize to array
                h_arr = h(:)';
                for k = 1:length(h_arr)
                    hc = h_arr(k);
                    % Determine color for this experiment
                    if ~isempty(options.colors) && length(options.colors) >= k && ~isempty(options.colors{k})
                        color_k = options.colors{k};
                    else
                        % Try to take from dataset metadata
                        try
                            color_k = dataset.(experiment_names{k}).metadata.color;
                        catch
                            color_k = []; % let matlab pick default
                        end
                    end
                    % Apply color if available
                    try
                        if ~isempty(color_k)
                            hc.BoxFaceColor = color_k;
                            hc.MarkerColor = color_k;
                        end
                    catch
                        % ignore if properties unavailable or invalid
                    end
                    try
                        hc.BoxFaceAlpha = options.boxFaceAlpha;
                    catch
                        % ignore if property not available
                    end
                    try
                        hc.MarkerStyle = options.markerStyle;
                        hc.MarkerSize = options.markerSize;
                    catch
                        % ignore
                    end
                    try
                        hc.LineWidth = obj.line_width;
                    catch
                        % Some versions use different property names; ignore
                    end
                end
            else
                % If we fell back to boxplot (h handles array of line objects), try to style
                try
                    set(h, {'LineWidth'}, {obj.line_width});
                catch
                end
            end

            ylabel(ax, options.ylabel, 'Interpreter', 'latex', 'FontSize', obj.font_size);
            if ~isempty(options.title)
                title(ax, options.title, 'Interpreter', 'latex');
            end
            grid(ax, 'on');
            set(ax, 'TickLabelInterpreter', 'latex', 'FontSize', obj.axisFontSize);

            if options.showComfort
                hold(ax, 'on');
                yline(ax, options.comfortLevel, '--r', 'Alpha', 0.5, 'LineWidth', obj.line_width);
                yline(ax, -options.comfortLevel, '--r', 'Alpha', 0.5, 'LineWidth', obj.line_width);
                hold(ax, 'off');
            end
        end

        function obj = aesthetic_axes(obj, axis_handle, ylabel_str, options)
            arguments
                obj
                axis_handle
                ylabel_str (1,:) string
                options.title (1,:) string = ''
                options.legend (1,1) logical = false
                options.customLegend cell = {}
                options.customXlabel string = obj.xlabel_str
                options.showXticks logical = false
                options.legendPosition string = 'northoutside'
                options.fontSizeLegend double = obj.font_size
                options.legendBox = 'on' % 'on' or 'off' 
                options.linkAxes logical = true % Whether to link x-axes for this axis (per-axis control)
                options.isBoxPlot logical = false % Whether the axis is a boxplot (adjustments accordingly)
            end

            if ~options.isBoxPlot
                obj = obj.add_xylabels(axis_handle, options.customXlabel, ylabel_str, options.showXticks);
            end
            if options.legend
                obj = obj.add_legend(axis_handle, customLegend = options.customLegend, legendPosition = options.legendPosition, fontSizeLegend = options.fontSizeLegend);
                % Remove box around legend if positioned outside
                if options.legendPosition == "northoutside" || options.legendPosition == "southoutside" || options.legendBox == "off"
                    legend_handle = legend(axis_handle);
                    legend_handle.Box = 'off';
                end
            end

            if ~isempty(options.title)
                title(axis_handle, options.title, 'FontSize', obj.font_size, 'Interpreter', 'latex');
            end
            grid(axis_handle, 'on');
            set(axis_handle,'Color',obj.background_color*[1 1 1],'gridcolor', obj.grid_color*[1 1 1],'gridalpha', obj.grid_alpha) % set the axis color
            box(axis_handle, 'on');
            % Store per-axis preference so we can link only the axes that
            % requested linking. This avoids making global linkaxes calls
            % that unintentionally synchronize all axes in the figure.
            ud = axis_handle.UserData;
            if isempty(ud) || ~isstruct(ud)
                ud = struct();
            end
            ud.linkXAxis = options.linkAxes;
            axis_handle.UserData = ud;

            try
                f = ancestor(axis_handle, 'figure');
                all_axes = findall(f, 'type', 'axes');
                % Keep only axes that explicitly requested linking and share
                % the same parent (e.g., same tiled layout)
                keep = arrayfun(@(h) isstruct(h.UserData) && isfield(h.UserData, 'linkXAxis') && h.UserData.linkXAxis && isequal(h.Parent, axis_handle.Parent), all_axes);
                align_axis = all_axes(keep);
                if numel(align_axis) > 1
                    linkaxes(align_axis, 'x');
                end
            catch
                % If linkaxes fails, do nothing
            end
        end

        function obj = add_custom_reference(obj, axis_handle, orientation, data, label_str, style_line, options)
            arguments
                obj
                axis_handle
                orientation (1,:) string % 'horizontal' or 'vertical'
                data (1,:) double % Data points where to add reference lines
                label_str (1,:) string % Label for the reference lines
                style_line (1,:) string = ':k' % Line style for the reference lines
                options.legend (1,:) string = 'off' % 'on' or 'off' for legend visibility
                options.opposite_range double = [] % Optional opposite axis range to plot line across
                options.line_width double = obj.line_width % Line width for the reference lines
            end

            hold(axis_handle, 'on');

            for i = 1:length(data)
                if orientation == "horizontal"
                    if ~isempty(options.opposite_range)
                        plot(axis_handle, options.opposite_range, [data(i) data(i)], style_line, 'LineWidth', options.line_width, 'DisplayName', label_str, 'HandleVisibility', options.legend);
                        continue;
                    end
                        yline(axis_handle, data(i), style_line, 'LineWidth', options.line_width, 'DisplayName', label_str, 'HandleVisibility', options.legend);
                elseif orientation == "vertical"
                    if ~isempty(options.opposite_range)
                        plot(axis_handle, [data(i) data(i)], options.opposite_range, style_line, 'LineWidth', options.line_width, 'DisplayName', label_str, 'HandleVisibility', options.legend);
                        continue;
                    end
                    xline(axis_handle, data(i), style_line, 'LineWidth', options.line_width, 'DisplayName', label_str, 'HandleVisibility', options.legend);
                end
            end
            
        end

        function obj = add_notation(obj, axis_handle, text_str, point_arrow, long_arrow, angle_arrow, color_str, font_size)
            if nargin < 7
                color_str = 'k';
            end
            if nargin < 8
                font_size = obj.font_size;
            end

            arrow_x = point_arrow(1) + long_arrow * cos(angle_arrow*pi/180);
            arrow_y = point_arrow(2) + long_arrow * sin(angle_arrow*pi/180);
            
            figure_handle = ancestor(axis_handle, 'figure');

            annotation(figure_handle, 'textarrow',  [arrow_x point_arrow(1)], [arrow_y point_arrow(2)], 'Color', color_str, 'String', text_str, 'FontSize', font_size, 'Interpreter', 'latex', 'LineWidth', obj.line_width);
        end

        function obj = add_markerPoint(obj, axis_handle, point, options)
            arguments
                obj
                axis_handle
                point (1,2) double % [x, y] coordinates of the point
                options.markerStyle string = 'o' % Marker style
                options.color string = 'k' % Marker color
                options.size double = 50 % Marker size
                options.fill string = 'filled' % 'filled' or 'none'
                options.label_str string = '' % Label for the marker point
                options.legend string = 'off' % 'on' or 'off' for legend visibility
                options.colorFill string = '#ffffff' % Optional different color for fill
                options.line_width double = obj.line_width % Line width for the marker edge
            end

            if isempty(options.label_str)
                options.legend = 'off';
            end

            hold(axis_handle, 'on');
            % Define marker point using the plot function
            plot(axis_handle, point(1), point(2), options.markerStyle, 'Color', options.color, 'MarkerSize', options.size, 'MarkerFaceColor', options.colorFill, 'MarkerEdgeColor', options.color, 'LineWidth', options.line_width, 'DisplayName', options.label_str, 'HandleVisibility', options.legend);
        end

        function obj = draw_invariant(obj, axis_handle, neighborhood, color_str, transparency, set_name)
            % Default values
            show_legend = 'on';
            if nargin < 4
                color_str = 'k';
            end
            if nargin < 5
                transparency = 0.3;
            end
            if nargin < 6
                set_name = '';
                show_legend = 'off';
            end

            hold(axis_handle, 'on');
            % Rectangle spanning full x limits and y = [-neighborhood, +neighborhood]
            x1 = axis_handle.XLim(1);
            x2 = axis_handle.XLim(2);
            xv = [x1; x2; x2; x1];
            yv = [-neighborhood; -neighborhood; neighborhood; neighborhood];

            % Use the axes handle form of patch and get the handle
            hPatch = patch(axis_handle, xv, yv, color_str, 'FaceAlpha', transparency, 'EdgeColor', 'none', 'HandleVisibility', show_legend, 'DisplayName', set_name);

            % Ensure the patch is placed behind existing plot elements so it
            % acts as a background rectangle. uistack moves graphics objects
            % in the stacking order; if unavailable, the operation is
            % skipped silently.
            try
                uistack(hPatch, 'bottom');
            catch
                % If uistack is not available or fails, do nothing.
            end
        end

        function obj = add_colorRectangle(obj, axis_handle, limits, options)
            arguments
                obj
                axis_handle
                limits double % [x_min, x_max] or [x_min, x_max; y_min, y_max]
                options.color_str string = 'k' % Color for the rectangle
                options.transparency double = 0.3 % Transparency for the rectangle
                options.legend_str string = '' % Legend entry label for the rectangle
             end
            
            if strcmp(options.legend_str, '')
                options.show_legend = 'off';

            else
                options.show_legend = 'on';
            end

            hold(axis_handle, 'on');
            % Rectangle spanning x limits and y limits

            if size(limits, 1) == 1
                limits = [limits; axis_handle.YLim];
            end


            x1 = limits(1,1);
            x2 = limits(1,2);
            y1 = limits(2,1);
            y2 = limits(2,2);
            
            xv = [x1; x2; x2; x1];
            yv = [y1; y1; y2; y2];

            % Use the axes handle form of patch and get the handle
            hPatch = patch(axis_handle, xv, yv, options.color_str, 'FaceAlpha', options.transparency, 'EdgeColor', 'none', 'HandleVisibility', options.show_legend, 'DisplayName', options.legend_str);

            % Ensure the patch is placed behind existing plot elements so it
            % acts as a background rectangle. uistack moves graphics objects
            % in the stacking order; if unavailable, the operation is
            % skipped silently.
            try
                uistack(hPatch, 'bottom');
            catch
                % If uistack is not available or fails, do nothing.
            end
        end

        function [obj, zoomed_axis_handle] = add_zoomed_figure(obj, axis_handle, limits, set_position, options)
            arguments
                obj
                axis_handle
                limits double % [x_min, x_max] or [x_min, x_max; y_min, y_max]
                set_position (1,4) double % [left, bottom, width, height] in normalized units
                options.Title (1,:) string = ''
                options.color  = "k" % Color in RGB or color string for zoomed axis
                options.backgroundTransparency double = 0 % Background transparency for zoomed axis
                options.line_width double = obj.line_width % Line width for rectangle in main axis
                options.stylebox string = '--' % Line style for rectangle in main axis
                options.fontSize double = obj.font_size % Font size for zoomed axis
                options.showXLabels logical = false % Whether to show xlabels in zoomed axis
            end

            [n, ~] = size(limits);
            if n == 1
                x_limits = limits;
            else
                x_limits = limits(1, :);
            end
            
            % Copy axis into the figure (not into the tiled layout) so we can
            % freely set the Position property. Setting Position on objects
            % that are children of a TiledChartLayout triggers warnings.
            fig = ancestor(axis_handle, 'figure');
            zoomed_axis_handle = copyobj(axis_handle, fig);
            % Ensure normalized units and then set the requested position
            try
                zoomed_axis_handle.Units = 'normalized';
            catch
                % If Units property isn't available for some copy, ignore
            end
            
            zoomed_axis_handle.Position = set_position;
            
            if ~isempty(options.Title)
                title(zoomed_axis_handle, options.Title, 'Interpreter', 'latex');
            end

            zoomed_axis_handle.Title.BackgroundColor = 'w';
            xlim(zoomed_axis_handle, x_limits);
            if n > 1 
                ylim(zoomed_axis_handle, limits(2, :));
            end
            box(zoomed_axis_handle, 'on');
            grid(zoomed_axis_handle, 'on');
            ylabel(zoomed_axis_handle, '');

            % Set font size in ysticks and xticks
            set(zoomed_axis_handle, 'FontSize', options.fontSize);

            % Show xticks labels, they were removed in the main axis
            set(zoomed_axis_handle, 'XTickLabelMode', 'auto');
            
            if ~options.showXLabels
                xlabel(zoomed_axis_handle, '', 'FontSize', options.fontSize, 'Interpreter', 'latex');
            end

            % set(axis_handle,'Color',0.94*[1 1 1],'gridcolor',[1 1 1],'gridalpha',0.9) % set the axis color
            
            % obj.aesthetic_axes(zoomed_axis_handle, '', title = options.Title, customXlabel = '');

            if options.backgroundTransparency > 0
                % Set background color with adjusted transparency
                backgroundColor = obj.adjustColorTransparency(options.color, options.backgroundTransparency);
                set(zoomed_axis_handle,'Color',backgroundColor,'gridcolor',[1 1 1],'gridalpha',0.9) % set the axis color
            end
            zoomed_axis_handle.XColor = options.color;
            zoomed_axis_handle.YColor = options.color;
            zoomed_axis_handle.XLabel.Color = options.color;
            zoomed_axis_handle.YLabel.Color = options.color;
            zoomed_axis_handle.Title.Color = options.color;
            obj.draw_rectangle4zoom(axis_handle, x_limits, zoomed_axis_handle.YLim, options.color, options.line_width, options.stylebox);    
        end

        function obj = draw_rectangle4zoom(obj, axis_handle, x_limits, y_limits, color, width_line, style_line)
            hold(axis_handle, 'on');
            rectangle(axis_handle, 'Position', [x_limits(1), y_limits(1), x_limits(2)-x_limits(1), y_limits(2)-y_limits(1)], 'EdgeColor', color, 'LineWidth', width_line, 'LineStyle', style_line);
        end

        function obj = convert2pdf(obj, figure_handle, filename_str)
            % figure_handle.PaperUnits = 'centimeters';  
            % figure_handle.PaperSize = [100 100];
            % print(figure_handle, filename_str, '-dpdf', '-r100', '-vector');
            exportgraphics(figure_handle, filename_str, 'ContentType', 'vector', 'Resolution', 300);
        end
    end

    methods(Access = private)
        function obj = add_1Dsignal(obj, axis_handle, t, data, name_str, markerStyle, markerSkip, colorSignal, styleLine)
            hold(axis_handle, 'on');
            if markerStyle ~= "none"
                index_vector = 1:markerSkip:length(t);
                plot(axis_handle, t, data, 'LineWidth', obj.line_width, 'DisplayName', name_str, 'Marker', markerStyle, 'MarkerIndices', index_vector, 'Color', colorSignal, 'LineStyle', styleLine);
                return;
            end
            plot(axis_handle, t, data, 'LineWidth', obj.line_width, 'DisplayName', name_str, 'Color', colorSignal, 'LineStyle', styleLine);
        end

        function obj = add_xylabels(obj, axis_handle, xlabel_str, ylabel_str, showXticks)
            set(axis_handle, 'FontSize', obj.axisFontSize);
            ylabel(axis_handle, ylabel_str, 'FontSize', obj.font_size, 'Interpreter', 'latex');
            if ~showXticks
                set(axis_handle, 'XTickLabel', []);
                return;
            end 
            xlabel(axis_handle, xlabel_str, 'FontSize', obj.font_size, 'Interpreter', 'latex');
        end

        function obj = add_legend(obj, axis_handle, options)
            arguments
                obj
                axis_handle
                options.customLegend cell = {}
                options.legendPosition string = 'northoutside'
                options.fontSizeLegend double = obj.font_size
            end
            if ~isempty(options.customLegend)
                legend(axis_handle, options.customLegend{:}, 'FontSize', options.fontSizeLegend, 'Location', options.legendPosition, 'Interpreter', 'latex', 'Orientation', 'horizontal');
                return;
            end
            legend(axis_handle, 'show', 'FontSize', options.fontSizeLegend, 'Location', options.legendPosition, 'Interpreter', 'latex', 'Orientation', 'horizontal');
        end

        function norm_data = compute_norm(obj, data)
            [n, m] = size(data);

            if n < m 
                data = data';
            end

            norm_data = 0;

            for i = 1:m
                norm_data = norm_data + data(:,i).^2;
            end

            norm_data = sqrt(norm_data);
        end

        function integral_data = compute_integral(obj, data, dt)
            % Compute cumulative time-integral of data (rows = time, cols = signals)
            if nargin < 3
            error('compute_integral requires data and dt');
            end

            % Ensure data is column-oriented (time along rows)
            if isrow(data)
            data = data';
            end

            % Cumulative integral for each column
            integral_data = cumsum(data, 1) * dt;
        end

        function new_color = adjustColorTransparency(~, color, transparency)
            % Adjust the transparency of a given HEX or RGB color
            if isnumeric(color) && length(color) == 3
                rgbColor = color;
            else
                if color(1) ~= '#'
                    error('Color must be a HEX string starting with # or an RGB array');
                end
                hexColor = color(2:end);
                rgbColor = sscanf(hexColor, '%2x', [1 3]) / 255;
            end          
            
            new_color = rgbColor * transparency + [1 1 1] * (1 - transparency);
        end

    end
end