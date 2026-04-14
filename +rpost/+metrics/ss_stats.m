function val = ss_stats(t, norm_v, ss_ratio)
    % SS_STATS  Steady-state statistics
    %
    % Computes mean and standard deviation over the final portion of the
    % signal, used to assess steady-state precision and chattering.
    %
    % INPUTS:
    %   t        - time vector (N x 1)
    %   norm_v   - Euclidean norm of the signal at each time step (N x 1)
    %   ss_ratio - fraction of the time window considered steady-state
    %              (default: 0.8, i.e. last 20% of t)
    %
    % OUTPUT:
    %   val      - struct with fields:
    %                .mean  - mean of norm_v in steady-state window
    %                .std   - std  of norm_v in steady-state window
    %                .t_ss  - time at which steady-state window begins
    if nargin < 3
        ss_ratio = 0.8;
    end

    N      = length(t);
    ss_idx = floor(ss_ratio * N) : N;

    val.mean = mean(norm_v(ss_idx));
    val.std  = std(norm_v(ss_idx));
    val.t_ss = t(ss_idx(1));
end
