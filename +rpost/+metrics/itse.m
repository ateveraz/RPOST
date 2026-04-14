function val = itse(t, norm_v)
    % ITSE  Integral Time-weighted Squared Error
    %
    % Combines the peak sensitivity of ISE with the time weighting of ITAE.
    % Useful when both transient peaks and settling time matter.
    %
    % INPUTS:
    %   t      - time vector (N x 1)
    %   norm_v - Euclidean norm of the signal at each time step (N x 1)
    %
    % OUTPUT:
    %   val    - scalar ITSE value
    val = trapz(t, t(:) .* norm_v.^2);
end
