% Reads and processes data from 'rf2412Data.xlsx'

function processData()

    % excelImport = 1 to import from '.xlsx' (slow, run at least once if data has been updated)
    % excelImport = 0 to import from .mat (fast)
    excelImport = 0;    

    % Import data
    [rf2412,rf5240] = importDataRuns(excelImport);
    
    % Loss models
    [rf2412,rf5240] = lossModels(rf2412,rf5240);
    
    % Plot stuff
    plot2by2(rf2412,rf5240);
    
    % Assign to workspace
    assignin('base','rf2412',rf2412);
    assignin('base','rf5240',rf5240);
    
end

function [rf2412,rf5240] = importDataRuns(excelImport)

    if excelImport == 1
       
        % Import data, assign to organized structure
        rf2412 = data2struct('rf2412Data.xlsx');
        rf5240 = data2struct('rf5240Data.xlsx');

        % Fix time stamps on data
        rf2412 = fixGpsTimeStamps(rf2412);
        rf5240 = fixGpsTimeStamps(rf5240);

        % Calculate distance
        rf2412 = calculateDistance(rf2412);
        rf5240 = calculateDistance(rf5240);

        % Synchronize time series from groundGps, robotGps, and rssi
        rf2412 = syncTimes(rf2412);
        rf5240 = syncTimes(rf5240);
        
    else
        
        % Alternatively, load the *.mat files
        load('rf2412.mat');
        load('rf5240.mat');
        
    end
    
    % 2.412 GHz data constants
    rf2412.freq = 2.412*1E9;    % frequency [Hz]
    rf2412.hr = 2;              % receiver height [m]
    rf2412.ht.m2 = 2;           % transmitter height 1 [m]
    rf2412.ht.m5 = 4.51;        % transmitter height 2 [m]
    rf2412.Pt = 15;             % transmit power [dBm]
    rf2412.Gt = 8;              % receiver antenna gain [dBi]
    rf2412.Gr = 8;              % transmitter antenna gain [dBi]
    
    % 5.240 GHz data constants
    rf5240.freq = 5.240*1E9;    % frequency [Hz]
    rf5240.hr = 2;              % receiver height [m]
    rf5240.ht.m2 = 2;           % transmitter height 1 [m]
    rf5240.ht.m5 = 4.51;        % transmitter height 2 [m]
    rf5240.Pt = 10;             % transmit power [dBm]
    rf5240.Gt = 13;             % receiver antenna gain [dBi]
    rf5240.Gr = 13;             % transmitter antenna gain [dBi]
    
    % Save to file
    save('rf2412.mat','rf2412');
    save('rf5240.mat','rf5240');    

end

function rf = data2struct(filename)

    % Read file
    rawData = readmatrix(filename);

    % Assign to organized structure
    rf.land.m2.robot.time = rmmissing(rawData(:,1)*1E-9);
    rf.land.m2.robot.lat = rmmissing(rawData(:,2));
    rf.land.m2.robot.lon = rmmissing(rawData(:,3));
    rf.land.m2.ground.time = rmmissing(rawData(:,4)*1E-9);
    rf.land.m2.ground.lat = rmmissing(rawData(:,5));
    rf.land.m2.ground.lon = rmmissing(rawData(:,6));
    rf.land.m2.rssiHms = rmmissing(rawData(:,7));
    rf.land.m2.rssiHmsDiff = rmmissing(rawData(:,8));
    rf.land.m2.rssiTime = rmmissing(rawData(:,9));
    rf.land.m2.rssi1 = rmmissing(rawData(:,10));
    rf.land.m2.rssi2 = rmmissing(rawData(:,11));
    rf.sea.m2.robot.time = rmmissing(rawData(:,12)*1E-9);
    rf.sea.m2.robot.lat = rmmissing(rawData(:,13));
    rf.sea.m2.robot.lon = rmmissing(rawData(:,14));
    rf.sea.m2.ground.time = rmmissing(rawData(:,15)*1E-9);
    rf.sea.m2.ground.lat = rmmissing(rawData(:,16));
    rf.sea.m2.ground.lon = rmmissing(rawData(:,17));
    rf.sea.m2.rssiHms = rmmissing(rawData(:,18));
    rf.sea.m2.rssiHmsDiff = rmmissing(rawData(:,19));
    rf.sea.m2.rssiTime = rmmissing(rawData(:,20));
    rf.sea.m2.rssi1 = rmmissing(rawData(:,21));
    rf.sea.m2.rssi2 = rmmissing(rawData(:,22));
    rf.land.m5.robot.time = rmmissing(rawData(:,23)*1E-9);
    rf.land.m5.robot.lat = rmmissing(rawData(:,24));
    rf.land.m5.robot.lon = rmmissing(rawData(:,25));
    rf.land.m5.ground.time = rmmissing(rawData(:,26)*1E-9);
    rf.land.m5.ground.lat = rmmissing(rawData(:,27));
    rf.land.m5.ground.lon = rmmissing(rawData(:,28));
    rf.land.m5.rssiHms = rmmissing(rawData(:,29));
    rf.land.m5.rssiHmsDiff = rmmissing(rawData(:,30));
    rf.land.m5.rssiTime = rmmissing(rawData(:,31));
    rf.land.m5.rssi1 = rmmissing(rawData(:,32));
    rf.land.m5.rssi2 = rmmissing(rawData(:,33));
    rf.sea.m5.robot.time = rmmissing(rawData(:,34)*1E-9);
    rf.sea.m5.robot.lat = rmmissing(rawData(:,35));
    rf.sea.m5.robot.lon = rmmissing(rawData(:,36));
    rf.sea.m5.ground.time = rmmissing(rawData(:,37)*1E-9);
    rf.sea.m5.ground.lat = rmmissing(rawData(:,38));
    rf.sea.m5.ground.lon = rmmissing(rawData(:,39));
    rf.sea.m5.rssiHms = rmmissing(rawData(:,40));
    rf.sea.m5.rssiHmsDiff = rmmissing(rawData(:,41));
    rf.sea.m5.rssiTime = rmmissing(rawData(:,42));
    rf.sea.m5.rssi1 = rmmissing(rawData(:,43));
    rf.sea.m5.rssi2 = rmmissing(rawData(:,44));
    
end

function rf = fixGpsTimeStamps(rf)

    % Sync land m2 data
    if rf.land.m2.robot.time(1,1) > rf.land.m2.ground.time(1,1)
        start = rf.land.m2.ground.time(1,1);
    else
        start = rf.land.m2.robot.time(1,1);
    end
    rf.land.m2.robot.time = rf.land.m2.robot.time-start;
    rf.land.m2.ground.time = rf.land.m2.ground.time-start;
    
    % Sync sea m2 data
    if rf.sea.m2.robot.time(1,1) > rf.sea.m2.ground.time(1,1)
        start = rf.sea.m2.ground.time(1,1);
    else
        start = rf.sea.m2.robot.time(1,1);
    end
    rf.sea.m2.robot.time = rf.sea.m2.robot.time-start;
    rf.sea.m2.ground.time = rf.sea.m2.ground.time-start;
    
    % Sync land m5 data
    if rf.land.m5.robot.time(1,1) > rf.land.m5.ground.time(1,1)
        start = rf.land.m5.ground.time(1,1);
    else
        start = rf.land.m5.robot.time(1,1);
    end
    rf.land.m5.robot.time = rf.land.m5.robot.time-start;
    rf.land.m5.ground.time = rf.land.m5.ground.time-start;
    
    % Sync sea m5 data
    if rf.sea.m5.robot.time(1,1) > rf.sea.m5.ground.time(1,1)
        start = rf.sea.m5.ground.time(1,1);
    else
        start = rf.sea.m5.robot.time(1,1);
    end
    rf.sea.m5.robot.time = rf.sea.m5.robot.time-start;
    rf.sea.m5.ground.time = rf.sea.m5.ground.time-start;
    
end

function rf = calculateDistance(rf)

    % land m2 distance calculation
    llo = [rf.land.m2.ground.lat(1,1),...
        rf.land.m2.ground.lon(1,1)];
    lla = [rf.land.m2.robot.lat(:,1),...
        rf.land.m2.robot.lon(:,1),...
        zeros(size(rf.land.m2.robot.lat(:,1)))];
    flat = lla2flat(lla,llo,0,0);
    rf.land.m2.dist = sqrt(flat(:,1).^2+flat(:,2).^2);
    
    % sea m2 distance calculation
    llo = [rf.sea.m2.ground.lat(1,1),...
        rf.sea.m2.ground.lon(1,1)];
    lla = [rf.sea.m2.robot.lat(:,1),...
        rf.sea.m2.robot.lon(:,1),...
        zeros(size(rf.sea.m2.robot.lat(:,1)))];
    flat = lla2flat(lla,llo,0,0);
    rf.sea.m2.dist = sqrt(flat(:,1).^2+flat(:,2).^2);
    
    % land m5 distance calculation
    llo = [rf.land.m5.ground.lat(1,1),...
        rf.land.m5.ground.lon(1,1)];
    lla = [rf.land.m5.robot.lat(:,1),...
        rf.land.m5.robot.lon(:,1),...
        zeros(size(rf.land.m5.robot.lat(:,1)))];
    flat = lla2flat(lla,llo,0,0);
    rf.land.m5.dist = sqrt(flat(:,1).^2+flat(:,2).^2);
    
    % sea m5 distance calculation
    llo = [rf.sea.m5.ground.lat(1,1),...
        rf.sea.m5.ground.lon(1,1)];
    lla = [rf.sea.m5.robot.lat(:,1),...
        rf.sea.m5.robot.lon(:,1),...
        zeros(size(rf.sea.m5.robot.lat(:,1)))];
    flat = lla2flat(lla,llo,0,0);
    rf.sea.m5.dist = sqrt(flat(:,1).^2+flat(:,2).^2);

end

function rf = syncTimes(rf)

    % land m2 dist-to-rssiTime synchronization
    rf.land.m2.dsDist = tVec2datestring(rf.land.m2.ground.time);    % distance datestring variable (based on ground station timestamp)
    rf.land.m2.dsRssi = tVec2datestring(rf.land.m2.rssiTime);       % rssi datestring variable (based on rssi timestamp)
    rf.land.m2.tsDist = timeseries(rf.land.m2.dist,...              % distance timeseries variable
        rf.land.m2.dsDist);
    rf.land.m2.tsRssi = timeseries([rf.land.m2.rssi1,...            % rssi timeseries variable
        rf.land.m2.rssi2],...
        rf.land.m2.dsRssi);
    [rf.land.m2.tsDist,rf.land.m2.tsRssi] = synchronize(...
        rf.land.m2.tsDist,...
        rf.land.m2.tsRssi,...
        'union');

    % sea m2 dist-to-rssiTime synchronization
    rf.sea.m2.dsDist = tVec2datestring(rf.sea.m2.ground.time);      % distance datestring variable (based on ground station timestamp)
    rf.sea.m2.dsRssi = tVec2datestring(rf.sea.m2.rssiTime);         % rssi datestring variable (based on rssi timestamp)
    rf.sea.m2.tsDist = timeseries(rf.sea.m2.dist,...                % distance timeseries variable
        rf.sea.m2.dsDist);
    rf.sea.m2.tsRssi = timeseries([rf.sea.m2.rssi1,...              % rssi timeseries variable
        rf.sea.m2.rssi2],...
        rf.sea.m2.dsRssi);
    [rf.sea.m2.tsDist,rf.sea.m2.tsRssi] = synchronize(...
        rf.sea.m2.tsDist,...
        rf.sea.m2.tsRssi,...
        'union');
    
    % land m5 dist-to-rssiTime synchronization
    rf.land.m5.dsDist = tVec2datestring(rf.land.m5.ground.time);    % distance datestring variable (based on ground station timestamp)
    rf.land.m5.dsRssi = tVec2datestring(rf.land.m5.rssiTime);       % rssi datestring variable (based on rssi timestamp)
    rf.land.m5.tsDist = timeseries(rf.land.m5.dist,...              % distance timeseries variable
        rf.land.m5.dsDist);
    rf.land.m5.tsRssi = timeseries([rf.land.m5.rssi1,...            % rssi timeseries variable
        rf.land.m5.rssi2],...
        rf.land.m5.dsRssi);
    [rf.land.m5.tsDist,rf.land.m5.tsRssi] = synchronize(...
        rf.land.m5.tsDist,...
        rf.land.m5.tsRssi,...
        'union');

    % sea m5 dist-to-rssiTime synchronization
    rf.sea.m5.dsDist = tVec2datestring(rf.sea.m5.ground.time);      % distance datestring variable (based on ground station timestamp)
    rf.sea.m5.dsRssi = tVec2datestring(rf.sea.m5.rssiTime);         % rssi datestring variable (based on rssi timestamp)
    rf.sea.m5.tsDist = timeseries(rf.sea.m5.dist,...                % distance timeseries variable
        rf.sea.m5.dsDist);
    rf.sea.m5.tsRssi = timeseries([rf.sea.m5.rssi1,...              % rssi timeseries variable
        rf.sea.m5.rssi2],...
        rf.sea.m5.dsRssi);
    [rf.sea.m5.tsDist,rf.sea.m5.tsRssi] = synchronize(...
        rf.sea.m5.tsDist,...
        rf.sea.m5.tsRssi,...
        'union');
    
end

function ds = tVec2datestring(tVec)
% Converts a time vector in [s] to a Matlab datastring variable that can be
% used to create a timeseries variable. Time series starts on 2019-01-01.
% Note that as of 2019.06.09, Matlab function 'timeseries()' still cannot
% take a datetime variable, so it is necessary to convert datetime variable
% to a datestring variable first.

    Y = (ones(size(tVec))*2019);
    M = (ones(size(tVec))*1);
    D = (ones(size(tVec))*1);
    H = (ones(size(tVec))*0);
    MI = (ones(size(tVec))*0);
    S = floor(tVec);
    MS = (tVec-floor(tVec))*1E3;
    dt = datetime(Y,M,D,H,MI,S,MS,...
        'Format','yyyy-MM-dd HH:mm:ss.SSS');
    ds = datestr(dt,'yyyy-mm-dd HH:MM:SS.FFF'); 

end

function [rf2412,rf5240] = lossModels(rf2412,rf5240)

    % Distance vectors
    rf2412.d = linspace(0,500,50000);   % distance vector [m]
    rf5240.d = linspace(0,500,50000);   % distance vector [m]
    
    % Phyiscal consatnts
    c = 299792458;                      % speed of light [m/s]
    rf2412.lambda = c/rf2412.freq;      % wavelength [m]
    rf5240.lambda = c/rf5240.freq;      % wavelength [m]
    R = -1;                             % reflection coefficient [ ]
    
    % Free space path loss model (FSPL)
    rf2412.fspl = rf2412.Pt-(-10*log10((10^(rf2412.Gt/10))*(10^(rf2412.Gr/10))*(rf2412.lambda./(4*pi*rf2412.d)).^2));
    rf5240.fspl = rf5240.Pt-(-10*log10((10^(rf5240.Gt/10))*(10^(rf5240.Gr/10))*(rf5240.lambda./(4*pi*rf5240.d)).^2));
    
    % Two ray ground reflection approximation model
    rf2412.trgrApprx.m2 = rf2412.Pt+rf2412.Gt+rf2412.Gr-40*log10(rf2412.d)+20*log10(rf2412.ht.m2)+20*log10(rf2412.hr);
    rf2412.trgrApprx.m5 = rf2412.Pt+rf2412.Gt+rf2412.Gr-40*log10(rf2412.d)+20*log10(rf2412.ht.m5)+20*log10(rf2412.hr);
    rf5240.trgrApprx.m2 = rf5240.Pt+rf5240.Gt+rf5240.Gr-40*log10(rf5240.d)+20*log10(rf5240.ht.m2)+20*log10(rf5240.hr);
    rf5240.trgrApprx.m5 = rf5240.Pt+rf5240.Gt+rf5240.Gr-40*log10(rf5240.d)+20*log10(rf5240.ht.m5)+20*log10(rf5240.hr);
    
    % Two ray ground reflection model (TRGR)
    rf2412.trgr.m2 = 20.*log10(rf2412.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10))./(sqrt(rf2412.d.^2+(rf2412.ht.m2-rf2412.hr).^2)))+(R.*(sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf2412.d.^2+(rf2412.ht.m2+rf2412.hr).^2))-(sqrt(rf2412.d.^2+(rf2412.ht.m2-rf2412.hr).^2))))./rf2412.lambda)))./(sqrt(rf2412.d.^2+(rf2412.ht.m2+rf2412.hr).^2)))))+rf2412.Pt;
    rf2412.trgr.m5 = 20.*log10(rf2412.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10))./(sqrt(rf2412.d.^2+(rf2412.ht.m5-rf2412.hr).^2)))+(R.*(sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf2412.d.^2+(rf2412.ht.m5+rf2412.hr).^2))-(sqrt(rf2412.d.^2+(rf2412.ht.m5-rf2412.hr).^2))))./rf2412.lambda)))./(sqrt(rf2412.d.^2+(rf2412.ht.m5+rf2412.hr).^2)))))+rf2412.Pt;
    rf5240.trgr.m2 = 20.*log10(rf5240.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10))./(sqrt(rf5240.d.^2+(rf5240.ht.m2-rf5240.hr).^2)))+(R.*(sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf5240.d.^2+(rf5240.ht.m2+rf5240.hr).^2))-(sqrt(rf5240.d.^2+(rf5240.ht.m2-rf5240.hr).^2))))./rf5240.lambda)))./(sqrt(rf5240.d.^2+(rf5240.ht.m2+rf5240.hr).^2)))))+rf5240.Pt;
    rf5240.trgr.m5 = 20.*log10(rf5240.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10))./(sqrt(rf5240.d.^2+(rf5240.ht.m5-rf5240.hr).^2)))+(R.*(sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf5240.d.^2+(rf5240.ht.m5+rf5240.hr).^2))-(sqrt(rf5240.d.^2+(rf5240.ht.m5-rf5240.hr).^2))))./rf5240.lambda)))./(sqrt(rf5240.d.^2+(rf5240.ht.m5+rf5240.hr).^2)))))+rf5240.Pt;
     
    % Crossover distance
    rf2412.cd.m2 = (4*pi*rf2412.ht.m2*rf2412.hr)/(rf2412.lambda);
    rf2412.cd.m5 = (4*pi*rf2412.ht.m5*rf2412.hr)/(rf2412.lambda);
    rf5240.cd.m2 = (4*pi*rf5240.ht.m2*rf5240.hr)/(rf5240.lambda);
    rf5240.cd.m5 = (4*pi*rf5240.ht.m5*rf5240.hr)/(rf5240.lambda);
            
    % Fit FSPL using path loss variable (PL)
    rf2412.land.m2.fsplFun = @(PL,x) rf2412.Pt-(-10*log10((10^(rf2412.Gt/10))*(10^(rf2412.Gr/10))*(rf2412.lambda./(4*pi*x)).^2))-PL;
    x = rf2412.land.m2.tsDist.Data;
    y = mean([rf2412.land.m2.tsRssi.Data(:,1),rf2412.land.m2.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf2412.ht.m2);
    x = x(xi:end,1); y = y(xi:end,1);
    [rf2412.land.m2.fsplFitCoef,rf2412.land.m2.R2] = fitFspl(x,y,rf2412.land.m2.fsplFun,10,1);
    rf2412.land.m2.fsplFit = rf2412.Pt-(-10*log10((10^(rf2412.Gt/10))*(10^(rf2412.Gr/10))*(rf2412.lambda./(4*pi*rf2412.d)).^2))-rf2412.land.m2.fsplFitCoef;
    
    rf2412.land.m5.fsplFun = @(PL,x) rf2412.Pt-(-10*log10((10^(rf2412.Gt/10))*(10^(rf2412.Gr/10))*(rf2412.lambda./(4*pi*x)).^2))-PL;
    x = rf2412.land.m5.tsDist.Data;
    y = mean([rf2412.land.m5.tsRssi.Data(:,1),rf2412.land.m5.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf2412.ht.m5);
    x = x(xi:end,1); y = y(xi:end,1);
    [rf2412.land.m5.fsplFitCoef,rf2412.land.m5.R2] = fitFspl(x,y,rf2412.land.m5.fsplFun,10,1);
    rf2412.land.m5.fsplFit = rf2412.Pt-(-10*log10((10^(rf2412.Gt/10))*(10^(rf2412.Gr/10))*(rf2412.lambda./(4*pi*rf2412.d)).^2))-rf2412.land.m5.fsplFitCoef;
    
    rf2412.sea.m2.fsplFun = @(PL,x) rf2412.Pt-(-10*log10((10^(rf2412.Gt/10))*(10^(rf2412.Gr/10))*(rf2412.lambda./(4*pi*x)).^2))-PL;
    x = rf2412.sea.m2.tsDist.Data;
    y = mean([rf2412.sea.m2.tsRssi.Data(:,1),rf2412.sea.m2.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf2412.ht.m2);
    x = x(xi:end,1); y = y(xi:end,1);
    [rf2412.sea.m2.fsplFitCoef,rf2412.sea.m2.R2] = fitFspl(x,y,rf2412.sea.m2.fsplFun,10,1);
    rf2412.sea.m2.fsplFit = rf2412.Pt-(-10*log10((10^(rf2412.Gt/10))*(10^(rf2412.Gr/10))*(rf2412.lambda./(4*pi*rf2412.d)).^2))-rf2412.sea.m2.fsplFitCoef;
    
    rf2412.sea.m5.fsplFun = @(PL,x) rf2412.Pt-(-10*log10((10^(rf2412.Gt/10))*(10^(rf2412.Gr/10))*(rf2412.lambda./(4*pi*x)).^2))-PL;
    x = rf2412.sea.m5.tsDist.Data;
    y = mean([rf2412.sea.m5.tsRssi.Data(:,1),rf2412.sea.m5.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf2412.ht.m5);
    x = x(xi:end,1); y = y(xi:end,1);
    [rf2412.sea.m5.fsplFitCoef,rf2412.sea.m5.R2] = fitFspl(x,y,rf2412.sea.m5.fsplFun,10,1);
    rf2412.sea.m5.fsplFit = rf2412.Pt-(-10*log10((10^(rf2412.Gt/10))*(10^(rf2412.Gr/10))*(rf2412.lambda./(4*pi*rf2412.d)).^2))-rf2412.sea.m5.fsplFitCoef;

    rf5240.land.m2.fsplFun = @(PL,x) rf5240.Pt-(-10*log10((10^(rf5240.Gt/10))*(10^(rf5240.Gr/10))*(rf5240.lambda./(4*pi*x)).^2))-PL;
    x = rf5240.land.m2.tsDist.Data;
    y = mean([rf5240.land.m2.tsRssi.Data(:,1),rf5240.land.m2.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf5240.ht.m2);
    x = x(xi:end,1); y = y(xi:end,1);
    [rf5240.land.m2.fsplFitCoef,rf5240.land.m2.R2] = fitFspl(x,y,rf5240.land.m2.fsplFun,10,1);
    rf5240.land.m2.fsplFit = rf5240.Pt-(-10*log10((10^(rf5240.Gt/10))*(10^(rf5240.Gr/10))*(rf5240.lambda./(4*pi*rf5240.d)).^2))-rf5240.land.m2.fsplFitCoef;
    
    rf5240.land.m5.fsplFun = @(PL,x) rf5240.Pt-(-10*log10((10^(rf5240.Gt/10))*(10^(rf5240.Gr/10))*(rf5240.lambda./(4*pi*x)).^2))-PL;
    x = rf5240.land.m5.tsDist.Data;
    y = mean([rf5240.land.m5.tsRssi.Data(:,1),rf5240.land.m5.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf5240.ht.m5);
    x = x(xi:end,1); y = y(xi:end,1);
    [rf5240.land.m5.fsplFitCoef,rf5240.land.m5.R2] = fitFspl(x,y,rf5240.land.m5.fsplFun,10,1);
    rf5240.land.m5.fsplFit = rf5240.Pt-(-10*log10((10^(rf5240.Gt/10))*(10^(rf5240.Gr/10))*(rf5240.lambda./(4*pi*rf5240.d)).^2))-rf5240.land.m5.fsplFitCoef;
    
    rf5240.sea.m2.fsplFun = @(PL,x) rf5240.Pt-(-10*log10((10^(rf5240.Gt/10))*(10^(rf5240.Gr/10))*(rf5240.lambda./(4*pi*x)).^2))-PL;
    x = rf5240.sea.m2.tsDist.Data;
    y = mean([rf5240.sea.m2.tsRssi.Data(:,1),rf5240.sea.m2.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf5240.ht.m2);
    x = x(xi:end,1); y = y(xi:end,1);
    [rf5240.sea.m2.fsplFitCoef,rf5240.sea.m2.R2] = fitFspl(x,y,rf5240.sea.m2.fsplFun,10,1);
    rf5240.sea.m2.fsplFit = rf5240.Pt-(-10*log10((10^(rf5240.Gt/10))*(10^(rf5240.Gr/10))*(rf5240.lambda./(4*pi*rf5240.d)).^2))-rf5240.sea.m2.fsplFitCoef;
    
    rf5240.sea.m5.fsplFun = @(PL,x) rf5240.Pt-(-10*log10((10^(rf5240.Gt/10))*(10^(rf5240.Gr/10))*(rf5240.lambda./(4*pi*x)).^2))-PL;
    x = rf5240.sea.m5.tsDist.Data;
    y = mean([rf5240.sea.m5.tsRssi.Data(:,1),rf5240.sea.m5.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf5240.ht.m5);
    x = x(xi:end,1); y = y(xi:end,1);
    [rf5240.sea.m5.fsplFitCoef,rf5240.sea.m5.R2] = fitFspl(x,y,rf5240.sea.m5.fsplFun,10,1);
    rf5240.sea.m5.fsplFit = rf5240.Pt-(-10*log10((10^(rf5240.Gt/10))*(10^(rf5240.Gr/10))*(rf5240.lambda./(4*pi*rf5240.d)).^2))-rf5240.sea.m5.fsplFitCoef;    
    
    % Fit TRGR using pass loss variable (PL) and ground reflectivity (R)
    rf2412.land.m2.trgrFun = @(p,x) 20.*log10(rf2412.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10))./(sqrt(x.^2+(rf2412.ht.m2+p(2)-rf2412.hr).^2)))+((R+p(3)).*(sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rf2412.ht.m2+p(2)+rf2412.hr).^2))-(sqrt(x.^2+(rf2412.ht.m2+p(2)-rf2412.hr).^2))))./rf2412.lambda)))./(sqrt(x.^2+(rf2412.ht.m2+p(2)+rf2412.hr).^2)))))+rf2412.Pt-p(1);
    x = rf2412.land.m2.tsDist.Data;
    y = mean([rf2412.land.m2.tsRssi.Data(:,1),rf2412.land.m2.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf2412.ht.m2);
    x = x(xi:end,1); y = y(xi:end,1);
    p0 = [12 0 0];
    [rf2412.land.m2.trgrFitCoef,rf2412.land.m2.R2] = fitTrgr(x,y,rf2412.land.m2.trgrFun,p0,1);
    rf2412.land.m2.trgrFit = 20.*log10(rf2412.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10))./(sqrt(rf2412.d.^2+(rf2412.ht.m2+rf2412.land.m2.trgrFitCoef(2)-rf2412.hr).^2)))+((R+rf2412.land.m2.trgrFitCoef(3)).*(sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf2412.d.^2+(rf2412.ht.m2+rf2412.land.m2.trgrFitCoef(2)+rf2412.hr).^2))-(sqrt(rf2412.d.^2+(rf2412.ht.m2+rf2412.land.m2.trgrFitCoef(2)-rf2412.hr).^2))))./rf2412.lambda)))./(sqrt(rf2412.d.^2+(rf2412.ht.m2+rf2412.land.m2.trgrFitCoef(2)+rf2412.hr).^2)))))+rf2412.Pt-rf2412.land.m2.trgrFitCoef(1);

    rf2412.land.m5.trgrFun = @(p,x) 20.*log10(rf2412.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10))./(sqrt(x.^2+(rf2412.ht.m5+p(2)-rf2412.hr).^2)))+((R+p(3)).*(sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rf2412.ht.m5+p(2)+rf2412.hr).^2))-(sqrt(x.^2+(rf2412.ht.m5+p(2)-rf2412.hr).^2))))./rf2412.lambda)))./(sqrt(x.^2+(rf2412.ht.m5+p(2)+rf2412.hr).^2)))))+rf2412.Pt-p(1);
    x = rf2412.land.m5.tsDist.Data;
    y = mean([rf2412.land.m5.tsRssi.Data(:,1),rf2412.land.m5.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf2412.ht.m5);
    xi = 30;
    x = x(xi:end,1); y = y(xi:end,1);
    p0 = [10 0 0];
    [rf2412.land.m5.trgrFitCoef,rf2412.land.m5.R2] = fitTrgr(x,y,rf2412.land.m5.trgrFun,p0,1);
    rf2412.land.m5.trgrFit = 20.*log10(rf2412.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10))./(sqrt(rf2412.d.^2+(rf2412.ht.m5+rf2412.land.m5.trgrFitCoef(2)-rf2412.hr).^2)))+((R+rf2412.land.m5.trgrFitCoef(3)).*(sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf2412.d.^2+(rf2412.ht.m5+rf2412.land.m5.trgrFitCoef(2)+rf2412.hr).^2))-(sqrt(rf2412.d.^2+(rf2412.ht.m5+rf2412.land.m5.trgrFitCoef(2)-rf2412.hr).^2))))./rf2412.lambda)))./(sqrt(rf2412.d.^2+(rf2412.ht.m5+rf2412.land.m5.trgrFitCoef(2)+rf2412.hr).^2)))))+rf2412.Pt-rf2412.land.m5.trgrFitCoef(1);

    rf2412.sea.m2.trgrFun = @(p,x) 20.*log10(rf2412.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10))./(sqrt(x.^2+(rf2412.ht.m2+p(2)-rf2412.hr).^2)))+((R+p(3)).*(sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rf2412.ht.m2+p(2)+rf2412.hr).^2))-(sqrt(x.^2+(rf2412.ht.m2+p(2)-rf2412.hr).^2))))./rf2412.lambda)))./(sqrt(x.^2+(rf2412.ht.m2+p(2)+rf2412.hr).^2)))))+rf2412.Pt-p(1);
    x = rf2412.sea.m2.tsDist.Data;
    y = mean([rf2412.sea.m2.tsRssi.Data(:,1),rf2412.sea.m2.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf2412.ht.m2);
    x = x(xi:end,1); y = y(xi:end,1);
    p0 = [15 0.1 0];
    [rf2412.sea.m2.trgrFitCoef,rf2412.sea.m2.R2] = fitTrgr(x,y,rf2412.sea.m2.trgrFun,p0,1);
    rf2412.sea.m2.trgrFit = 20.*log10(rf2412.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10))./(sqrt(rf2412.d.^2+(rf2412.ht.m2+rf2412.sea.m2.trgrFitCoef(2)-rf2412.hr).^2)))+((R+rf2412.sea.m2.trgrFitCoef(3)).*(sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf2412.d.^2+(rf2412.ht.m2+rf2412.sea.m2.trgrFitCoef(2)+rf2412.hr).^2))-(sqrt(rf2412.d.^2+(rf2412.ht.m2+rf2412.sea.m2.trgrFitCoef(2)-rf2412.hr).^2))))./rf2412.lambda)))./(sqrt(rf2412.d.^2+(rf2412.ht.m2+rf2412.sea.m2.trgrFitCoef(2)+rf2412.hr).^2)))))+rf2412.Pt-rf2412.sea.m2.trgrFitCoef(1);

    rf2412.sea.m5.trgrFun = @(p,x) 20.*log10(rf2412.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10))./(sqrt(x.^2+(rf2412.ht.m5+p(2)-rf2412.hr).^2)))+((R+p(3)).*(sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rf2412.ht.m5+p(2)+rf2412.hr).^2))-(sqrt(x.^2+(rf2412.ht.m5+p(2)-rf2412.hr).^2))))./rf2412.lambda)))./(sqrt(x.^2+(rf2412.ht.m5+p(2)+rf2412.hr).^2)))))+rf2412.Pt-p(1);
    x = rf2412.sea.m5.tsDist.Data;
    y = mean([rf2412.sea.m5.tsRssi.Data(:,1),rf2412.sea.m5.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf2412.ht.m5);
    x = x(xi:end,1); y = y(xi:end,1);
    p0 = [16 0 0];
    [rf2412.sea.m5.trgrFitCoef,rf2412.sea.m5.R2] = fitTrgr(x,y,rf2412.sea.m5.trgrFun,p0,1);
    rf2412.sea.m5.trgrFit = 20.*log10(rf2412.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10))./(sqrt(rf2412.d.^2+(rf2412.ht.m5+rf2412.sea.m5.trgrFitCoef(2)-rf2412.hr).^2)))+((R+rf2412.sea.m5.trgrFitCoef(3)).*(sqrt(10.^(rf2412.Gt./10).*10.^(rf2412.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf2412.d.^2+(rf2412.ht.m5+rf2412.sea.m5.trgrFitCoef(2)+rf2412.hr).^2))-(sqrt(rf2412.d.^2+(rf2412.ht.m5+rf2412.sea.m5.trgrFitCoef(2)-rf2412.hr).^2))))./rf2412.lambda)))./(sqrt(rf2412.d.^2+(rf2412.ht.m5+rf2412.sea.m5.trgrFitCoef(2)+rf2412.hr).^2)))))+rf2412.Pt-rf2412.sea.m5.trgrFitCoef(1);

    rf5240.land.m2.trgrFun = @(p,x) 20.*log10(rf5240.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10))./(sqrt(x.^2+(rf5240.ht.m2+p(2)-rf5240.hr).^2)))+((R+p(3)).*(sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rf5240.ht.m2+p(2)+rf5240.hr).^2))-(sqrt(x.^2+(rf5240.ht.m2+p(2)-rf5240.hr).^2))))./rf5240.lambda)))./(sqrt(x.^2+(rf5240.ht.m2+p(2)+rf5240.hr).^2)))))+rf5240.Pt-p(1);
    x = rf5240.land.m2.tsDist.Data;
    y = mean([rf5240.land.m2.tsRssi.Data(:,1),rf5240.land.m2.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf5240.ht.m2);
    x = x(xi:end,1); y = y(xi:end,1);
    p0 = [10 -0.3 0.5];
    [rf5240.land.m2.trgrFitCoef,rf5240.land.m2.R2] = fitTrgr(x,y,rf5240.land.m2.trgrFun,p0,1);
    rf5240.land.m2.trgrFit = 20.*log10(rf5240.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10))./(sqrt(rf5240.d.^2+(rf5240.ht.m2+rf5240.land.m2.trgrFitCoef(2)-rf5240.hr).^2)))+((R+rf5240.land.m2.trgrFitCoef(3)).*(sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf5240.d.^2+(rf5240.ht.m2+rf5240.land.m2.trgrFitCoef(2)+rf5240.hr).^2))-(sqrt(rf5240.d.^2+(rf5240.ht.m2+rf5240.land.m2.trgrFitCoef(2)-rf5240.hr).^2))))./rf5240.lambda)))./(sqrt(rf5240.d.^2+(rf5240.ht.m2+rf5240.land.m2.trgrFitCoef(2)+rf5240.hr).^2)))))+rf5240.Pt-rf5240.land.m2.trgrFitCoef(1);

    rf5240.land.m5.trgrFun = @(p,x) 20.*log10(rf5240.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10))./(sqrt(x.^2+(rf5240.ht.m5+p(2)-rf5240.hr).^2)))+((R+p(3)).*(sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rf5240.ht.m5+p(2)+rf5240.hr).^2))-(sqrt(x.^2+(rf5240.ht.m5+p(2)-rf5240.hr).^2))))./rf5240.lambda)))./(sqrt(x.^2+(rf5240.ht.m5+p(2)+rf5240.hr).^2)))))+rf5240.Pt-p(1);
    x = rf5240.land.m5.tsDist.Data;
    y = mean([rf5240.land.m5.tsRssi.Data(:,1),rf5240.land.m5.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf5240.ht.m5);
    x = x(xi:end,1); y = y(xi:end,1);
    p0 = [10 -0.5 0.5];
    [rf5240.land.m5.trgrFitCoef,rf5240.land.m5.R2] = fitTrgr(x,y,rf5240.land.m5.trgrFun,p0,1);
    rf5240.land.m5.trgrFit = 20.*log10(rf5240.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10))./(sqrt(rf5240.d.^2+(rf5240.ht.m5+rf5240.land.m5.trgrFitCoef(2)-rf5240.hr).^2)))+((R+rf5240.land.m5.trgrFitCoef(3)).*(sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf5240.d.^2+(rf5240.ht.m5+rf5240.land.m5.trgrFitCoef(2)+rf5240.hr).^2))-(sqrt(rf5240.d.^2+(rf5240.ht.m5+rf5240.land.m5.trgrFitCoef(2)-rf5240.hr).^2))))./rf5240.lambda)))./(sqrt(rf5240.d.^2+(rf5240.ht.m5+rf5240.land.m5.trgrFitCoef(2)+rf5240.hr).^2)))))+rf5240.Pt-rf5240.land.m5.trgrFitCoef(1);

    rf5240.sea.m2.trgrFun = @(p,x) 20.*log10(rf5240.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10))./(sqrt(x.^2+(rf5240.ht.m2+p(2)-rf5240.hr).^2)))+((R+p(3)).*(sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rf5240.ht.m2+p(2)+rf5240.hr).^2))-(sqrt(x.^2+(rf5240.ht.m2+p(2)-rf5240.hr).^2))))./rf5240.lambda)))./(sqrt(x.^2+(rf5240.ht.m2+p(2)+rf5240.hr).^2)))))+rf5240.Pt-p(1);
    x = rf5240.sea.m2.tsDist.Data;
    y = mean([rf5240.sea.m2.tsRssi.Data(:,1),rf5240.sea.m2.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf5240.ht.m2);
    x = x(xi:end,1); y = y(xi:end,1);
    p0 = [10 -0.3 0.5];
    [rf5240.sea.m2.trgrFitCoef,rf5240.sea.m2.R2] = fitTrgr(x,y,rf5240.sea.m2.trgrFun,p0,1);
    rf5240.sea.m2.trgrFit = 20.*log10(rf5240.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10))./(sqrt(rf5240.d.^2+(rf5240.ht.m2+rf5240.sea.m2.trgrFitCoef(2)-rf5240.hr).^2)))+((R+rf5240.sea.m2.trgrFitCoef(3)).*(sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf5240.d.^2+(rf5240.ht.m2+rf5240.sea.m2.trgrFitCoef(2)+rf5240.hr).^2))-(sqrt(rf5240.d.^2+(rf5240.ht.m2+rf5240.sea.m2.trgrFitCoef(2)-rf5240.hr).^2))))./rf5240.lambda)))./(sqrt(rf5240.d.^2+(rf5240.ht.m2+rf5240.sea.m2.trgrFitCoef(2)+rf5240.hr).^2)))))+rf5240.Pt-rf5240.sea.m2.trgrFitCoef(1);

    rf5240.sea.m5.trgrFun = @(p,x) 20.*log10(rf5240.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10))./(sqrt(x.^2+(rf5240.ht.m5+p(2)-rf5240.hr).^2)))+((R+p(3)).*(sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rf5240.ht.m5+p(2)+rf5240.hr).^2))-(sqrt(x.^2+(rf5240.ht.m5+p(2)-rf5240.hr).^2))))./rf5240.lambda)))./(sqrt(x.^2+(rf5240.ht.m5+p(2)+rf5240.hr).^2)))))+rf5240.Pt-p(1);
    x = rf5240.sea.m5.tsDist.Data;
    y = mean([rf5240.sea.m5.tsRssi.Data(:,1),rf5240.sea.m5.tsRssi.Data(:,2)],2);
    xi = findIndexHeight(x,rf5240.ht.m5);
    x = x(xi:end,1); y = y(xi:end,1);
    p0 = [10 -0.5 0.5];
    [rf5240.sea.m5.trgrFitCoef,rf5240.sea.m5.R2] = fitTrgr(x,y,rf5240.sea.m5.trgrFun,p0,1);
    rf5240.sea.m5.trgrFit = 20.*log10(rf5240.lambda./(4.*pi))+20.*log10(abs((sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10))./(sqrt(rf5240.d.^2+(rf5240.ht.m5+rf5240.sea.m5.trgrFitCoef(2)-rf5240.hr).^2)))+((R+rf5240.sea.m5.trgrFitCoef(3)).*(sqrt(10.^(rf5240.Gt./10).*10.^(rf5240.Gr./10)).*exp(-(1i).*((2.*pi.*((sqrt(rf5240.d.^2+(rf5240.ht.m5+rf5240.sea.m5.trgrFitCoef(2)+rf5240.hr).^2))-(sqrt(rf5240.d.^2+(rf5240.ht.m5+rf5240.sea.m5.trgrFitCoef(2)-rf5240.hr).^2))))./rf5240.lambda)))./(sqrt(rf5240.d.^2+(rf5240.ht.m5+rf5240.sea.m5.trgrFitCoef(2)+rf5240.hr).^2)))))+rf5240.Pt-rf5240.sea.m5.trgrFitCoef(1);

end

function xi = findIndexHeight(x,ht)

    xi = 0;
    [row,~] = size(x);
    for i = 1:1:row
        if x(i,1) >= ht
            xi = i;
            break;
        end
    end

end

function [PL,Rsq] = fitFspl(x,y,dataFitFun,PL0,fitTrue)

%         PL0 = 10;

    if fitTrue == 1

        % Calculate fit
        error = @(PL) sum((dataFitFun(PL,x)-y).^2);
        PL = fminsearch(error,PL0);
        
        % Calculate R-squared
        SStot = sum((mean(y)-y).^2);
        SSres = error(PL);
        Rsq = 1-(SSres/SStot);
    
    else
        
        p = PL0;
        Rsq = 1;
        
    end
    
end

function [p,Rsq] = fitTrgr(x,y,dataFitFun,p0,fitTrue)

    if fitTrue == 1
        
        % Calculate fit
        error = @(p) sum((dataFitFun(p,x)-y).^2);
%         p = fminsearch(error,p0);
        p = fmincon(error,p0,[],[],[],[],[0,-1,0],[25,1,1])
        
        % Calculate R-squared
        SStot = sum((mean(y)-y).^2);
        SSres = error(p);
        Rsq = 1-(SSres/SStot);
        
    else
        
        p = p0;
        Rsq = 1;
        
    end
    
end

function plot2by2(rf2412,rf5240)

    % Close any open figures
    close all;
    
    % Font sizes
    titleFontSize = 24;
    defaultFontSize = 20;

    % Plot
    figure(1);
    set(gcf, 'Position', [0, -500, 1920, 1080])
    rf2412_m2 = subplot(2,2,1);
    hold on;
    plot(rf2412.land.m2.tsDist.Data,mean([rf2412.land.m2.tsRssi.Data(:,1),rf2412.land.m2.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf2412.sea.m2.tsDist.Data,mean([rf2412.sea.m2.tsRssi.Data(:,1),rf2412.sea.m2.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf2412.d,rf2412.trgr.m2,'c-.','LineWidth',1.5);
    plot(rf2412.d,rf2412.fspl,'m--','LineWidth',1.5);
    plot(rf2412.d,rf2412.trgrApprx.m2,'r:','LineWidth',1.5);
    hold off;
    xlabel(['antenna separation [m]';" "]);
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    legend('land RSSI h_t','sea RSSI','P_r from full two-ray','P_r from apprx. two-ray h_t<d<c_d','P_r from apprx. two-ray d>c_d');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('2.412 GHz, h_t = 2.0 m','FontName','Times New Roman','FontSize',22);
    grid on;
    rf2412_m5 = subplot(2,2,2);
    hold on;
    plot(rf2412.land.m5.tsDist.Data,mean([rf2412.land.m5.tsRssi.Data(:,1),rf2412.land.m5.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf2412.sea.m5.tsDist.Data,mean([rf2412.sea.m5.tsRssi.Data(:,1),rf2412.sea.m5.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf2412.d,rf2412.trgr.m5,'c-.','LineWidth',1.5);
    plot(rf2412.d,rf2412.fspl,'m--','LineWidth',1.5);
    plot(rf2412.d,rf2412.trgrApprx.m5,'r:','LineWidth',1.5);
    hold off;
    xlabel('antenna separation [m]');
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('2.412 GHz, h_t = 4.5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    rf5240_m2 = subplot(2,2,3);
    hold on;
    plot(rf5240.land.m2.tsDist.Data,mean([rf5240.land.m2.tsRssi.Data(:,1),rf5240.land.m2.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf5240.sea.m2.tsDist.Data,mean([rf5240.sea.m2.tsRssi.Data(:,1),rf5240.sea.m2.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf5240.d,rf5240.trgr.m2,'c-.','LineWidth',1.5);
    plot(rf5240.d,rf5240.fspl,'m--','LineWidth',1.5);
    plot(rf5240.d,rf5240.trgrApprx.m2,'r:','LineWidth',1.5);
    hold off;
    xlabel('antenna separation [m]');
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('5.240 GHz, h_t = 2.0 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    rf5240_m5 = subplot(2,2,4);
    hold on;
    plot(rf5240.land.m5.tsDist.Data,mean([rf5240.land.m5.tsRssi.Data(:,1),rf5240.land.m5.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf5240.sea.m5.tsDist.Data,mean([rf5240.sea.m5.tsRssi.Data(:,1),rf5240.sea.m5.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf5240.d,rf5240.trgr.m5,'c-.','LineWidth',1.5);
    plot(rf5240.d,rf5240.fspl,'m--','LineWidth',1.5);
    plot(rf5240.d,rf5240.trgrApprx.m5,'r:','LineWidth',1.5);
    hold off;
    xlabel('antenna separation [m]');
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('5.240 GHz, h_t = 4.5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    linkaxes([rf2412_m2,rf2412_m5,rf5240_m2,rf5240_m5],'x');
    linkaxes([rf2412_m2,rf2412_m5,rf5240_m2,rf5240_m5],'y');
    
    figure(2);
    set(gcf, 'Position', [0, -500, 1920, 1080])
    rf2412_m2 = subplot(2,2,1);
    hold on;
    plot(rf2412.land.m2.tsDist.Data,mean([rf2412.land.m2.tsRssi.Data(:,1),rf2412.land.m2.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf2412.sea.m2.tsDist.Data,mean([rf2412.sea.m2.tsRssi.Data(:,1),rf2412.sea.m2.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf2412.d,rf2412.land.m2.fsplFit,'Color','#000000','LineStyle','-.','LineWidth',1);
    plot(rf2412.d,rf2412.sea.m2.fsplFit,'Color','#000000','LineStyle','-','LineWidth',1);
    hold off;
    xlabel(['antenna separation [m]';" "]);
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    legend('land RSSI','sea RSSI','two-ray theoretical land fit','two-ray theoretical sea fit');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('2.412 GHz, h_t = 2.0 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    rf2412_m5 = subplot(2,2,2);
    hold on;
    plot(rf2412.land.m5.tsDist.Data,mean([rf2412.land.m5.tsRssi.Data(:,1),rf2412.land.m5.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf2412.sea.m5.tsDist.Data,mean([rf2412.sea.m5.tsRssi.Data(:,1),rf2412.sea.m5.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf2412.d,rf2412.land.m5.fsplFit,'Color','#000000','LineStyle','-.','LineWidth',1);
    plot(rf2412.d,rf2412.sea.m5.fsplFit,'Color','#000000','LineStyle','-','LineWidth',1);
    hold off;
    xlabel(['antenna separation [m]';" "]);
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('2.412 GHz, h_t = 4.5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    rf5240_m2 = subplot(2,2,3);
    hold on;
    plot(rf5240.land.m2.tsDist.Data,mean([rf5240.land.m2.tsRssi.Data(:,1),rf5240.land.m2.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf5240.sea.m2.tsDist.Data,mean([rf5240.sea.m2.tsRssi.Data(:,1),rf5240.sea.m2.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf5240.d,rf5240.land.m2.fsplFit,'Color','#000000','LineStyle','-.','LineWidth',1);
    plot(rf5240.d,rf5240.sea.m2.fsplFit,'Color','#000000','LineStyle','-','LineWidth',1);
    hold off;
    xlabel(['antenna separation [m]';" "]);
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('5.240 GHz, h_t = 2.0 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    rf5240_m5 = subplot(2,2,4);
    hold on;
    plot(rf5240.land.m5.tsDist.Data,mean([rf5240.land.m5.tsRssi.Data(:,1),rf5240.land.m5.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf5240.sea.m5.tsDist.Data,mean([rf5240.sea.m5.tsRssi.Data(:,1),rf5240.sea.m5.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf5240.d,rf5240.land.m5.fsplFit,'Color','#000000','LineStyle','-.','LineWidth',1);
    plot(rf5240.d,rf5240.sea.m5.fsplFit,'Color','#000000','LineStyle','-','LineWidth',1);
    hold off;
    xlabel(['antenna separation [m]';" "]);
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('5.240 GHz, h_t = 4.5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    linkaxes([rf2412_m2,rf2412_m5,rf5240_m2,rf5240_m5],'x');
    linkaxes([rf2412_m2,rf2412_m5,rf5240_m2,rf5240_m5],'y');
    
    figure(3);
    set(gcf, 'Position', [0, -500, 1920, 1080])
    rf2412_m2 = subplot(2,2,1);
    hold on;
    plot(rf2412.land.m2.tsDist.Data,mean([rf2412.land.m2.tsRssi.Data(:,1),rf2412.land.m2.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf2412.sea.m2.tsDist.Data,mean([rf2412.sea.m2.tsRssi.Data(:,1),rf2412.sea.m2.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf2412.d,rf2412.land.m2.trgrFit,'Color','#000000','LineStyle','-.','LineWidth',1);
    plot(rf2412.d,rf2412.sea.m2.trgrFit,'Color','#000000','LineStyle','-','LineWidth',1);
    hold off;
    xlabel(['antenna separation [m]';" "]);
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    legend('land RSSI','sea RSSI','two-ray theoretical land fit','two-ray theoretical sea fit');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('2.412 GHz, h_t = 2.0 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    rf2412_m5 = subplot(2,2,2);
    hold on;
    plot(rf2412.land.m5.tsDist.Data,mean([rf2412.land.m5.tsRssi.Data(:,1),rf2412.land.m5.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf2412.sea.m5.tsDist.Data,mean([rf2412.sea.m5.tsRssi.Data(:,1),rf2412.sea.m5.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf2412.d,rf2412.land.m5.trgrFit,'Color','#000000','LineStyle','-.','LineWidth',1);
    plot(rf2412.d,rf2412.sea.m5.trgrFit,'Color','#000000','LineStyle','-','LineWidth',1);
    hold off;
    xlabel(['antenna separation [m]';" "]);
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('2.412 GHz, h_t = 4.5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    rf5240_m2 = subplot(2,2,3);
    hold on;
    plot(rf5240.land.m2.tsDist.Data,mean([rf5240.land.m2.tsRssi.Data(:,1),rf5240.land.m2.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf5240.sea.m2.tsDist.Data,mean([rf5240.sea.m2.tsRssi.Data(:,1),rf5240.sea.m2.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf5240.d,rf5240.land.m2.trgrFit,'Color','#000000','LineStyle','-.','LineWidth',1);
    plot(rf5240.d,rf5240.sea.m2.trgrFit,'Color','#000000','LineStyle','-','LineWidth',1);
    hold off;
    xlabel(['antenna separation [m]';" "]);
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('5.240 GHz, h_t = 2.0 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    rf5240_m5 = subplot(2,2,4);
    hold on;
    plot(rf5240.land.m5.tsDist.Data,mean([rf5240.land.m5.tsRssi.Data(:,1),rf5240.land.m5.tsRssi.Data(:,2)],2),'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rf5240.sea.m5.tsDist.Data,mean([rf5240.sea.m5.tsRssi.Data(:,1),rf5240.sea.m5.tsRssi.Data(:,2)],2),'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rf5240.d,rf5240.land.m5.trgrFit,'Color','#000000','LineStyle','-.','LineWidth',1);
    plot(rf5240.d,rf5240.sea.m5.trgrFit,'Color','#000000','LineStyle','-','LineWidth',1);
    hold off;
    xlabel(['antenna separation [m]';" "]);
    ylabel('RSSI [dBm]');
    xlim([0,500]);
    ylim([-100,30]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('5.240 GHz, h_t = 4.5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    linkaxes([rf2412_m2,rf2412_m5,rf5240_m2,rf5240_m5],'x');
    linkaxes([rf2412_m2,rf2412_m5,rf5240_m2,rf5240_m5],'y');
    
end

function vecLog = mw2log(vecMw)

    vecLog = 10.*log10(vecMw);

end

function vecMw = log2mw(vecLog)

    vecMw = 10.^((vecLog)./10);

end