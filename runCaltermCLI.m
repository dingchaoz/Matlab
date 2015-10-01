function runCaltermCLI(cal,ecfg,filter,export,xml,code)
%This generates a .bat file and call the CaltermCLI to generate a .m export file
%   
%   Inputs -
%   cal:     Full file path and name of the .xcal file
%   ecfg:    Full file path and name of the .ecfg file
%   filter:  Full file path and name of the .flt.txt file
%   export:  Full file path and name of the desired export file
%   code:    Product code to use for Calterm
%   
%   Outputs -
%   none
%   
%   Original Version - Chris Remington - March 21, 2012
%   Revised - Chris Remington - January 13, 2014
%     - Modified to simply call the entire CLI command at once
%   Revised - Dingchao Zhang - Oct 1, 2015
%     - Modified to add export xml file using CLI command
    


    % Forumulate the CLI command call
    mexport = sprintf('%s -Cexport -P"%s" -S"%s" -E"%s" -G"%s" -O"%s" -Dfalse -FmatLabMFile -Lcal',...
        '"C:\Software\Calterm III\CaltermCLI.exe"',code,cal,ecfg,filter,export);
    
    % Run the CLI command
    dos(mexport);
    
    % Forumulate the CLI command call
    xmlexport = sprintf('%s -Cexport -P"%s" -S"%s" -E"%s" -G"%s" -O"%s" -Dfalse -FXML -Lcal',...
        '"C:\Software\Calterm III\CaltermCLI.exe"',code,cal,ecfg,filter,xml);
    
    % Run the CLI command
    dos(xmlexport);
    
end
