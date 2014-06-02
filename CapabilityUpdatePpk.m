% Run UpdatePrecalc results for these all

% Pacific
a = tic;
Pacific = Capability('Pacific');
Pacific.updatePrecalcResults;
clear Pacific
progTime.Pacific = toc(a);

% Acadia
% a = tic;
% Acadia = Capability('Acadia');
% Acadia.updatePrecalcResults;
% clear Acadia
% progTime.Acadia = toc(a);

% Atlantic
a = tic;
Atlantic = Capability('Atlantic');
Atlantic.updatePrecalcResults;
clear Atlantic
progTime.Atlantic = toc(a);

% Mamba
a = tic;
Mamba = Capability('Mamba');
Mamba.updatePrecalcResults;
clear Mamba
progTime.Mamba = toc(a);

% Pele
a = tic;
Pele = Capability('Pele');
Pele.updatePrecalcResults;
clear Pele
progTime.Pele = toc(a);

% DragonCC
a = tic;
DragonCC = Capability('DragonCC');
DragonCC.updatePrecalcResults;
clear DragonCC
progTime.DragonCC = toc(a);

% DragonMR
a = tic;
DragonMR = Capability('DragonMR');
DragonMR.updatePrecalcResults;
clear DragonMR
progTime.DragonMR = toc(a);

% Seahawk
a = tic;
Seahawk = Capability('Seahawk');
Seahawk.updatePrecalcResults;
clear Seahawk
progTime.Seahawk = toc(a);

% Yukon
a = tic;
Yukon = Capability('Yukon');
Yukon.updatePrecalcResults;
clear Yukon
progTime.Yukon = toc(a);

% Blazer
a = tic;
Blazer = Capability('Blazer');
Blazer.updatePrecalcResults;
clear Blazer
progTime.Blazer = toc(a);

% Bronco
a = tic;
Bronco = Capability('Bronco');
Bronco.updatePrecalcResults;
clear Bronco
progTime.Bronco = toc(a);

% Clydesdale
a = tic;
Clydesdale = Capability('Clydesdale');
Clydesdale.updatePrecalcResults;
clear Clydesdale
progTime.Clydesdale = toc(a);

% Shadowfax
a = tic;
Shadowfax = Capability('Shadowfax');
Shadowfax.updatePrecalcResults;
clear Shadowfax
progTime.Shadowfax = toc(a);

% Vanguard
a = tic;
Vanguard = Capability('Vanguard');
Vanguard.updatePrecalcResults;
clear Vanguard
progTime.Vanguard = toc(a);

% Ventura
a = tic;
Ventura = Capability('Ventura');
Ventura.updatePrecalcResults;
clear Ventura
progTime.Ventura = toc(a);

% Show the seconds for each program
progTime

%% Times to Run April 13, 2014
%      Pacific: 4728.43055957155
%     Atlantic: 216.118795513811
%        Mamba: 67.5229200960277
%         Pele: 54.598779620497
%     DragonCC: 1129.08849237221
%     DragonMR: 1911.61067423046
%      Seahawk: 2669.82019185501
%        Yukon: 2486.95632677456
