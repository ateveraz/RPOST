function val = ise(t, norm_v)
    % ISE  Integral Squared Error
    %
    % Penalizes large deviations heavily. Useful for comparing transient
    % responses where peaks (e.g. overshoot) are undesirable.
    %
    % INPUTS:
    %   t      - time vector (N x 1)
    %   norm_v - Euclidean norm of the signal at each time step (N x 1)
    %
    % OUTPUT:
    %   val    - scalar ISE value
    val = trapz(t, norm_v.^2);
end
