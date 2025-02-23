% Test Case 1: Object moving North (directly towards the radar)
% Expected: v_rad = -100 m/s (negative, moving towards), AZ_deg_per_s = 0, ELEV_deg_per_s = 0
[RadialVelocity_mps, AZ_deg_per_s, ELEV_deg_per_s] = trajectory2aerv(0, 90, 100000, -100, 0, 0);
fprintf('Test 1: v_rad = %.3f (Expected: -100.000)\n', RadialVelocity_mps);
fprintf('         AZ_deg_per_s = %.3f, ELEV_deg_per_s = %.3f\n', AZ_deg_per_s, ELEV_deg_per_s);

% Test Case 2: Object moving South (directly away from the radar)
% Expected: v_rad = 100 m/s (positive, moving away), AZ_deg_per_s = 0, ELEV_deg_per_s = 0
[RadialVelocity_mps, AZ_deg_per_s, ELEV_deg_per_s] = trajectory2aerv(0, 90, 100000, 100, 0, 0);
fprintf('Test 2: v_rad = %.3f (Expected: 100.000)\n', RadialVelocity_mps);
fprintf('         AZ_deg_per_s = %.3f, ELEV_deg_per_s = %.3f\n', AZ_deg_per_s, ELEV_deg_per_s);

% Test Case 3: Object moving East (directly towards the radar)
% Expected: v_rad = 100 m/s (positive, moving towards), AZ_deg_per_s = 0, ELEV_deg_per_s = 0
[RadialVelocity_mps, AZ_deg_per_s, ELEV_deg_per_s] = trajectory2aerv(90, 0, 100000, 0, 100, 0);
fprintf('Test 3: v_rad = %.3f (Expected: 100.000)\n', RadialVelocity_mps);
fprintf('         AZ_deg_per_s = %.3f, ELEV_deg_per_s = %.3f\n', AZ_deg_per_s, ELEV_deg_per_s);

% Test Case 4: Object moving West (directly away from the radar)
% Expected: v_rad = -100 m/s (negative, moving away), AZ_deg_per_s = 0, ELEV_deg_per_s = 0
[RadialVelocity_mps, AZ_deg_per_s, ELEV_deg_per_s] = trajectory2aerv(270, 0, 100000, 0, -100, 0);
fprintf('Test 4: v_rad = %.3f (Expected: -100.000)\n', RadialVelocity_mps);
fprintf('         AZ_deg_per_s = %.3f, ELEV_deg_per_s = %.3f\n', AZ_deg_per_s, ELEV_deg_per_s);

% Test Case 5: Object moving vertically upwards (no horizontal movement)
% Expected: v_rad = 0 m/s (no radial velocity), AZ_deg_per_s = 0, ELEV_deg_per_s = non-zero
[RadialVelocity_mps, AZ_deg_per_s, ELEV_deg_per_s] = trajectory2aerv(0, 90, 100000, 0, 0, 100);
fprintf('Test 5: v_rad = %.3f (Expected: 0.000)\n', RadialVelocity_mps);
fprintf('         AZ_deg_per_s = %.3f, ELEV_deg_per_s = %.3f (non-zero)\n', AZ_deg_per_s, ELEV_deg_per_s);

% Test Case 6: Object moving vertically downwards (no horizontal movement)
% Expected: v_rad = 0 m/s (no radial velocity), AZ_deg_per_s = 0, ELEV_deg_per_s = non-zero
[RadialVelocity_mps, AZ_deg_per_s, ELEV_deg_per_s] = trajectory2aerv(0, -90, 100000, 0, 0, -100);
fprintf('Test 6: v_rad = %.3f (Expected: 0.000)\n', RadialVelocity_mps);
fprintf('         AZ_deg_per_s = %.3f, ELEV_deg_per_s = %.3f (non-zero)\n', AZ_deg_per_s, ELEV_deg_per_s);

% Test Case 7: Object moving in a diagonal (45 degrees to North-East)
% Expected: v_rad ≈ -141.421 m/s (towards the radar), az_deg_per_s and elev_deg_per_s non-zero
[RadialVelocity_mps, AZ_deg_per_s, ELEV_deg_per_s] = trajectory2aerv(45, 45, 100000, -100, 100, 0);
fprintf('Test 7: v_rad = %.3f (Expected: ~-141.421)\n', RadialVelocity_mps);
fprintf('         AZ_deg_per_s = %.3f, ELEV_deg_per_s = %.3f\n', AZ_deg_per_s, ELEV_deg_per_s);

% Test Case 8: Object moving directly upwards and to the East (complex movement)
% Expected: v_rad ≈ 100 m/s (towards the radar), az_deg_per_s and elev_deg_per_s non-zero
[RadialVelocity_mps, AZ_deg_per_s, ELEV_deg_per_s] = trajectory2aerv(90, 45, 100000, -100, 100, 100);
fprintf('Test 8: v_rad = %.3f (Expected: ~100)\n', RadialVelocity_mps);
fprintf('         AZ_deg_per_s = %.3f, ELEV_deg_per_s = %.3f\n', AZ_deg_per_s, ELEV_deg_per_s);
