%% Upload capability data for all programs
% Possibly in the future this can use one lab per program to do the data processing faster
% Otherwise, multiple Matlab's can be opened with each Matlab doing one program at a time

% Work on Pacific
Pacific = CapabilityUploader('HDPacific');
Pacific.dataUploader;
clear Pacific

% Work on Acadia
Acadia = CapabilityUploader('Acadia');
Acadia.dataUploader;
clear Acadia

% Work on Atlatnic
Atlantic = CapabilityUploader('Atlantic');
Atlantic.dataUploader;
clear Atlantic

% Work on Ayrton
Ayrton = CapabilityUploader('Ayrton');
Ayrton.dataUploader;
clear Ayrton

% Work on Mamba
Mamba = CapabilityUploader('Mamba');
Mamba.dataUploader;
clear Mamba

% % Copy Pele data to ETD_Data
% MovePeleCapData

% Work on Pele
Pele = CapabilityUploader('Pele');
Pele.dataUploader;
clear Pele

% Sync Processed MR Data
MoveMRCapData

% Work on DragonCC
DragonCC = CapabilityUploader('DragonCC');
DragonCC.dataUploader;
clear DragonCC

% Work on DragonMR
DragonMR = CapabilityUploader('DragonMR');
DragonMR.dataUploader;
clear DragonMR

% Work on Seahawk
Seahawk = CapabilityUploader('Seahawk');
Seahawk.dataUploader;
clear Seahawk

% Work on Yukon
Yukon = CapabilityUploader('Yukon');
Yukon.dataUploader;
clear Yukon

% Work on Nighthawk
Nighthawk = CapabilityUploader('Nighthawk');
Nighthawk.dataUploader;
clear Nighthawk

% Work on Sierra
Sierra = CapabilityUploader('Sierra');
Sierra.dataUploader;
clear Sierra

% Vulture
Vulture = CapabilityUploader('Vulture');
Vulture.dataUploader;
clear Vulture

% Thunderbolt
Thunderbolt = CapabilityUploader('Thunderbolt');
Thunderbolt.dataUploader;
clear Thunderbolt

% Move the MR Industrial Data
MoveMRIndCapData

% Blazer
Blazer = CapabilityUploader('Blazer');
Blazer.dataUploader;
clear Blazer

% Bronco
Bronco = CapabilityUploader('Bronco');
Bronco.dataUploader;
clear Bronco

% Clydesdale
Clydesdale = CapabilityUploader('Clydesdale');
Clydesdale.dataUploader;
clear Clydesdale

% Shadowfax
Shadowfax = CapabilityUploader('Shadowfax');
Shadowfax.dataUploader;
clear Shadowfax

% % Move the V8 data
% MoveV8CapData

% Vanguard
Vanguard = CapabilityUploader('Vanguard');
Vanguard.dataUploader;
clear Vanguard

% Ventura
Ventura = CapabilityUploader('Ventura');
Ventura.dataUploader;
clear Ventura
