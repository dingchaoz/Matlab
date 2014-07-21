%% Threhsold Exporter
% This script will generate .mat export files of the calibratible parameters specified by
% filter file for the newest mainline calibrations for the specified engine families

% Each engine family in each program should be specified manually in the file, then the
% right things will be done on each to upload the data 

% Define the root of there suppdata is (so the filter file can be located)
r = '\\CIDCSDFS01\EBU_Data01$\NACTGx\common\DL_Diag\Data Analysis\Storage\suppdata';
% Define where locally to copy the mainline calibrations
l = '..\tempcal';
% Define where to store manual calibrations
manualCals = '\\CIDCSDFS01\EBU_Data01$\NACTGx\common\DL_Diag\Data Analysis\Storage\manualcals';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Mainline folders need to be kept up-to-date when programs move to different VPI phases %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Family Names must be a valid matlab variable, they cannot have spaces or start with a number %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You need to restart Matlab after running this or changes to the filter file won't work right %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Maybe add a check that if the date modified of the .xcal file is more than 2 weeks old
% throw a warning that this script may be pointed to an old mainline folder.

%% Pacific
% Pacific Root
pacificRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Dragnet_X';
% Pacific Default (use the Dragnet X1 as Default because it contains IAT stuff)
exportThresholds(r,l,fullfile(pacificRoot,'MY15_Beta\X1'),'HDPacific','Default','BDR')
% Pacific Dragnet X1
exportThresholds(r,l,fullfile(pacificRoot,'MY15_Beta\X1'),'HDPacific','DNET_X1','BDR')
% Pacific Dragnet X2 (this will be the same as X3)
exportThresholds(r,l,fullfile(pacificRoot,'MY15_Beta\X3'),'HDPacific','DNET_X2','BDR')
% Pacific Dragnet X3
exportThresholds(r,l,fullfile(pacificRoot,'MY15_Beta\X3'),'HDPacific','DNET_X3','BDR')
% Pacific Dragnet Black / X12(use LE3 as I think all OBD should be common across Black / X12)
exportThresholds(r,l,fullfile(pacificRoot,'MY15_Beta\12L LE3'),'HDPacific','DNET_Black','BDR')
% Pacific CPS X1
exportThresholds(r,l,fullfile(manualCals,'PacificCPS_X1'),'HDPacific','X1','BDR')
% Pacific CPS X2
exportThresholds(r,l,fullfile(manualCals,'PacificCPS_X3'),'HDPacific','X2','BDR')
% Pacific CPS X3
exportThresholds(r,l,fullfile(manualCals,'PacificCPS_X3'),'HDPacific','X3','BDR')
% Pacific CPS Black / X12
exportThresholds(r,l,fullfile(manualCals,'PacificCPS_Black'),'HDPacific','Black','BDR')

%% Acadia
% % Acadia Root
% acadiaRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Acadia';
% % Acadia Default
% exportThresholds(r,l,fullfile(acadiaRoot,'Aplha\X1'),'Acadia','Default','BGT')
% % Acadia X1
% exportThresholds(r,l,fullfile(acadiaRoot,'Alpha\X1'),'Acadia','Acadia_X1','BGT')
% % Acadia X3
% exportThresholds(r,l,fullfile(acadiaRoot,'Alpha\X3'),'Acadia','Acadia_X3','BGT')

%% Atlantic
% Atlantic Root
atlanticRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer\Atlantic Red';
% Atlatnic Default (here just use the highest rating
exportThresholds(r,l,fullfile(atlanticRoot,'FP\675_2100'),'Atlantic','Default','BEF')
% Highest power rating, may need to additional ones later on
exportThresholds(r,l,fullfile(atlanticRoot,'FP\675_2100'),'Atlantic','Atlantic','BEF')

%% Mamba
% Mamba Root
mambaRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer\Confidential\Mamba';
% Mamba Default (use the 460 family)
exportThresholds(r,l,fullfile(mambaRoot,'LP\460_2100'),'Mamba','Default','BGB')
% Main Mamba (use the 460 family)
exportThresholds(r,l,fullfile(mambaRoot,'LP\460_2100'),'Mamba','Mamba','BGB')
% Mamba 430 @ 2100
%%%exportThresholds(r,l,fullfile(mambaRoot,'Beta_Upfit\430_2100'),'Mamba','430_2100','BGB')
% Mamba 460 @ 2100
%%%exportThresholds(r,l,fullfile(mambaRoot,'Beta_Upfit\460_2100'),'Mamba','460_2100','BGB')

%% Pele
% Pele Root
peleRoot = '\\cidcsdfs01\ebu_data01$\NACTGx\fngroup_ctc\MR_Worldwide\Calbert_China\Pele';
% Pele Default (main Pele also)
exportThresholds(r,l,fullfile(peleRoot,'Development\Manual 125 kW'),'Pele','Default','BGK')
% Pele main export
exportThresholds(r,l,fullfile(peleRoot,'Development\Manual 125 kW'),'Pele','Pele','BGK')

%% DragonCC
% DragonCC Root
dragonccRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Dragnet_CC';
% DragonCC Default (use the Auto family)
exportThresholds(r,l,fullfile(dragonccRoot,'PV\DragnetCC_Auto'),'DragonCC','Default','BDC')
% Dragnet_CC (use the Auto family)
exportThresholds(r,l,fullfile(dragonccRoot,'PV\DragnetCC_Auto'),'DragonCC','Dragnet_CC','BDC')
% Plain Dragon Front (should update this to use a current product calibration)
exportThresholds(r,l,fullfile(dragonccRoot,'PV\DragnetCC_Auto'),'DragonCC','Dragon_Front','BDC')
% % DragonCC Auto
% exportThresholds(r,l,fullfile(dragonccRoot,'PV\DragnetCC_Auto'),'DragonCC','DragonCC_Auto','BDC')
% % DragonCC Manual
% exportThresholds(r,l,fullfile(dragonccRoot,'PV\DragnetCC_Man'),'DragonCC','DragonCC_Man','BDC')

%% DragonMR
% DragonMR Root
dragonmrRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Dragnet_B';
% DragonMR Default (use the B360 family)
exportThresholds(r,l,fullfile(dragonmrRoot,'MY15\B360'),'DragonMR','Default','BDH')
% Dragnet_B (use the B360 family)
exportThresholds(r,l,fullfile(dragonmrRoot,'MY15\B360'),'DragonMR','Dragnet_B','BDH')
% Plain Dragon Rear (should update this to use a current product calibration)
exportThresholds(r,l,fullfile(dragonmrRoot,'MY15\B360'),'DragonMR','Dragon_Rear','BDH')
% % DragonMR B260
% exportThresholds(r,l,fullfile(dragonmrRoot,'Alpha\B260'),'DragonMR','B260','BDH')
% % DragonMR B280Hyb
% exportThresholds(r,l,fullfile(dragonmrRoot,'Alpha\B280Hyb'),'DragonMR','B280Hyb','BDH')
% % DragonMR B360
% exportThresholds(r,l,fullfile(dragonmrRoot,'Alpha\B360'),'DragonMR','B360','BDH')

%% Seahawk
% Seahawk Root
seahawkRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Dragnet_PU';
% Seahawk Default (use the Auto family)
exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Auto'),'Seahawk','Default','BDC')
% Dragnet_PU (use the Auto family)
exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Auto'),'Seahawk','Dragnet_PU','BDC')
% Plain Seahawk (should update this to use a current product calibration)
exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Auto'),'Seahawk','Seahawk','BDC')
% % Seahawk Auto
% exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Auto'),'Seahawk','DragnetPU_Auto','BDC')
% % Seahawk Auto Aisin
% exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Auto_Aisin'),'Seahawk','DragnetPU_Auto_Aisin','BDC')
% % Seahawk Manual
% exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Man'),'Seahawk','DragnetPU_Man','BDC')

%% Yukon
% Yukon Root
yukonRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Dragnet_L';
% Yukon Default (use the L450 family)
exportThresholds(r,l,fullfile(yukonRoot,'MY15\L450'),'Yukon','Default','BDO')
% Yukon Dragnet_L (use the L450 family)
exportThresholds(r,l,fullfile(yukonRoot,'MY15\L450'),'Yukon','Dragnet_L','BDO')
% Plain Yukon  (should update this to use a current product calibration)
exportThresholds(r,l,fullfile(yukonRoot,'MY15\L450'),'Yukon','Yukon','BDO')
% % DragonMR L330UBus
% exportThresholds(r,l,fullfile(yukonRoot,'Alpha\L330UBus'),'Yukon','L330UBus','BDO')
% % DragonMR L350
% exportThresholds(r,l,fullfile(yukonRoot,'Alpha\L350'),'Yukon','L350','BDO')
% % DragonMR L450
% exportThresholds(r,l,fullfile(yukonRoot,'Alpha\L450'),'Yukon','L450','BDO')

%% Vanguard
% Vanguard Root
vanguardRoot = '\\CIDCSDFS01\EBU_Data01$\NACEPx\LDD Test Data\Calibrations3230\Vanguard\In Progress';
% Vanguard Default (use In Progress)
exportThresholds(r,l,fullfile(manualCals,'Vanguard'),'Vanguard','Default','BCX')

%% Ventura
% Ventura Root
venturaRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Ventura';
% Ventura Default (use the Alpha Mainline family)
exportThresholds(r,l,fullfile(venturaRoot,'Alpha\Mainline'),'Ventura','Default','BFY')

%% Blazer
BlazerRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer\Blazer';
% Blazer Default
exportThresholds(r,l,fullfile(BlazerRoot,'LP\140_2200_FEL'),'Blazer','Default','BFU')

%% Bronco
BroncoRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer';
% Bronco Default
exportThresholds(r,l,fullfile(BroncoRoot,'Workhorse Bronco Lite\LP\173_2300'),'Bronco','Default','BEE')
%  Bronco Lite
exportThresholds(r,l,fullfile(BroncoRoot,'Workhorse Bronco Lite\LP\173_2300_FEL'),'Bronco','Bronco_Lite','BEE')
% Bronco
exportThresholds(r,l,fullfile(BroncoRoot,'Workhorse Bronco\PP1_GPU\225_2000'),'Bronco','Bronco','BEE')

%% Clydesdale
ClydesdaleRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer\Workhorse Clydesdale';
% Clydesdale Default
exportThresholds(r,l,fullfile(ClydesdaleRoot,'PP1\380_2100_SG'),'Clydesdale','Default','BEG')

%% Shadowfax
ShadowfaxRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer\Shadowfax';
% Shadowfax Default
exportThresholds(r,l,fullfile(ShadowfaxRoot,'LP\130_2500'),'Shadowfax','Default','BFV')

%% Copy output to correct location (do this for compatibility reasons at the present time)
% Copy those outputs to the @SQLProcessor folder for its useage
copyfile(fullfile(l,'HDPacific\X1\X1_export.mat'),'D:\Matlab\Capability\code\@CalParameters\calParamsX1.mat');
copyfile(fullfile(l,'HDPacific\X3\X3_export.mat'),'D:\Matlab\Capability\code\@CalParameters\calParamsX3.mat');
copyfile(fullfile(l,'HDPacific\Black\Black_export.mat'),'D:\Matlab\Capability\code\@CalParameters\calParamsBlack.mat');
% Copy the Atlatnic one to the correct spot
copyfile(fullfile(l,'Atlantic\Atlantic\Atlantic_export.mat'),'D:\Matlab\Capability\codeAtl\@CalParameters\calParamsAtlantic.mat');
