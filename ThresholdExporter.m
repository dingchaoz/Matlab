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
exportThresholds(r,l,fullfile(pacificRoot,'MY16_Beta\X1'),'HDPacific','Default','BDR')
% Pacific Dragnet X1
exportThresholds(r,l,fullfile(pacificRoot,'MY16_Beta\X1'),'HDPacific','DNET_X1','BDR')
% Pacific Dragnet X2 (this will be the same as X3)
exportThresholds(r,l,fullfile(pacificRoot,'MY16_Beta\X3'),'HDPacific','DNET_X2','BDR')
% Pacific Dragnet X3
exportThresholds(r,l,fullfile(pacificRoot,'MY16_Beta\X3'),'HDPacific','DNET_X3','BDR')
% Pacific Dragnet Black / X12(use LE3 as I think all OBD should be common across Black / X12)
exportThresholds(r,l,fullfile(pacificRoot,'MY16_Beta\12L_LE3'),'HDPacific','DNET_Black','BDR')
% Pacific CPS X1
exportThresholds(r,l,fullfile(manualCals,'PacificCPS_X1'),'HDPacific','X1','BDR')
% Pacific CPS X2
exportThresholds(r,l,fullfile(manualCals,'PacificCPS_X3'),'HDPacific','X2','BDR')
% Pacific CPS X3
exportThresholds(r,l,fullfile(manualCals,'PacificCPS_X3'),'HDPacific','X3','BDR')
% Pacific CPS Black / X12
exportThresholds(r,l,fullfile(manualCals,'PacificCPS_Black'),'HDPacific','Black','BDR')

%% Acadia
% Acadia Root
acadiaRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Acadia';
% Acadia Default
exportThresholds(r,l,fullfile(acadiaRoot,'Beta\X1'),'Acadia','Default','BGT')
% Acadia X1
exportThresholds(r,l,fullfile(acadiaRoot,'Beta\X1'),'Acadia','Acadia_X1','BGT')
% Acadia X3
exportThresholds(r,l,fullfile(acadiaRoot,'Beta\X3'),'Acadia','Acadia_X3','BGT')

%% Atlantic
% Atlantic Root
atlanticRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer\Atlantic Red';
% Atlatnic Default (here just use the highest rating
exportThresholds(r,l,fullfile(atlanticRoot,'DIG\675_2100'),'Atlantic','Default','BEF')
% Highest power rating, may need to additional ones later on
exportThresholds(r,l,fullfile(atlanticRoot,'DIG\675_2100'),'Atlantic','Atlantic','BEF')

%% Mamba
% Mamba Root
mambaRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer\Confidential\Mamba';
% Mamba Default (use the 460 family)
exportThresholds(r,l,fullfile(mambaRoot,'DIG\460_2100'),'Mamba','Default','BGB')
% Main Mamba (use the 460 family)
exportThresholds(r,l,fullfile(mambaRoot,'DIG\460_2100'),'Mamba','Mamba','BGB')
% Mamba 430 @ 2100
%%%exportThresholds(r,l,fullfile(mambaRoot,'Beta_Upfit\430_2100'),'Mamba','430_2100','BGB')
% Mamba 460 @ 2100
%%%exportThresholds(r,l,fullfile(mambaRoot,'Beta_Upfit\460_2100'),'Mamba','460_2100','BGB')

%% Pele
% Pele Root
peleRoot = '\\cidcsdfs01\ebu_data01$\NACTGx\fngroup_ctc\MR_Worldwide\Calbert_China\Pele2';
% Pele Default (main Pele also)
exportThresholds(r,l,fullfile(peleRoot,'Development\Foton - Manual 125 kW'),'Pele','Default','BGK')
% Pele main export
exportThresholds(r,l,fullfile(peleRoot,'Development\Foton - Manual 125 kW'),'Pele','Pele','BGK')

%% DragonCC
% DragonCC Root
dragonccRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Dragnet_CC';
% DragonCC Default (use the Auto family)
exportThresholds(r,l,fullfile(dragonccRoot,'MY17\DragnetCC_Auto'),'DragonCC','Default','BDC')
% Dragnet_CC (use the Auto family)
exportThresholds(r,l,fullfile(dragonccRoot,'PV\DragnetCC_Auto'),'DragonCC','Dragnet_CC','BDC')
% Dragnet_CC_16 (use the Auto family)
exportThresholds(r,l,fullfile(dragonccRoot,'MY16\DragnetCC_Auto'),'DragonCC','Dragnet_CC_16','BDC')
% Dragnet_CC_16.5 (use the Auto family)
exportThresholds(r,l,fullfile(dragonccRoot,'MY16.5\DD_Auto'),'DragonCC','Dragnet_CC_16_5','BDC')
% Plain Dragon Front (should update this to use a current product calibration)
exportThresholds(r,l,fullfile(dragonccRoot,'PV\DragnetCC_Auto'),'DragonCC','DragonCC','BDC')
% % DragonCC Auto
% exportThresholds(r,l,fullfile(dragonccRoot,'PV\DragnetCC_Auto'),'DragonCC','DragonCC_Auto','BDC')
% % DragonCC Manual
% exportThresholds(r,l,fullfile(dragonccRoot,'PV\DragnetCC_Man'),'DragonCC','DragonCC_Man','BDC')

%% Vulture
% Vulture Root
VultureRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Vulture';
% Vulture Default (use the FE family as default)
exportThresholds(r,l,fullfile(VultureRoot,'MY19\Vulture_FE'),'Vulture','Default','BHQ')
%Vulture_FE
exportThresholds(r,l,fullfile(VultureRoot,'MY19\Vulture_FE'),'Vulture','Vulture_FE','BHQ')
%Vulture_HO
exportThresholds(r,l,fullfile(VultureRoot,'MY19\Vulture_HO'),'Vulture','Vulture_HO','BHQ')

%% Thunderbolt
% Thunderbolt Root
ThunderboltRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Dragnet_CC';
% Thunderbolt Default (use the CC_Auto family as default)
exportThresholds(r,l,fullfile(ThunderboltRoot,'MY19\CC_Auto'),'Thunderbolt','Default','BHQ')
% Thunderbolt CC_Auto
exportThresholds(r,l,fullfile(ThunderboltRoot,'MY19\CC_Auto'),'Thunderbolt','Thunderbolt_CC_Auto','BHQ')

%% DragonMR
% DragonMR Root
dragonmrRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Dragnet_B';
% DragonMR Default (use the B360 family)
exportThresholds(r,l,fullfile(dragonmrRoot,'MY16\B360'),'DragonMR','Default','BDH')
% Dragnet_B (use the B360 family)
exportThresholds(r,l,fullfile(dragonmrRoot,'MY15_PP2\B360'),'DragonMR','Dragnet_B','BDH')
% Dragnet_B_16 (use the B360 family)
exportThresholds(r,l,fullfile(dragonmrRoot,'MY16\B360'),'DragonMR','Dragnet_B_16','BDH')
% Plain Dragon Rear (should update this to use a current product calibration)
exportThresholds(r,l,fullfile(dragonmrRoot,'MY15_PP2\B360'),'DragonMR','DragonMR','BDH')
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
exportThresholds(r,l,fullfile(seahawkRoot,'MY17\DragnetPU_Auto'),'Seahawk','Default','BDC')
% Dragnet_PU (use the Auto family)
exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Auto'),'Seahawk','Dragnet_PU','BDC')
% Dragnet_PU_16 (use the Auto family)
exportThresholds(r,l,fullfile(seahawkRoot,'MY16\DragnetPU_Auto'),'Seahawk','Dragnet_PU_16','BDC')
% Dragnet_PU_17 (use the Auto family)
exportThresholds(r,l,fullfile(seahawkRoot,'MY17\DragnetPU_Auto'),'Seahawk','Dragnet_PU_17','BDC')
% Plain Seahawk (should update this to use a current product calibration)
exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Auto'),'Seahawk','Seahawk','BDC')
% % Seahawk Auto
% exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Auto'),'Seahawk','DragnetPU_Auto','BDC')
% % Seahawk Auto Aisin
% exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Auto_Aisin'),'Seahawk','DragnetPU_Auto_Aisin','BDC')
% % Seahawk Manual
% exportThresholds(r,l,fullfile(seahawkRoot,'PV\DragnetPU_Man'),'Seahawk','DragnetPU_Man','BDC')

%% Sierra
% Sierra Root 
sierraRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Sierra_L';
% Sierra Default (use the 450)
exportThresholds(r,l,fullfile(sierraRoot,'MY17\L450'),'Sierra','Default','BGV')
% Sierra HybUBus (use the 330HybUBus)
exportThresholds(r,l,fullfile(sierraRoot,'MY17\L330HybUBus'),'Sierra','HybUBus','BGV')
% Sierra UBus (use the 330UBus)
exportThresholds(r,l,fullfile(sierraRoot,'MY17\L330UBus'),'Sierra','UBus','BGV')
% Sierra HT (use the 350HT)
exportThresholds(r,l,fullfile(sierraRoot,'MY17\L350_HT'),'Sierra','HT','BGV')
% Sierra Hyb (use the 370Hyb)
exportThresholds(r,l,fullfile(sierraRoot,'MY17\L370Hyb'),'Sierra','Hyb','BGV')

%% Yukon
% Yukon Root
yukonRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Dragnet_L';
% Yukon Default (use the L450 family)
exportThresholds(r,l,fullfile(yukonRoot,'MY16\L450'),'Yukon','Default','BDO')
% Yukon Dragnet_L (use the L450 family)
exportThresholds(r,l,fullfile(yukonRoot,'MY15_PP2\L450'),'Yukon','Dragnet_L','BDO')
% Yukon Dragnet_L_16 (use the L450 family)
exportThresholds(r,l,fullfile(yukonRoot,'MY16\L450'),'Yukon','Dragnet_L_16','BDO')
% Plain Yukon  (should update this to use a current product calibration)
exportThresholds(r,l,fullfile(yukonRoot,'MY15_PP2\L450'),'Yukon','Yukon','BDO')
% % DragonMR L330UBus
% exportThresholds(r,l,fullfile(yukonRoot,'Alpha\L330UBus'),'Yukon','L330UBus','BDO')
% % DragonMR L350
% exportThresholds(r,l,fullfile(yukonRoot,'Alpha\L350'),'Yukon','L350','BDO')
% % DragonMR L450
% exportThresholds(r,l,fullfile(yukonRoot,'Alpha\L450'),'Yukon','L450','BDO')

%% Nighthawk
% Nighthawk Root
nighthawkRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Nighthawk_B';
% Nighthawk Default (use the B260 family)
exportThresholds(r,l,fullfile(nighthawkRoot,'MY17\B260_LHP_Beta'),'Nighthawk','Default','BGU')
% Nighthawk_LHP (use the B260 family)
exportThresholds(r,l,fullfile(nighthawkRoot,'MY17\B260_LHP_Beta'),'Nighthawk','Nighthawk_LHP','BGU')
% Nighthawk_MHP (use the B325 family)
exportThresholds(r,l,fullfile(nighthawkRoot,'MY17\B325_MHP_Beta'),'Nighthawk','Nighthawk_MHP','BGU')
% Nighthawk_HHP (use the B360 family)
exportThresholds(r,l,fullfile(nighthawkRoot,'MY17\B360_HHP_Beta'),'Nighthawk','Nighthawk_HHP','BGU')

%% Ayrton
% Ayrton Root
ayrtonRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\MR_Worldwide_2\Ayrton';
% Ayrton Default (use the 96kW FOTON family)
exportThresholds(r,l,fullfile(ayrtonRoot,'Development\Manual_96 kW FOTON'),'Ayrton','Default','BGY')
% Ayrton FOTON
exportThresholds(r,l,fullfile(ayrtonRoot,'Development\Manual_96 kW FOTON'),'Ayrton','Foton','BGY')
% Ayrton Gaas 96 kw
exportThresholds(r,l,fullfile(ayrtonRoot,'Development\Manual_96 kW GAZ'),'Ayrton','Gaas','BGY')
% Ayrton Gaas 120 kw
exportThresholds(r,l,fullfile(ayrtonRoot,'Development\Manual_120 kW GAZ'),'Ayrton','Ayrton_120KW_GAZ','BGY')
% Ayrton Foton 130 kw
exportThresholds(r,l,fullfile(ayrtonRoot,'Development\Manual_130 kW FOTON'),'Ayrton','Ayrton_130KW_FOTON','BGY')

%% Vanguard
% Vanguard Root
% vanguardRoot = '\\CIDCSDFS01\EBU_Data01$\NACEPx\LDD Test Data\Calibrations3230\Vanguard\In Progress';
vanguardRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Vanguard';
% Vanguard Default (use In Progress)
% exportThresholds(r,l,fullfile(manualCals,'Vanguard'),'Vanguard','Default','BCX')
exportThresholds(r,l,fullfile(vanguardRoot,'MY16\Mainline'),'Vanguard','Default','BCX')

%% Ventura
% Ventura Root
venturaRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Ventura';
% Ventura2 Root
ventura2Root = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\HMLDE_Calibrations\Calbert\Ventura_II';
% Ventura Default (use the Alpha Mainline family)
exportThresholds(r,l,fullfile(venturaRoot,'MY15\Ve_ISV200'),'Ventura','Default','BFY')
% Ventura2 (use the Ventura2_MY16 Mainline family)
exportThresholds(r,l,fullfile(ventura2Root,'MY16\Ve2_ISV200hp'),'Ventura','Ventura2','BFY')

%% Blazer
blazerRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer\Blazer';
% Blazer Default
exportThresholds(r,l,fullfile(blazerRoot,'DIG\173_2500'),'Blazer','Default','BFU')

%% Bronco
broncoRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer';
% Bronco Default
exportThresholds(r,l,fullfile(broncoRoot,'Workhorse Bronco\DIG\300_2500'),'Bronco','Default','BEE')
% Bronco Lite
exportThresholds(r,l,fullfile(broncoRoot,'Workhorse Bronco Lite\FP\173_2300'),'Bronco','Bronco_Lite','BEE')
% Bronco
exportThresholds(r,l,fullfile(broncoRoot,'Workhorse Bronco\DIG\300_2500'),'Bronco','Bronco','BEE')

%% Clydesdale
clydesdaleRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer\Workhorse Clydesdale';
% Clydesdale Default
exportThresholds(r,l,fullfile(clydesdaleRoot,'DIG\380_2100_AP'),'Clydesdale','Default','BEG')

%% Shadowfax
shadowfaxRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\Off Highway Electronics VPI SW And Cal Integration\Cal Team\CalServer\Shadowfax';
% Shadowfax Default
exportThresholds(r,l,fullfile(shadowfaxRoot,'PP2_Recycle\130_2500'),'Shadowfax','Default','BFV')

%% Copy output to correct location (do this for compatibility reasons at the present time)
% % Copy those outputs to the @SQLProcessor folder for its useage
% copyfile(fullfile(l,'HDPacific\X1\X1_export.mat'),'D:\Matlab\Capability\code\@CalParameters\calParamsX1.mat');
% copyfile(fullfile(l,'HDPacific\X3\X3_export.mat'),'D:\Matlab\Capability\code\@CalParameters\calParamsX3.mat');
% copyfile(fullfile(l,'HDPacific\Black\Black_export.mat'),'D:\Matlab\Capability\code\@CalParameters\calParamsBlack.mat');
% % Copy the Atlatnic one to the correct spot
% copyfile(fullfile(l,'Atlantic\Atlantic\Atlantic_export.mat'),'D:\Matlab\Capability\codeAtl\@CalParameters\calParamsAtlantic.mat');
