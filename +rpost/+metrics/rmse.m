function val = rmse(t, norm_v)
    % RMSE  Root Mean Squared Error
    %
    % Provides a measure of the average magnitude of the error. Useful for
    % comparing overall performance across different responses.
    %
    % INPUTS:
    %   t      - time vector (N x 1)
    %   norm_v - Euclidean norm of the signal at each time step (N x 1)
    %
    % OUTPUT:
    %   val    - scalar RMSE value
    val = sqrt(trapz(t, norm_v.^2) / length(t));
end