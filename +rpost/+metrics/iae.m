function val = iae(t, norm_v)
    % IAE  Integral Absolute Error
    %
    % Measures total accumulated error without squaring. Less sensitive to
    % peaks than ISE; good for evaluating overall tracking quality.
    %
    % INPUTS:
    %   t      - time vector (N x 1)
    %   norm_v - Euclidean norm of the signal at each time step (N x 1)
    %
    % OUTPUT:
    %   val    - scalar IAE value
    val = trapz(t, norm_v);
end
