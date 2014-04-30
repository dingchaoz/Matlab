function savePlot(obj, fileName)
%Method that will save the current plot
%   May need tweaking depending on desired behavior with who closes the figure
%   
%   Usage: savePlot(obj, fileName)
%   
%   Inputs -
%   fileName: Name of the file to save the plot into
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - October 23, 2012
%   Revised - N/A - N/A
    
    % Size the figure properly
    set(gcf, 'PaperPositionMode', 'manual');
    %set(gcf, 'PaperUnits', 'inches');
    % set(gcf, 'PaperPosition', [2 1 6 4.5]);
    set(gcf, 'PaperPosition', [0 0 11 7]);
    %set(gcf, 'Renderer', 'painters');
    %set(gcf, 'RendererMode', 'manual');
    % Save the figure to disk
    print('-dpng', '-r150', fileName)
    
    %saveas(gcf, [fileName '_saveas'], 'png')
    % Delete and close the figure
    delete(gcf)
    
end
