function rpy = quat2rpy(q)
    % --- Normalization ---
    % Ensure it's a unit quaternion (conversions rely on this)
    q = q / norm(q);

    % Extract components
    w = q(1);
    x = q(2);
    y = q(3);
    z = q(4);

    % --- Conversion ---

    % Calculate pitch (y-axis rotation) and check for singularity
    % This value is sin(pitch)
    sinp = 2 * (w * y - z * x);

    % Use a small epsilon for robust floating-point comparison
    epsilon = 1e-9; 

    if abs(sinp) >= 1 - epsilon
        % --- Gimbal Lock Case ---
        % Pitch is +/- 90 degrees
        pitch = sign(sinp) * (pi / 2);
        
        % We set roll to 0 and solve for yaw
        roll = 0;

        yaw = 2 * atan2(x, w);
        
    else
        % --- Non-Singular Case ---
        pitch = asin(sinp);
        
        % Roll (x-axis rotation)
        sinr_cosp = 2 * (w * x + y * z);
        cosr_cosp = 1 - 2 * (x^2 + y^2);
        roll = atan2(sinr_cosp, cosr_cosp);
        
        % Yaw (z-axis rotation)
        siny_cosp = 2 * (w * z + x * y);
        cosy_cosp = 1 - 2 * (y^2 + z^2);
        yaw = atan2(siny_cosp, cosy_cosp);
    end

        rpy = [roll pitch yaw];

end