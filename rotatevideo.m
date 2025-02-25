% Set up the video writer (older method)
v = VideoWriter('rotating_3d_plot.avi');  % Use AVI format
open(v);

% Define the rotation angles
numFrames = 180; % Number of frames in the video (i.e., one complete rotation)
for i = 1:numFrames
    % Rotate the plot by adjusting the view
    view(i, 12.5);  % Adjust the azimuth (i) and elevation (30)
    
    % Capture the current frame
    drawnow;  % Ensures the figure is updated before capturing
    frame = getframe(gcf);
    
    % Write the frame to the video
    writeVideo(v, frame);
end

% Close the video writer
close(v);