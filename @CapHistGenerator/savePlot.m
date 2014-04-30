function savePlot(obj, fileName)
%Save the Box Plot that makePlot generated
%   This will save the current figure using the settings correct for a box plot
%   to a file name that is specified.
%   
%   Usage: savePlot(obj, fileName)
%   
%   Inputs - 
%   fileName: Name of the file that the plot should be saved into
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - April 11, 2012
%   Revised - N/A - N/A

    %% Check that the path to the specified folder exists
    % Don't think this is needed as makeBoxPlots makes all the directories first
%     [path, ~, ~] = fileparts(fileName);
%     if ~exist(path, 'dir')
%         % If not, then make it
%         mkdir(path)
%     end
    
    % Set the size of the plot
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition', [0 0 11 7]);
    % Set the axis mode to frozen as (apparently) the axis limits can change when
    % using print
    set(gca, 'XLimMode', 'manual', 'YLimMode', 'manual');
    
%     % Move the y-labels to the left so they don't cross into the plot
%     % Get the handles to all the text labels
%     
%     %Get the hggroup
%     hg1 = get(gca,'Children');
%     %Get the text annotations
%     ch2 = findobj(hg1,'type','text');
%     
%     %text_h=findobj(gca,'type','text'); % Using this works
%     % For each text label
%     for i = 1:length(ch2)
%         % If they aren't the LSL and USL labels
%         if ~strcmp(get(ch2(i),'String'),'LSL') && ~strcmp(get(ch2(i),'String'),'USL')
%             % Move them to right by 25% of the total difference of the x-axis limits
%             set(ch2(i),'Position',get(ch2(i),'Position') - [0.25*diff(xlim) 0 0])
%         end
%     end
%     
%     %Make a new hggroup with the repositioned text annotations
%     copyobj(hg1,gca)
%     %delete the first hggroup
%     delete(hg1);
    
    % Save as a png at a resolution of 150 dpi in the specified directory and file name
    print('-dpng', '-r150', fileName)
    % Delete (and close) the figure
    delete(gcf);
    
end
