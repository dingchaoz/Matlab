function CopyGUIToDLDiag
%Push GUI Code to DL_Diag
%   Simply copies the latest code from a local copy of the git directroy and places it on 
%   DL_Diag in the location that users are expecting the GUI to be used. This makes it 
%   easier to only put the files required for the GUI on the network instead of everything
    
    % Path to network location
    targetDir = '\\CIDCSDFS01\EBU_Data01$\NACTGx\common\DL_Diag\Data Analysis\OBD Capability GUI\CapabilityGUI';
    
    % Define folders and files to copy
    copyList = {'@BoxPlotGenerator','@Capability','@CapHistGenerator','@DotPlotGenerator',...
                '@HistogramGenerator','@StatCalculator','sqldriver','CapabilityGUI.fig',...
                'CapabilityGUI.m','customDataCursor.m','findjobj.m','InstallSQLDriver.m',...
                'rawData.fig','rawData.m','xlswrite2.m'};
    
   % For each file being worked on
    for i = 1:length(copyList)
        % Show what's being worked on
        disp(copyList{i})
        % Copy these folders and files (and only these) that are needed for the GUI to work
        copyfile(copyList{i},fullfile(targetDir,copyList{i}),'f')
    end
    
    % Copy the 'RunCapabilityGUI.m' file to one level higher directory
    copyfile('RunCapabilityGUI.m',fullfile(targetDir,'..','RunCapabilityGUI.m'),'f')
    % Copy the 'RunCapabilityGUI.m' file to one level higher directory
    copyfile('Capability GUI Installation Instructions.docx',fullfile(targetDir,'..','Capability GUI Installation Instructions.docx'),'f')
    
    % Set all the files to be read-only to help prevent people from changing them (won't stop 
    % files from being deleted but this should help keep it from changing)
    dos(sprintf('attrib +r "%s\\*" /D /S',targetDir),'-echo');
    dos(sprintf('attrib +r "%s\\..\\RunCapabilityGUI.m" /D /S',targetDir),'-echo');
    dos(sprintf('attrib +r "%s\\..\\Capability GUI Installation Instructions.docx" /D /S',targetDir),'-echo');
end
