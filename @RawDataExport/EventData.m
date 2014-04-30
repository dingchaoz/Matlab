function EventData(obj, dir)
%Exports all Event Driven data from the database to .mat files
%   This rountine will look for a listing of all system errors with data in
%   tblEventDrivenData. It will then pull each parameters's worth of data from the 
%   database and save the raw data into both an excel spreadsheet and a .mat file
%   
%   Usage: EventData(obj, dir)
%   
%   Inputs -
%   dir:      Location of the base directory where the files should be stored
%   
%   Outputs -
%   none
%   
%   Original Version - Chris Remington - March 27, 2012
%   Revisied - Chris Remington - August 22, 2012
%     - Added a try/catch block to the main for loop so that any error on one system error
%       doesn't stop the rest of the system errors in the export list
%   Revised - Chris Remington - September 17, 2012
%     - Modified so that this function will call a single sub-function to export each
%       individual system error's worth of data
    
    % Display a warning that a unique list of SEID is being fetched
    fprintf('Fetching unique list of SEID, this may take a few minutes...\n')
    % Select a unique listing of all SEIDs present in the tblEventDrivenData table
    d = fetch(obj.conn, 'SELECT DISTINCT [SEID] FROM [dbo].[tblEventDrivenData]');
    %d.SEID = [1754;1757;1759;2465;2468;2837;2844;2847;2851;2852;2858;2895;2896;2897;2898;2899;2960;2961;2962;2964;2965;2983;2984;3036;3073;3190;3545;3565;3576;3579;3590;3633;3634;3635;3650;3651;3652;3665;3669;3785;3796;3797;3799;3876;3877;3878;3922;3924;3926;3927;4014;4015;4016;4067;4070;4190;4192;4360;4361;4438;4439;4441;4442;4443;4719;4748;5043;5245;5246;5365;5366;5367;5368;5369;5726;5738;5739;5803;5829;5976;5978;5979;5980;5982;6021;6481;6482;6486;6507;6508;6509;6545;6688;6689;6955;6982;6996;7280;7282;7284;7285;7286;7288;7293;7294;7295;7296;7312;7321;7322;7448;7455;7458;7560;7610;7611;7612;7613;7631;7632;7831;7832;7834;7835;7872;7979;7987;7988;7989;7990;8026;8281;8289;8291;8293;8319;8680;8681;8682;8683;8684;8687;8688;8689;8690;8691;8692;8693;8694;8695;];
    % Skipped from manual list = [4758;6981;];
    % Display how many system errors were found
    fprintf('Found %.0f system errors worth of event driven data.\n', length(d.SEID));
    
    % Create the specified directory for Matlab Data if it doesn't exist already
    if ~exist(dir, 'dir')
        mkdir(dir)
    end
    
    % Loop through each of the SEIDs
    for i = 1:length(d.SEID)
        tic
        % Try to complete the export for this system error
        try
            obj.SingleEventData(d.SEID(i), dir);
        catch ex
            % Print the seid that was errored on
            fprintf('Failure on SEID %.0f\n',d.SEID(i))
            % Print the error report to the display
            disp(getReport(ex))
        end
        % Print time to export this system error
        toc
    end
end
