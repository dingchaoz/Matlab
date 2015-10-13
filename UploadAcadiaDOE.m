%Define program
    program = 'Acadia';

% Define Conn
    conn = database(program,'','','com.microsoft.sqlserver.jdbc.SQLServerDriver',...
           sprintf('%s%s;%s','jdbc:sqlserver://W4-S129433;instanceName=CapabilityDB;database=',program,...
            'integratedSecurity=true;loginTimeout=5;'));
        
 % Create DOETable struct to hold table to be inserted
    DOETable = struct('Test_No',{},'Start',{},'Stop',{},'DateNum_Start',{},'DateNum_Stop',{},'System_Error',{},'SEID',{},'Parameter',{});
        
    % Fill up the structure of DOETable
    DOETable(1).Test_No = VarName1;
    DOETable(1).Start = VarName2;
    DOETable(1).Stop = VarName3;
    DOETable(1).DateNum_Start = VarName4;
    DOETable(1).DateNum_Stop = VarName5;
    DOETable(1).System_Error = NOX_OUT_SENSOR_IR_LO_MOTOR_ERR;
    DOETable(1).SEID = VarName7;
    DOETable(1).Parameter = V_SCD_ppm_AvgNOxOff_Decision;

    % Upload the data and engine family to the database
    fastinsert(conn,'[dbo].[tblDOE]',fields(DOETable),DOETable);

    % Close the database connection
    close(conn)