function val = linf(~, norm_v)
    % LINF  L-infinity norm (worst-case / peak value)
    %
    % Returns the maximum value of the signal norm over the entire
    % time window. Relevant for assessing actuator saturation limits
    % or worst-case tracking deviation.
    %
    % INPUTS:
    %   t      - time vector (N x 1) [unused, kept for uniform interface]
    %   norm_v - Euclidean norm of the signal at each time step (N x 1)
    %
    % OUTPUT:
    %   val    - scalar peak value
    val = max(norm_v);
end
