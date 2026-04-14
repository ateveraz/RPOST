function val = itae(t, norm_v)
    % ITAE  Integral Time-weighted Absolute Error
    %
    % Penalizes errors that persist over time. Particularly useful for
    % detecting poor steady-state performance or slow convergence in
    % sliding mode and adaptive controllers.
    %
    % INPUTS:
    %   t      - time vector (N x 1)
    %   norm_v - Euclidean norm of the signal at each time step (N x 1)
    %
    % OUTPUT:
    %   val    - scalar ITAE value
    val = trapz(t, t(:) .* norm_v);
end
