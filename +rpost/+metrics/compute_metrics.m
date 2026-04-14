function m = compute_metrics(simu, exp_names, var_name, opts)
    % COMPUTE_METRICS  Performance metrics from Euclidean norm of a variable
    %
    % Iterates over a set of experiments (or simulations) and computes the
    % requested scalar metrics based on the Euclidean norm of the specified
    % field across all its dimensions.
    %
    % INPUTS:
    %   simu      - struct where each field is an experiment with:
    %                 .data.(var_name)  [N x d] signal matrix
    %                 .data.t           [N x 1] time vector
    %   exp_names - cell array of experiment name strings
    %   var_name  - name of the field in .data to evaluate (e.g. 'e', 'u')
    %   opts      - optional name-value pairs:
    %                 'metrics'   cell of metric names to compute.
    %                             Available: 'ise', 'iae', 'itae', 'itse',
    %                                        'linf', 'ss_stats'
    %                             Default: all of the above.
    %                 'ss_ratio'  scalar in (0,1), fraction of time window
    %                             considered steady-state (default: 0.8)
    %                 'do_plot'   logical, display summary table (default: false)
    %
    % OUTPUT:
    %   m - struct where m.(exp_name).(metric) holds each result.
    %       For 'ss_stats', m.(exp_name).ss_stats is itself a struct
    %       with fields .mean, .std, and .t_ss.
    %
    % EXAMPLE:
    %   m = rpost.metrics.compute_metrics(simu, {'exp1','exp2'}, 'e', ...
    %           'metrics', {'ise','itae','linf'}, 'do_plot', true);

    arguments
        simu
        exp_names  cell
        var_name   char
        opts.metrics  cell     = {'ise','iae','itae','itse','linf','ss_stats'}
        opts.ss_ratio double   = 0.8
        opts.do_plot  logical  = false
    end

    % --- Map metric names to function handles ---
    ss_ratio = opts.ss_ratio;
    available = struct( ...
        'ise',      @(t,v) rpost.metrics.ise(t, v),          ...
        'iae',      @(t,v) rpost.metrics.iae(t, v),          ...
        'itae',     @(t,v) rpost.metrics.itae(t, v),         ...
        'itse',     @(t,v) rpost.metrics.itse(t, v),         ...
        'linf',     @(t,v) rpost.metrics.linf(t, v),         ...
        'ss_stats', @(t,v) rpost.metrics.ss_stats(t, v, ss_ratio) ...
    );

    % --- Validate requested metrics ---
    for k = 1:length(opts.metrics)
        if ~isfield(available, opts.metrics{k})
            error('rpost:metrics:unknown', ...
                'Unknown metric ''%s''. Available: %s.', ...
                opts.metrics{k}, strjoin(fieldnames(available), ', '));
        end
    end

    % --- Compute ---
    m = struct();
    for i = 1:length(exp_names)
        name   = exp_names{i};
        t      = simu.(name).data.t(:);
        norm_v = vecnorm(simu.(name).data.(var_name), 2, 2);

        for k = 1:length(opts.metrics)
            metric_name = opts.metrics{k};
            fn = available.(metric_name);
            m.(name).(metric_name) = fn(t, norm_v);
        end
    end

    % --- Optional table display ---
    if opts.do_plot
        scalar_metrics = opts.metrics(~strcmp(opts.metrics, 'ss_stats'));
        names_col = string(exp_names');
        T = table(names_col, 'VariableNames', {'Experiment'});

        for k = 1:length(scalar_metrics)
            mn  = scalar_metrics{k};
            col = cellfun(@(n) m.(n).(mn), exp_names)';
            T.(upper(mn)) = col;
        end

        if ismember('ss_stats', opts.metrics)
            T.SS_Mean = cellfun(@(n) m.(n).ss_stats.mean, exp_names)';
            T.SS_Std  = cellfun(@(n) m.(n).ss_stats.std,  exp_names)';
        end

        fprintf('\n--- Performance Metrics: %s ---\n', var_name);
        disp(T);
    end
end
