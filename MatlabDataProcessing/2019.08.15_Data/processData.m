function processData

    % Set argument to 1 to import from .xlsx file (slow, but this must be
    % executed at least once); set to 0 to import from .mat file (faster)
    rfData = importDataRuns(0);
    assignin('base','rfDataRaw',rfData);
            
    % Remove errors in data
    rfData = removeErrors(rfData);
    
    % Plot all of the corrected data
    plotImported(rfData,1);
    
    % Remove data outside effective antenna beamwidth
    rfData = removeOutsideAntennaData(rfData);
        
    % Combine runs
    rfData = combineRuns(rfData);
    
    % Plot combined Rx Tx data
    plotRxTx(rfData,2);
    
    % Run binned mean, std dev, and confidence interval statistics on data
    rfData = binStatistics(rfData);
    
    % Plot binned mean, std dev and confidence interval
    plotBins(rfData,3);
    
    % Loss model processing
    rfModel = lossModels(rfData);
    
    % Plot loss models
    plotLossModels(rfData,rfModel,4);
    
    % Remove data ouside of crossover distance before fitting TRGR R2
    rfData = removeOutsideCrossoverDistance(rfData,rfModel);
    
    % Fit data to loss models
    rfModel = fitLossModels(rfModel,rfData);
       
    % Plot fits
    plotTrgrR2Fits(rfData,rfModel,5);
    plotTrgrFits(rfData,rfModel,6);
    
    % Assign to workspace
    assignin('base','rfData',rfData);
    assignin('base','rfModel',rfModel);
    
end

function rfData = importDataRuns(excelImport)

    if excelImport == 1
       
        % Import data, assign to organized structure
        rfData = data2struct('compiledData.xlsx');

        % Fix time stamps on data
        rfData = fixGpsTimeStamps(rfData);
        
    else
        
        % Alternatively, load the *.mat files
        load('rfData.mat');
        
    end
    
    % Calculate distances
    rfData = calculateDistances(rfData);

    % Synchronize time series from groundGps, robotGps, and rssi
    rfData = syncTimes(rfData);
    
    % Other relevant variables
    c = 299792458;                  % speed of light [m/s]
    rfData.f2 = 2.412*1E9;          % 2.4 GHz frequency [Hz] 
    rfData.f5 = 5.240*1E9;          % 5 GHz frequency [Hz]
    rfData.lambda2 = c/rfData.f2;   % wavelength [m]
    rfData.lambda5 = c/rfData.f5;   % wavelength [m]
    rfData.p2 = 18;                 % 2.4 GHz transmit power setting [dBm]
    rfData.p5 = 16;                 % 5 GHz transmit power setting [dBm]
    rfData.g2 = 5;                  % 2.4 GHz antenna gain [dBi]
    rfData.g5 = 7;                  % 5 GHz antenna gain [dBi]
    rfData.bw2 = deg2rad(30);       % 2 GHz vertical half-power beamwidth [deg]
    rfData.bw5 = deg2rad(15);       % 5 GHz vertical half-power beanwidth [deg]
    rfData.hRx = 2;                 % receiving antenna height [m]
    rfData.hTx2 = 2;                % transmitting antenna height low [m]
    rfData.hTx5 = 5;                % transmitting antenna height high [m]
    
    % Save to file
    save('rfData.mat','rfData');

end

function rfData = data2struct(filename)

    % Note that the two GNSS data vectors must be the same length in source
    % file!  

    % Read file
    rawData = readmatrix(filename);
    
    % Assign to organized structures
    rfData.rawData = rawData;
    i = 1;
    rfData.freq2.h2.land.run1.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run1.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run1.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run1.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run1.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run1.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run1.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run1.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run1.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run1.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run1.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.land.run2.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run1.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h2.sea.run2.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run1.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.land.run2.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run1.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq2.h5.sea.run2.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run1.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run2.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.land.run3.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run1.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h2.sea.run2.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run1.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.land.run2.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run1.signal.txRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.station.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.station.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.station.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.robot.gnssTime = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.robot.lat = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.robot.lon = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.signal.time = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.signal.timeConv = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.signal.sec = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.signal.rxRssi = rmmissing(rawData(:,i)); i = i+1;
    rfData.freq5.h5.sea.run2.signal.txRssi = rmmissing(rawData(:,i));
           
end

function rfData = fixGpsTimeStamps(rfData)
    
    % 2 GHz, 2m, land, run1
    rfData.freq2.h2.land.run1.station.gnssTime = zeroTime(rfData.freq2.h2.land.run1.station.gnssTime.*1E-9);
    rfData.freq2.h2.land.run1.robot.gnssTime = zeroTime(rfData.freq2.h2.land.run1.robot.gnssTime.*1E-9);
    
    % 2 GHz, 2m, land, run2
    rfData.freq2.h2.land.run2.station.gnssTime = zeroTime(rfData.freq2.h2.land.run2.station.gnssTime.*1E-9);
    rfData.freq2.h2.land.run2.robot.gnssTime = zeroTime(rfData.freq2.h2.land.run2.robot.gnssTime.*1E-9);
    
    % 2 GHz, 2m, sea, run1
    rfData.freq2.h2.sea.run1.station.gnssTime = zeroTime(rfData.freq2.h2.sea.run1.station.gnssTime.*1E-9);
    rfData.freq2.h2.sea.run1.robot.gnssTime = zeroTime(rfData.freq2.h2.sea.run1.robot.gnssTime.*1E-9);
    
    % 2 GHz, 2m, sea, run2
    rfData.freq2.h2.sea.run2.station.gnssTime = zeroTime(rfData.freq2.h2.sea.run2.station.gnssTime.*1E-9);
    rfData.freq2.h2.sea.run2.robot.gnssTime = zeroTime(rfData.freq2.h2.sea.run2.robot.gnssTime.*1E-9);
    
    % 2 GHz, 5m, land, run1
    rfData.freq2.h5.land.run1.station.gnssTime = zeroTime(rfData.freq2.h5.land.run1.station.gnssTime.*1E-9);
    rfData.freq2.h5.land.run1.robot.gnssTime = zeroTime(rfData.freq2.h5.land.run1.robot.gnssTime.*1E-9);
    
    % 2 GHz, 5m, land, run2
    rfData.freq2.h5.land.run2.station.gnssTime = zeroTime(rfData.freq2.h5.land.run2.station.gnssTime.*1E-9);
    rfData.freq2.h5.land.run2.robot.gnssTime = zeroTime(rfData.freq2.h5.land.run2.robot.gnssTime.*1E-9);
    
    % 2 GHz, 5m, sea, run1
    rfData.freq2.h5.sea.run1.station.gnssTime = zeroTime(rfData.freq2.h5.sea.run1.station.gnssTime.*1E-9);
    rfData.freq2.h5.sea.run1.robot.gnssTime = zeroTime(rfData.freq2.h5.sea.run1.robot.gnssTime.*1E-9);
    
    % 2 GHz, 5m, sea, run2
    rfData.freq2.h5.sea.run2.station.gnssTime = zeroTime(rfData.freq2.h5.sea.run2.station.gnssTime.*1E-9);
    rfData.freq2.h5.sea.run2.robot.gnssTime = zeroTime(rfData.freq2.h5.sea.run2.robot.gnssTime.*1E-9);
    
    % 5 GHz, 2m, land, run1
    rfData.freq5.h2.land.run1.station.gnssTime = zeroTime(rfData.freq5.h2.land.run1.station.gnssTime.*1E-9);
    rfData.freq5.h2.land.run1.robot.gnssTime = zeroTime(rfData.freq5.h2.land.run1.robot.gnssTime.*1E-9);
    
    % 5 GHz, 2m, land, run2
    rfData.freq5.h2.land.run2.station.gnssTime = zeroTime(rfData.freq5.h2.land.run2.station.gnssTime.*1E-9);
    rfData.freq5.h2.land.run2.robot.gnssTime = zeroTime(rfData.freq5.h2.land.run2.robot.gnssTime.*1E-9);
    
    % 5 GHz, 2m, land, run3
    rfData.freq5.h2.land.run3.station.gnssTime = zeroTime(rfData.freq5.h2.land.run3.station.gnssTime.*1E-9);
    rfData.freq5.h2.land.run3.robot.gnssTime = zeroTime(rfData.freq5.h2.land.run3.robot.gnssTime.*1E-9);
    
    % 5 GHz, 2m, sea, run1
    rfData.freq5.h2.sea.run1.station.gnssTime = zeroTime(rfData.freq5.h2.sea.run1.station.gnssTime.*1E-9);
    rfData.freq5.h2.sea.run1.robot.gnssTime = zeroTime(rfData.freq5.h2.sea.run1.robot.gnssTime.*1E-9);
    
    % 5 GHz, 2m, sea, run2
    rfData.freq5.h2.sea.run2.station.gnssTime = zeroTime(rfData.freq5.h2.sea.run2.station.gnssTime.*1E-9);
    rfData.freq5.h2.sea.run2.robot.gnssTime = zeroTime(rfData.freq5.h2.sea.run2.robot.gnssTime.*1E-9);
    
    % 5 GHz, 5m, land, run1
    rfData.freq5.h5.land.run1.station.gnssTime = zeroTime(rfData.freq5.h5.land.run1.station.gnssTime.*1E-9);
    rfData.freq5.h5.land.run1.robot.gnssTime = zeroTime(rfData.freq5.h5.land.run1.robot.gnssTime.*1E-9);
    
    % 5 GHz, 5m, land, run2
    rfData.freq5.h5.land.run2.station.gnssTime = zeroTime(rfData.freq5.h5.land.run2.station.gnssTime.*1E-9);
    rfData.freq5.h5.land.run2.robot.gnssTime = zeroTime(rfData.freq5.h5.land.run2.robot.gnssTime.*1E-9);
    
    % 5 GHz, 5m, sea, run1
    rfData.freq5.h5.sea.run1.station.gnssTime = zeroTime(rfData.freq5.h5.sea.run1.station.gnssTime.*1E-9);
    rfData.freq5.h5.sea.run1.robot.gnssTime = zeroTime(rfData.freq5.h5.sea.run1.robot.gnssTime.*1E-9);
    
    % 5 GHz, 5m, sea, run2
    rfData.freq5.h5.sea.run2.station.gnssTime = zeroTime(rfData.freq5.h5.sea.run2.station.gnssTime.*1E-9);
    rfData.freq5.h5.sea.run2.robot.gnssTime = zeroTime(rfData.freq5.h5.sea.run2.robot.gnssTime.*1E-9); 
    
end

function tVec = zeroTime(tVec)

    start = tVec(1,1);
    tVec = tVec-start;

end

function rfData = calculateDistances(rfData)
    
    % 2GHz, 2m, land, run1
    rfData.freq2.h2.land.run1.dist = calculateDistance(rfData.freq2.h2.land.run1.station.lat,...
        rfData.freq2.h2.land.run1.station.lon,rfData.freq2.h2.land.run1.robot.lat,rfData.freq2.h2.land.run1.robot.lon);
    
    % 2GHz, 2m, land, run2
    rfData.freq2.h2.land.run2.dist = calculateDistance(rfData.freq2.h2.land.run2.station.lat,...
        rfData.freq2.h2.land.run2.station.lon,rfData.freq2.h2.land.run2.robot.lat,rfData.freq2.h2.land.run2.robot.lon);
    
    % 2GHz, 2m, sea, run1
    rfData.freq2.h2.sea.run1.dist = calculateDistance(rfData.freq2.h2.sea.run1.station.lat,...
        rfData.freq2.h2.sea.run1.station.lon,rfData.freq2.h2.sea.run1.robot.lat,rfData.freq2.h2.sea.run1.robot.lon);
    
    % 2GHz, 2m, sea, run2
    rfData.freq2.h2.sea.run2.dist = calculateDistance(rfData.freq2.h2.sea.run2.station.lat,...
        rfData.freq2.h2.sea.run2.station.lon,rfData.freq2.h2.sea.run2.robot.lat,rfData.freq2.h2.sea.run2.robot.lon);
    
    % 2GHz, 5m, land, run1
    rfData.freq2.h5.land.run1.dist = calculateDistance(rfData.freq2.h5.land.run1.station.lat,...
        rfData.freq2.h5.land.run1.station.lon,rfData.freq2.h5.land.run1.robot.lat,rfData.freq2.h5.land.run1.robot.lon);
    
    % 2GHz, 5m, land, run2
    rfData.freq2.h5.land.run2.dist = calculateDistance(rfData.freq2.h5.land.run2.station.lat,...
        rfData.freq2.h5.land.run2.station.lon,rfData.freq2.h5.land.run2.robot.lat,rfData.freq2.h5.land.run2.robot.lon);
    
    % 2GHz, 5m, sea, run1
    rfData.freq2.h5.sea.run1.dist = calculateDistance(rfData.freq2.h5.sea.run1.station.lat,...
        rfData.freq2.h5.sea.run1.station.lon,rfData.freq2.h5.sea.run1.robot.lat,rfData.freq2.h5.sea.run1.robot.lon);
    
    % 2GHz, 5m, sea, run2
    rfData.freq2.h5.sea.run2.dist = calculateDistance(rfData.freq2.h5.sea.run2.station.lat,...
        rfData.freq2.h5.sea.run2.station.lon,rfData.freq2.h5.sea.run2.robot.lat,rfData.freq2.h5.sea.run2.robot.lon);
    
    % 5GHz, 2m, land, run1
    rfData.freq5.h2.land.run1.dist = calculateDistance(rfData.freq5.h2.land.run1.station.lat,...
        rfData.freq5.h2.land.run1.station.lon,rfData.freq5.h2.land.run1.robot.lat,rfData.freq5.h2.land.run1.robot.lon);
    
    % 5GHz, 2m, land, run2
    rfData.freq5.h2.land.run2.dist = calculateDistance(rfData.freq5.h2.land.run2.station.lat,...
        rfData.freq5.h2.land.run2.station.lon,rfData.freq5.h2.land.run2.robot.lat,rfData.freq5.h2.land.run2.robot.lon);
    
    % 5GHz, 2m, land, run3
    rfData.freq5.h2.land.run3.dist = calculateDistance(rfData.freq5.h2.land.run3.station.lat,...
        rfData.freq5.h2.land.run3.station.lon,rfData.freq5.h2.land.run3.robot.lat,rfData.freq5.h2.land.run3.robot.lon);
    
    % 5GHz, 2m, sea, run1
    rfData.freq5.h2.sea.run1.dist = calculateDistance(rfData.freq5.h2.sea.run1.station.lat,...
        rfData.freq5.h2.sea.run1.station.lon,rfData.freq5.h2.sea.run1.robot.lat,rfData.freq5.h2.sea.run1.robot.lon);
    
    % 5GHz, 2m, sea, run2
    rfData.freq5.h2.sea.run2.dist = calculateDistance(rfData.freq5.h2.sea.run2.station.lat,...
        rfData.freq5.h2.sea.run2.station.lon,rfData.freq5.h2.sea.run2.robot.lat,rfData.freq5.h2.sea.run2.robot.lon);
    
    % 5GHz, 5m, land, run1
    rfData.freq5.h5.land.run1.dist = calculateDistance(rfData.freq5.h5.land.run1.station.lat,...
        rfData.freq5.h5.land.run1.station.lon,rfData.freq5.h5.land.run1.robot.lat,rfData.freq5.h5.land.run1.robot.lon);
    
    % 5 GHz, 5m, land, run2
    rfData.freq5.h5.land.run2.dist = calculateDistance(rfData.freq5.h5.land.run2.station.lat,...
        rfData.freq5.h5.land.run2.station.lon,rfData.freq5.h5.land.run2.robot.lat,rfData.freq5.h5.land.run2.robot.lon);
    
    % 5GHz, 5m, sea, run1
    rfData.freq5.h5.sea.run1.dist = calculateDistance(rfData.freq5.h5.sea.run1.station.lat,...
        rfData.freq5.h5.sea.run1.station.lon,rfData.freq5.h5.sea.run1.robot.lat,rfData.freq5.h5.sea.run1.robot.lon);
    
    % 5GHz, 5m, sea, run2
    rfData.freq5.h5.sea.run2.dist = calculateDistance(rfData.freq5.h5.sea.run2.station.lat,...
        rfData.freq5.h5.sea.run2.station.lon,rfData.freq5.h5.sea.run2.robot.lat,rfData.freq5.h5.sea.run2.robot.lon);

end

function dist = calculateDistance(stationLat,stationLon,robotLat,robotLon)

    llo = [stationLat(1,1),stationLon(1,1)];
    lla = [robotLat(:,1),robotLon(:,1),zeros(size(stationLat(:,1)))];
    flat = lla2flat(lla,llo,0,0);
    dist = sqrt(flat(:,1).^2+flat(:,2).^2);

end

function rfData = syncTimes(rfData)

    % 2GHz, 2m, land, run1
    [rfData.freq2.h2.land.run1.distTs,rfData.freq2.h2.land.run1.rssiTs] =...
        syncDistRssi(rfData.freq2.h2.land.run1.station.gnssTime,...
        rfData.freq2.h2.land.run1.signal.sec,...
        rfData.freq2.h2.land.run1.dist,...
        rfData.freq2.h2.land.run1.signal.rxRssi,...
        rfData.freq2.h2.land.run1.signal.txRssi);
    
    % 2GHz, 2m, land, run2
    [rfData.freq2.h2.land.run2.distTs,rfData.freq2.h2.land.run2.rssiTs] =...
        syncDistRssi(rfData.freq2.h2.land.run2.station.gnssTime,...
        rfData.freq2.h2.land.run2.signal.sec,...
        rfData.freq2.h2.land.run2.dist,...
        rfData.freq2.h2.land.run2.signal.rxRssi,...
        rfData.freq2.h2.land.run2.signal.txRssi);    
        
    % 2GHz, 2m, sea, run1
    [rfData.freq2.h2.sea.run1.distTs,rfData.freq2.h2.sea.run1.rssiTs] =...
        syncDistRssi(rfData.freq2.h2.sea.run1.station.gnssTime,...
        rfData.freq2.h2.sea.run1.signal.sec,...
        rfData.freq2.h2.sea.run1.dist,...
        rfData.freq2.h2.sea.run1.signal.rxRssi,...
        rfData.freq2.h2.sea.run1.signal.txRssi);
       
    % 2GHz, 2m, sea, run2
    [rfData.freq2.h2.sea.run2.distTs,rfData.freq2.h2.sea.run2.rssiTs] =...
        syncDistRssi(rfData.freq2.h2.sea.run2.station.gnssTime,...
        rfData.freq2.h2.sea.run2.signal.sec,...
        rfData.freq2.h2.sea.run2.dist,...
        rfData.freq2.h2.sea.run2.signal.rxRssi,...
        rfData.freq2.h2.sea.run2.signal.txRssi);
        
    % 2GHz, 5m, land, run1
    [rfData.freq2.h5.land.run1.distTs,rfData.freq2.h5.land.run1.rssiTs] =...
        syncDistRssi(rfData.freq2.h5.land.run1.station.gnssTime,...
        rfData.freq2.h5.land.run1.signal.sec,...
        rfData.freq2.h5.land.run1.dist,...
        rfData.freq2.h5.land.run1.signal.rxRssi,...
        rfData.freq2.h5.land.run1.signal.txRssi);
        
    % 2GHz, 5m, land, run2
    [rfData.freq2.h5.land.run2.distTs,rfData.freq2.h5.land.run2.rssiTs] =...
        syncDistRssi(rfData.freq2.h5.land.run2.station.gnssTime,...
        rfData.freq2.h5.land.run2.signal.sec,...
        rfData.freq2.h5.land.run2.dist,...
        rfData.freq2.h5.land.run2.signal.rxRssi,...
        rfData.freq2.h5.land.run2.signal.txRssi);
        
    % 2GHz, 5m, sea, run1
    [rfData.freq2.h5.sea.run1.distTs,rfData.freq2.h5.sea.run1.rssiTs] =...
        syncDistRssi(rfData.freq2.h5.sea.run1.station.gnssTime,...
        rfData.freq2.h5.sea.run1.signal.sec,...
        rfData.freq2.h5.sea.run1.dist,...
        rfData.freq2.h5.sea.run1.signal.rxRssi,...
        rfData.freq2.h5.sea.run1.signal.txRssi);
        
    % 2GHz, 5m, sea, run2
    [rfData.freq2.h5.sea.run2.distTs,rfData.freq2.h5.sea.run2.rssiTs] =...
        syncDistRssi(rfData.freq2.h5.sea.run2.station.gnssTime,...
        rfData.freq2.h5.sea.run2.signal.sec,...
        rfData.freq2.h5.sea.run2.dist,...
        rfData.freq2.h5.sea.run2.signal.rxRssi,...
        rfData.freq2.h5.sea.run2.signal.txRssi);
        
    % 5GHz, 2m, land, run1
    [rfData.freq5.h2.land.run1.distTs,rfData.freq5.h2.land.run1.rssiTs] =...
        syncDistRssi(rfData.freq5.h2.land.run1.station.gnssTime,...
        rfData.freq5.h2.land.run1.signal.sec,...
        rfData.freq5.h2.land.run1.dist,...
        rfData.freq5.h2.land.run1.signal.rxRssi,...
        rfData.freq5.h2.land.run1.signal.txRssi);
        
    % 5GHz, 2m, land, run2
    [rfData.freq5.h2.land.run2.distTs,rfData.freq5.h2.land.run2.rssiTs] =...
        syncDistRssi(rfData.freq5.h2.land.run2.station.gnssTime,...
        rfData.freq5.h2.land.run2.signal.sec,...
        rfData.freq5.h2.land.run2.dist,...
        rfData.freq5.h2.land.run2.signal.rxRssi,...
        rfData.freq5.h2.land.run2.signal.txRssi);
    
    % 5GHz, 2m, land, run3
    [rfData.freq5.h2.land.run3.distTs,rfData.freq5.h2.land.run3.rssiTs] =...
        syncDistRssi(rfData.freq5.h2.land.run3.station.gnssTime,...
        rfData.freq5.h2.land.run3.signal.sec,...
        rfData.freq5.h2.land.run3.dist,...
        rfData.freq5.h2.land.run3.signal.rxRssi,...
        rfData.freq5.h2.land.run3.signal.txRssi);
        
    % 5GHz, 2m, sea, run1
    [rfData.freq5.h2.sea.run1.distTs,rfData.freq5.h2.sea.run1.rssiTs] =...
        syncDistRssi(rfData.freq5.h2.sea.run1.station.gnssTime,...
        rfData.freq5.h2.sea.run1.signal.sec,...
        rfData.freq5.h2.sea.run1.dist,...
        rfData.freq5.h2.sea.run1.signal.rxRssi,...
        rfData.freq5.h2.sea.run1.signal.txRssi);
        
    % 5GHz, 2m, sea, run2
    [rfData.freq5.h2.sea.run2.distTs,rfData.freq5.h2.sea.run2.rssiTs] =...
        syncDistRssi(rfData.freq5.h2.sea.run2.station.gnssTime,...
        rfData.freq5.h2.sea.run2.signal.sec,...
        rfData.freq5.h2.sea.run2.dist,...
        rfData.freq5.h2.sea.run2.signal.rxRssi,...
        rfData.freq5.h2.sea.run2.signal.txRssi);
    
    % 5GHz, 5m, land, run1
    [rfData.freq5.h5.land.run1.distTs,rfData.freq5.h5.land.run1.rssiTs] =...
        syncDistRssi(rfData.freq5.h5.land.run1.station.gnssTime,...
        rfData.freq5.h5.land.run1.signal.sec,...
        rfData.freq5.h5.land.run1.dist,...
        rfData.freq5.h5.land.run1.signal.rxRssi,...
        rfData.freq5.h5.land.run1.signal.txRssi);
    
    % 5GHz, 5m, land, run2
    [rfData.freq5.h5.land.run2.distTs,rfData.freq5.h5.land.run2.rssiTs] =...
        syncDistRssi(rfData.freq5.h5.land.run2.station.gnssTime,...
        rfData.freq5.h5.land.run2.signal.sec,...
        rfData.freq5.h5.land.run2.dist,...
        rfData.freq5.h5.land.run2.signal.rxRssi,...
        rfData.freq5.h5.land.run2.signal.txRssi);
    
    % 5GHz, 5m, sea, run1
    [rfData.freq5.h5.sea.run1.distTs,rfData.freq5.h5.sea.run1.rssiTs] =...
        syncDistRssi(rfData.freq5.h5.sea.run1.station.gnssTime,...
        rfData.freq5.h5.sea.run1.signal.sec,...
        rfData.freq5.h5.sea.run1.dist,...
        rfData.freq5.h5.sea.run1.signal.rxRssi,...
        rfData.freq5.h5.sea.run1.signal.txRssi);
        
    % 5GHz, 5m, sea, run2
    [rfData.freq5.h5.sea.run2.distTs,rfData.freq5.h5.sea.run2.rssiTs] =...
        syncDistRssi(rfData.freq5.h5.sea.run2.station.gnssTime,...
        rfData.freq5.h5.sea.run2.signal.sec,...
        rfData.freq5.h5.sea.run2.dist,...
        rfData.freq5.h5.sea.run2.signal.rxRssi,...
        rfData.freq5.h5.sea.run2.signal.txRssi);
    
end

function [distTimestring,rssiTimestring] = syncDistRssi(stationTime,rssiTime,dist,rssiRx,rssiTx)

    dsDist = tVec2datestring(stationTime);              % create distance datestring variable (based on ground station timestamp)
    dsRssi = tVec2datestring(rssiTime);                 % create rssi datestring variable (based on rssi timestamp)
    tsDist = timeseries(dist,dsDist);                   % create distance timeseries variable
    tsRssi = timeseries([rssiRx,rssiTx],dsRssi);        % createrssi timeseries variable
    [distTimestring,rssiTimestring] =...
        synchronize(tsDist,tsRssi,'Union');      % synchronize distance and rssi timeseries variables    

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

function rfData = removeErrors(rfData)

    % Remove errors in timeseries data for 2GHz, 2m, land, run1
    rfData.freq2.h2.land.run1.distTs =...
        delsample(rfData.freq2.h2.land.run1.distTs,'Index',[68:89,138,191:228,338:396,515]);
    rfData.freq2.h2.land.run1.rssiTs =...
        delsample(rfData.freq2.h2.land.run1.rssiTs,'Index',[68:89,138,191:228,338:396,515]);
    
    % Remove errors in timeseries data for 2GHz, 2m, land, run2
    rfData.freq2.h2.land.run2.distTs =...
        delsample(rfData.freq2.h2.land.run2.distTs,'Index',[73,285:384,399:402]);
    rfData.freq2.h2.land.run2.rssiTs =...
        delsample(rfData.freq2.h2.land.run2.rssiTs,'Index',[73,285:384,399:402]);
    
    % Remove errors in timeseries data for 2GHz, 2m, sea, run1
    rfData.freq2.h2.sea.run1.distTs =...
        delsample(rfData.freq2.h2.sea.run1.distTs,'Index',[32,477,695]);
    rfData.freq2.h2.sea.run1.rssiTs =...
        delsample(rfData.freq2.h2.sea.run1.rssiTs,'Index',[32,477,695]);
    
    % Remove errors in timeseries data for 2GHz, 2m, sea, run2
    rfData.freq2.h2.sea.run2.distTs =...
        delsample(rfData.freq2.h2.sea.run2.distTs,'Index',473);
    rfData.freq2.h2.sea.run2.rssiTs =...
        delsample(rfData.freq2.h2.sea.run2.rssiTs,'Index',473);
    
    % Remove errors in timeseries data for 2GHz, 5m, land, run1
    rfData.freq2.h5.land.run1.distTs =...
        delsample(rfData.freq2.h5.land.run1.distTs,'Index',[14,172,191:337]);
    rfData.freq2.h5.land.run1.rssiTs =...
        delsample(rfData.freq2.h5.land.run1.rssiTs,'Index',[14,172,191:337]);
    
    % Remove errors in timeseries data for 2GHz, 5m, land, run2
    rfData.freq2.h5.land.run2.distTs =...
        delsample(rfData.freq2.h5.land.run2.distTs,'Index',[104,183:245,291:372,421]);
    rfData.freq2.h5.land.run2.rssiTs =...
        delsample(rfData.freq2.h5.land.run2.rssiTs,'Index',[104,183:245,291:372,421]);
    
    % Remove errors in timeseries data for 2GHz, 5m, sea, run1
    rfData.freq2.h5.sea.run1.distTs =...
        delsample(rfData.freq2.h5.sea.run1.distTs,'Index',[90,540,609:728]);
    rfData.freq2.h5.sea.run1.rssiTs =...
        delsample(rfData.freq2.h5.sea.run1.rssiTs,'Index',[90,540,609:728]);
    
    % Remove errors in timeseries data for 2GHz, 5m, sea, run2
    rfData.freq2.h5.sea.run2.distTs =...
        delsample(rfData.freq2.h5.sea.run2.distTs,'Index',[210:277]);
    rfData.freq2.h5.sea.run2.rssiTs =...
        delsample(rfData.freq2.h5.sea.run2.rssiTs,'Index',[210:277]);
    
    % Remove errors in timeseries data for 5GHz, 2m, land, run1
    rfData.freq5.h2.land.run1.distTs =...
        delsample(rfData.freq5.h2.land.run1.distTs,'Index',[197:208]);
    rfData.freq5.h2.land.run1.rssiTs =...
        delsample(rfData.freq5.h2.land.run1.rssiTs,'Index',[197:208]);
    
    % Remove errors in timeseries data for 5GHz, 2m, land, run2
    % No errors
    
    % Remove errors in timeseries data for 5GHz, 2m, land, run3
    rfData.freq5.h2.land.run3.distTs =...
        delsample(rfData.freq5.h2.land.run3.distTs,'Index',217);
    rfData.freq5.h2.land.run3.rssiTs =...
        delsample(rfData.freq5.h2.land.run3.rssiTs,'Index',217);
    
    % Remove errors in timeseries data for 5GHz, 2m, sea, run1
    rfData.freq5.h2.sea.run1.distTs =...
        delsample(rfData.freq5.h2.sea.run1.distTs,'Index',[128,357]);
    rfData.freq5.h2.sea.run1.rssiTs =...
        delsample(rfData.freq5.h2.sea.run1.rssiTs,'Index',[128,357]);
    
    % Remove errors in timeseries data for 5GHz, 2m, sea, run2
    rfData.freq5.h2.sea.run2.distTs =...
        delsample(rfData.freq5.h2.sea.run2.distTs,'Index',[106,242:248,308,502,705]);
    rfData.freq5.h2.sea.run2.rssiTs =...
        delsample(rfData.freq5.h2.sea.run2.rssiTs,'Index',[106,242:248,308,502,705]);
    
    % Remove errors in timeseries data for 5GHz, 5m, land, run1
    rfData.freq5.h5.land.run1.distTs =...
        delsample(rfData.freq5.h5.land.run1.distTs,'Index',[428:439,441:446,556]);
    rfData.freq5.h5.land.run1.rssiTs =...
        delsample(rfData.freq5.h5.land.run1.rssiTs,'Index',[428:439,441:446,556]);
    
    % Remove errors in timeseries data for 5GHz, 5m, land, run2
    rfData.freq5.h5.land.run2.distTs =...
        delsample(rfData.freq5.h5.land.run2.distTs,'Index',[183:197,267:298,329:384,438:517,549:564]);
    rfData.freq5.h5.land.run2.rssiTs =...
        delsample(rfData.freq5.h5.land.run2.rssiTs,'Index',[183:197,267:298,329:384,438:517,549:564]);
    
    % Remove errors in timeseries data for 5GHz, 5m, sea, run1
    rfData.freq5.h5.sea.run1.distTs =...
        delsample(rfData.freq5.h5.sea.run1.distTs,'Index',[85,269:273,606]);
    rfData.freq5.h5.sea.run1.rssiTs =...
        delsample(rfData.freq5.h5.sea.run1.rssiTs,'Index',[85,269:273,606]);
    
    % Remove errors in timeseries data for 5GHz, 5m, sea, run2
    rfData.freq5.h5.sea.run2.distTs =...
        delsample(rfData.freq5.h5.sea.run2.distTs,'Index',317);
    rfData.freq5.h5.sea.run2.rssiTs =...
        delsample(rfData.freq5.h5.sea.run2.rssiTs,'Index',317);
    
end

function plotImported(rfData,figNum)

    % Close all open figures
    close all;

    % Create new figure
    figure(figNum);
    
    % Plot variables
    xMin = 0;
    xMax = 550;
    yMin = -100;
    yMax = -20;
    titleFontSize = 22;
    defaultFontSize = 20;
    
    % 2GHz, 2m, land
    f2h2l = subplot(2,4,1);
    hold on;
    plot(rfData.freq2.h2.land.run1.distTs.Data,...
        rfData.freq2.h2.land.run1.rssiTs.Data(:,1),'.');
    plot(rfData.freq2.h2.land.run1.distTs.Data,...
        rfData.freq2.h2.land.run1.rssiTs.Data(:,2),'.');
    plot(rfData.freq2.h2.land.run2.distTs.Data,...
        rfData.freq2.h2.land.run2.rssiTs.Data(:,1),'.');
    plot(rfData.freq2.h2.land.run2.distTs.Data,...
        rfData.freq2.h2.land.run2.rssiTs.Data(:,2),'.');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('Run 1 Rx','Run 1 Tx','Run 2 Rx','Run 2 Tx');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 2 m, Over Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 2m, sea
    f2h2s = subplot(2,4,5);
    hold on;
    plot(rfData.freq2.h2.sea.run1.distTs.Data,...
        rfData.freq2.h2.sea.run1.rssiTs.Data(:,1),'.');
    plot(rfData.freq2.h2.sea.run1.distTs.Data,...
        rfData.freq2.h2.sea.run1.rssiTs.Data(:,2),'.');
    plot(rfData.freq2.h2.sea.run2.distTs.Data,...
        rfData.freq2.h2.sea.run2.rssiTs.Data(:,1),'.');
    plot(rfData.freq2.h2.sea.run2.distTs.Data,...
        rfData.freq2.h2.sea.run2.rssiTs.Data(:,2),'.');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('Run 1 Rx','Run 1 Tx','Run 2 Rx','Run 2 Tx');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 2 m, Over Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 5m, land
    f2h5l = subplot(2,4,2);
    hold on;
    plot(rfData.freq2.h5.land.run1.distTs.Data,...
        rfData.freq2.h5.land.run1.rssiTs.Data(:,1),'.');
    plot(rfData.freq2.h5.land.run1.distTs.Data,...
        rfData.freq2.h5.land.run1.rssiTs.Data(:,2),'.');
    plot(rfData.freq2.h5.land.run2.distTs.Data,...
        rfData.freq2.h5.land.run2.rssiTs.Data(:,1),'.');
    plot(rfData.freq2.h5.land.run2.distTs.Data,...
        rfData.freq2.h5.land.run2.rssiTs.Data(:,2),'.');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('Run 1 Rx','Run 1 Tx','Run 2 Rx','Run 2 Tx');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 5 m, Over Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 5m, sea
    f2h5s = subplot(2,4,6);
    hold on;
    plot(rfData.freq2.h5.sea.run1.distTs.Data,...
        rfData.freq2.h5.sea.run1.rssiTs.Data(:,1),'.');
    plot(rfData.freq2.h5.sea.run1.distTs.Data,...
        rfData.freq2.h5.sea.run1.rssiTs.Data(:,2),'.');
    plot(rfData.freq2.h5.sea.run2.distTs.Data,...
        rfData.freq2.h5.sea.run2.rssiTs.Data(:,1),'.');
    plot(rfData.freq2.h5.sea.run2.distTs.Data,...
        rfData.freq2.h5.sea.run2.rssiTs.Data(:,2),'.');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('Run 1 Rx','Run 1 Tx','Run 2 Rx','Run 2 Tx');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 5 m, Over Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 2m, land
    f5h2l = subplot(2,4,3);
    hold on;
    plot(rfData.freq5.h2.land.run1.distTs.Data,...
        rfData.freq5.h2.land.run1.rssiTs.Data(:,1),'.');
    plot(rfData.freq5.h2.land.run1.distTs.Data,...
        rfData.freq5.h2.land.run1.rssiTs.Data(:,2),'.');
    plot(rfData.freq5.h2.land.run2.distTs.Data,...
        rfData.freq5.h2.land.run2.rssiTs.Data(:,1),'.');
    plot(rfData.freq5.h2.land.run2.distTs.Data,...
        rfData.freq5.h2.land.run2.rssiTs.Data(:,2),'.');
    plot(rfData.freq5.h2.land.run3.distTs.Data,...
        rfData.freq5.h2.land.run3.rssiTs.Data(:,1),'.');
    plot(rfData.freq5.h2.land.run3.distTs.Data,...
        rfData.freq5.h2.land.run3.rssiTs.Data(:,2),'.');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('Run 1 Rx','Run 1 Tx','Run 2 Rx','Run 2 Tx','Run 3 Rx','Run 3 Tx');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 2 m, Over Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 2m, sea
    f5h2s = subplot(2,4,7);
    hold on;
    plot(rfData.freq5.h2.sea.run1.distTs.Data,...
        rfData.freq5.h2.sea.run1.rssiTs.Data(:,1),'.');
    plot(rfData.freq5.h2.sea.run1.distTs.Data,...
        rfData.freq5.h2.sea.run1.rssiTs.Data(:,2),'.');
    plot(rfData.freq5.h2.sea.run2.distTs.Data,...
        rfData.freq5.h2.sea.run2.rssiTs.Data(:,1),'.');
    plot(rfData.freq5.h2.sea.run2.distTs.Data,...
        rfData.freq5.h2.sea.run2.rssiTs.Data(:,2),'.');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('Run 1 Rx','Run 1 Tx','Run 2 Rx','Run 2 Tx');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 2 m, Over Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 5m, land
    f5h5l = subplot(2,4,4);
    hold on;
    plot(rfData.freq5.h5.land.run1.distTs.Data,...
        rfData.freq5.h5.land.run1.rssiTs.Data(:,1),'.');
    plot(rfData.freq5.h5.land.run1.distTs.Data,...
        rfData.freq5.h5.land.run1.rssiTs.Data(:,2),'.');
    plot(rfData.freq5.h5.land.run2.distTs.Data,...
        rfData.freq5.h5.land.run2.rssiTs.Data(:,1),'.');
    plot(rfData.freq5.h5.land.run2.distTs.Data,...
        rfData.freq5.h5.land.run2.rssiTs.Data(:,2),'.');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('Run 1 Rx','Run 1 Tx','Run 2 Rx','Run 2 Tx');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 5 m, Over Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 5m, sea
    f5h5s = subplot(2,4,8);
    hold on;
    plot(rfData.freq5.h5.sea.run1.distTs.Data,...
        rfData.freq5.h5.sea.run1.rssiTs.Data(:,1),'.');
    plot(rfData.freq5.h5.sea.run1.distTs.Data,...
        rfData.freq5.h5.sea.run1.rssiTs.Data(:,2),'.');
    plot(rfData.freq5.h5.sea.run2.distTs.Data,...
        rfData.freq5.h5.sea.run2.rssiTs.Data(:,1),'.');
    plot(rfData.freq5.h5.sea.run2.distTs.Data,...
        rfData.freq5.h5.sea.run2.rssiTs.Data(:,2),'.');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('Run 1 Rx','Run 1 Tx','Run 2 Rx','Run 2 Tx');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 5 m, Over Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % Link axes
    linkaxes([f2h2l,f2h2s,f2h5l,f2h5s,f5h2l,f5h2s,f5h5l,f5h5s],'x');
    linkaxes([f2h2l,f2h2s,f2h5l,f2h5s,f5h2l,f5h2s,f5h5l,f5h5s],'y');

end

function rfData = removeOutsideAntennaData(rfData)

    % 2GHz, 2m, land
    minDist = antennaMinDist(rfData.hTx2,rfData.bw2);
    [rfData.freq2.h2.land.run1.distTs,rfData.freq2.h2.land.run1.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq2.h2.land.run1.distTs,...
        rfData.freq2.h2.land.run1.rssiTs,minDist);
    [rfData.freq2.h2.land.run2.distTs,rfData.freq2.h2.land.run2.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq2.h2.land.run2.distTs,...
        rfData.freq2.h2.land.run2.rssiTs,minDist);
    
    % 2GHz, 2m, sea
    minDist = antennaMinDist(rfData.hTx2,rfData.bw2);
    [rfData.freq2.h2.sea.run1.distTs,rfData.freq2.h2.sea.run1.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq2.h2.sea.run1.distTs,...
        rfData.freq2.h2.sea.run1.rssiTs,minDist);
    [rfData.freq2.h2.sea.run2.distTs,rfData.freq2.h2.sea.run2.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq2.h2.sea.run2.distTs,...
        rfData.freq2.h2.sea.run2.rssiTs,minDist);
    
    % 2GHz, 5m, land
    minDist = antennaMinDist(rfData.hTx5,rfData.bw2);
    [rfData.freq2.h5.land.run1.distTs,rfData.freq2.h5.land.run1.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq2.h5.land.run1.distTs,...
        rfData.freq2.h5.land.run1.rssiTs,minDist);
    [rfData.freq2.h5.land.run2.distTs,rfData.freq2.h5.land.run2.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq2.h5.land.run2.distTs,...
        rfData.freq2.h5.land.run2.rssiTs,minDist);
    
    % 2GHz, 5m, sea
    minDist = antennaMinDist(rfData.hTx5,rfData.bw2);
    [rfData.freq2.h5.sea.run1.distTs,rfData.freq2.h5.sea.run1.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq2.h5.sea.run1.distTs,...
        rfData.freq2.h5.sea.run1.rssiTs,minDist);
    [rfData.freq2.h5.sea.run2.distTs,rfData.freq2.h5.sea.run2.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq2.h5.sea.run2.distTs,...
        rfData.freq2.h5.sea.run2.rssiTs,minDist);
    
    % 5GHz, 2m, land
    minDist = antennaMinDist(rfData.hTx2,rfData.bw5);
    [rfData.freq5.h2.land.run1.distTs,rfData.freq5.h2.land.run1.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq5.h2.land.run1.distTs,...
        rfData.freq5.h2.land.run1.rssiTs,minDist);
    [rfData.freq5.h2.land.run2.distTs,rfData.freq5.h2.land.run2.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq5.h2.land.run2.distTs,...
        rfData.freq5.h2.land.run2.rssiTs,minDist);
    [rfData.freq5.h2.land.run3.distTs,rfData.freq5.h2.land.run3.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq5.h2.land.run3.distTs,...
        rfData.freq5.h2.land.run3.rssiTs,minDist);
    
    % 5GHz, 2m, sea
    minDist = antennaMinDist(rfData.hTx2,rfData.bw5);
    [rfData.freq5.h2.sea.run1.distTs,rfData.freq5.h2.sea.run1.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq5.h2.sea.run1.distTs,...
        rfData.freq5.h2.sea.run1.rssiTs,minDist);
    [rfData.freq5.h2.sea.run2.distTs,rfData.freq5.h2.sea.run2.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq5.h2.sea.run2.distTs,...
        rfData.freq5.h2.sea.run2.rssiTs,minDist);
    
    % 5GHz, 5m, land
    minDist = antennaMinDist(rfData.hTx5,rfData.bw5);
    [rfData.freq5.h5.land.run1.distTs,rfData.freq5.h5.land.run1.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq5.h5.land.run1.distTs,...
        rfData.freq5.h5.land.run1.rssiTs,minDist);
    [rfData.freq5.h5.land.run2.distTs,rfData.freq5.h5.land.run2.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq5.h5.land.run2.distTs,...
        rfData.freq5.h5.land.run2.rssiTs,minDist);
    
    % 5GHz, 5m, sea
    minDist = antennaMinDist(rfData.hTx5,rfData.bw5);
    [rfData.freq5.h5.sea.run1.distTs,rfData.freq5.h5.sea.run1.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq5.h5.sea.run1.distTs,...
        rfData.freq5.h5.sea.run1.rssiTs,minDist);
    [rfData.freq5.h5.sea.run2.distTs,rfData.freq5.h5.sea.run2.rssiTs] =...
        removeDistRssiTsMinDist(rfData.freq5.h5.sea.run2.distTs,...
        rfData.freq5.h5.sea.run2.rssiTs,minDist);
    
end

function minDist = antennaMinDist(antennaHeight,antennaBeamwidth)

    r1MinDist = antennaHeight;
    beamwidthMinDist = antennaHeight/(tan(antennaBeamwidth));
    
    if r1MinDist > beamwidthMinDist
        minDist = r1MinDist;
    else
        minDist = beamwidthMinDist;
    end

end

function [distTs,rssiTs] = removeDistRssiTsMinDist(distTs,rssiTs,minDist)

    iRemove = distTs.Data < minDist;                    % indexed array of all distance values smaller than minDist
    distTs = delsample(distTs,'Index',find(iRemove));   % remove indexed array from distance timeseries
    rssiTs = delsample(rssiTs,'Index',find(iRemove));   % remove indexed array from RSSI timeseries

end

function rfData = combineRuns(rfData)

    % 2GHz, 2m, land
    rfData.freq2.h2.land.allDistData = [...
        rfData.freq2.h2.land.run1.distTs.Data;
        rfData.freq2.h2.land.run2.distTs.Data];
    rfData.freq2.h2.land.allRssiRxData = [...
        rfData.freq2.h2.land.run1.rssiTs.Data(:,1);
        rfData.freq2.h2.land.run2.rssiTs.Data(:,1)];
    rfData.freq2.h2.land.allRssiTxData = [...
        rfData.freq2.h2.land.run1.rssiTs.Data(:,2);
        rfData.freq2.h2.land.run2.rssiTs.Data(:,2)];
    rfData.freq2.h2.land.allRssiRxTxData =...
        mean([rfData.freq2.h2.land.allRssiRxData,rfData.freq2.h2.land.allRssiTxData],2);
    
    % 2GHz, 2m, sea
    rfData.freq2.h2.sea.allDistData = [...
        rfData.freq2.h2.sea.run1.distTs.Data;
        rfData.freq2.h2.sea.run2.distTs.Data];
    rfData.freq2.h2.sea.allRssiRxData = [...
        rfData.freq2.h2.sea.run1.rssiTs.Data(:,1);
        rfData.freq2.h2.sea.run2.rssiTs.Data(:,1)];
    rfData.freq2.h2.sea.allRssiTxData = [...
        rfData.freq2.h2.sea.run1.rssiTs.Data(:,2);
        rfData.freq2.h2.sea.run2.rssiTs.Data(:,2)];
    rfData.freq2.h2.sea.allRssiRxTxData =...
        mean([rfData.freq2.h2.sea.allRssiRxData,rfData.freq2.h2.sea.allRssiTxData],2);
    
    % 2GHz, 5m, land
    rfData.freq2.h5.land.allDistData = [...
        rfData.freq2.h5.land.run1.distTs.Data;
        rfData.freq2.h5.land.run2.distTs.Data];
    rfData.freq2.h5.land.allRssiRxData = [...
        rfData.freq2.h5.land.run1.rssiTs.Data(:,1);
        rfData.freq2.h5.land.run2.rssiTs.Data(:,1)];
    rfData.freq2.h5.land.allRssiTxData = [...
        rfData.freq2.h5.land.run1.rssiTs.Data(:,2);
        rfData.freq2.h5.land.run2.rssiTs.Data(:,2)];
    rfData.freq2.h5.land.allRssiRxTxData =...
        mean([rfData.freq2.h5.land.allRssiRxData,rfData.freq2.h5.land.allRssiTxData],2);    
    
    % 2GHz, 5m, sea
    rfData.freq2.h5.sea.allDistData = [...
        rfData.freq2.h5.sea.run1.distTs.Data;
        rfData.freq2.h5.sea.run2.distTs.Data];
    rfData.freq2.h5.sea.allRssiRxData = [...
        rfData.freq2.h5.sea.run1.rssiTs.Data(:,1);
        rfData.freq2.h5.sea.run2.rssiTs.Data(:,1)];
    rfData.freq2.h5.sea.allRssiTxData = [...
        rfData.freq2.h5.sea.run1.rssiTs.Data(:,2);
        rfData.freq2.h5.sea.run2.rssiTs.Data(:,2)];
    rfData.freq2.h5.sea.allRssiRxTxData =...
        mean([rfData.freq2.h5.sea.allRssiRxData,rfData.freq2.h5.sea.allRssiTxData],2);
    
    % 5GHz, 2m, land
    rfData.freq5.h2.land.allDistData = [...
        rfData.freq5.h2.land.run1.distTs.Data;
        rfData.freq5.h2.land.run2.distTs.Data;
        rfData.freq5.h2.land.run3.distTs.Data];
    rfData.freq5.h2.land.allRssiRxData = [...
        rfData.freq5.h2.land.run1.rssiTs.Data(:,1);
        rfData.freq5.h2.land.run2.rssiTs.Data(:,1);
        rfData.freq5.h2.land.run3.rssiTs.Data(:,1)];
    rfData.freq5.h2.land.allRssiTxData = [...
        rfData.freq5.h2.land.run1.rssiTs.Data(:,2);
        rfData.freq5.h2.land.run2.rssiTs.Data(:,2);
        rfData.freq5.h2.land.run3.rssiTs.Data(:,2)];
    rfData.freq5.h2.land.allRssiRxTxData =...
        mean([rfData.freq5.h2.land.allRssiRxData,rfData.freq5.h2.land.allRssiTxData],2);
    
    % 5GHz, 2m, sea
    rfData.freq5.h2.sea.allDistData = [...
        rfData.freq5.h2.sea.run1.distTs.Data;
        rfData.freq5.h2.sea.run2.distTs.Data];
    rfData.freq5.h2.sea.allRssiRxData = [...
        rfData.freq5.h2.sea.run1.rssiTs.Data(:,1);
        rfData.freq5.h2.sea.run2.rssiTs.Data(:,1)];
    rfData.freq5.h2.sea.allRssiTxData = [...
        rfData.freq5.h2.sea.run1.rssiTs.Data(:,2);
        rfData.freq5.h2.sea.run2.rssiTs.Data(:,2)];
    rfData.freq5.h2.sea.allRssiRxTxData =...
        mean([rfData.freq5.h2.sea.allRssiRxData,rfData.freq5.h2.sea.allRssiTxData],2);
    
    % 5GHz, 5m, land
    rfData.freq5.h5.land.allDistData = [...
        rfData.freq5.h5.land.run1.distTs.Data;
        rfData.freq5.h5.land.run2.distTs.Data];
    rfData.freq5.h5.land.allRssiRxData = [...
        rfData.freq5.h5.land.run1.rssiTs.Data(:,1);
        rfData.freq5.h5.land.run2.rssiTs.Data(:,1)];
    rfData.freq5.h5.land.allRssiTxData = [...
        rfData.freq5.h5.land.run1.rssiTs.Data(:,2);
        rfData.freq5.h5.land.run2.rssiTs.Data(:,2)];
    rfData.freq5.h5.land.allRssiRxTxData =...
        mean([rfData.freq5.h5.land.allRssiRxData,rfData.freq5.h5.land.allRssiTxData],2);
    
    % 5GHz, 5m, sea
    rfData.freq5.h5.sea.allDistData = [...
        rfData.freq5.h5.sea.run1.distTs.Data;
        rfData.freq5.h5.sea.run2.distTs.Data];
    rfData.freq5.h5.sea.allRssiRxData = [...
        rfData.freq5.h5.sea.run1.rssiTs.Data(:,1);
        rfData.freq5.h5.sea.run2.rssiTs.Data(:,1)];
    rfData.freq5.h5.sea.allRssiTxData = [...
        rfData.freq5.h5.sea.run1.rssiTs.Data(:,2);
        rfData.freq5.h5.sea.run2.rssiTs.Data(:,2)];
    rfData.freq5.h5.sea.allRssiRxTxData =...
        mean([rfData.freq5.h5.sea.allRssiRxData,rfData.freq5.h5.sea.allRssiTxData],2);
        
end

function plotRxTx(rfData,figNum)

    % Create new figure
    figure(figNum);
    
    % Plot variables
    xMin = 0;
    xMax = 550;
    yMin = -100;
    yMax = -20;
    titleFontSize = 24;
    defaultFontSize = 22;
    
    % 2GHz, 2m, land
    f2h2l = subplot(2,4,1);
    hold on;
    plot(rfData.freq2.h2.land.allDistData,...
        rfData.freq2.h2.land.allRssiRxTxData,...
        'Color',[0 1 0],'LineStyle','None','Marker','x','MarkerSize',5);    
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 2 m, Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 2m, sea
    f2h2s = subplot(2,4,5);
    hold on;
    plot(rfData.freq2.h2.sea.allDistData,...
        rfData.freq2.h2.sea.allRssiRxTxData,...
        'Color',[0 0 1],'LineStyle','None','Marker','x','MarkerSize',5);  
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 2 m, Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 5m, land
    f2h5l = subplot(2,4,2);
    hold on;
    plot(rfData.freq2.h5.land.allDistData,...
        rfData.freq2.h5.land.allRssiRxTxData,...
        'Color',[0 1 0],'LineStyle','None','Marker','x','MarkerSize',5);  
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 5 m, Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 5m, sea
    f2h5s = subplot(2,4,6);
    hold on;
    plot(rfData.freq2.h5.sea.allDistData,...
        rfData.freq2.h5.sea.allRssiRxTxData,...
        'Color',[0 0 1],'LineStyle','None','Marker','x','MarkerSize',5);  
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 5 m, Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 2m, land
    f5h2l = subplot(2,4,3);
    hold on;
    plot(rfData.freq5.h2.land.allDistData,...
        rfData.freq5.h2.land.allRssiRxTxData,...
        'Color',[0 1 0],'LineStyle','None','Marker','x','MarkerSize',5);  
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 2 m, Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 2m, sea
    f5h2s = subplot(2,4,7);
    hold on;
    plot(rfData.freq5.h2.sea.allDistData,...
        rfData.freq5.h2.sea.allRssiRxTxData,...
        'Color',[0 0 1],'LineStyle','None','Marker','x','MarkerSize',5);  
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 2 m, Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 5m, land
    f5h5l = subplot(2,4,4);
    hold on;
    plot(rfData.freq5.h5.land.allDistData,...
        rfData.freq5.h5.land.allRssiRxTxData,...
        'Color',[0 1 0],'LineStyle','None','Marker','x','MarkerSize',5); 
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 5 m, Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 5m, sea
    f5h5s = subplot(2,4,8);
    hold on;
    plot(rfData.freq5.h5.sea.allDistData,...
        rfData.freq5.h5.sea.allRssiRxTxData,...
        'Color',[0 0 1],'LineStyle','None','Marker','x','MarkerSize',5);  
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 5 m, Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % Link axes
    linkaxes([f2h2l,f2h2s,f2h5l,f2h5s,f5h2l,f5h2s,f5h5l,f5h5s],'x');
    linkaxes([f2h2l,f2h2s,f2h5l,f2h5s,f5h2l,f5h2s,f5h5l,f5h5s],'y');

end

function rfData = binStatistics(rfData)
    
    % Binning values
    maxDist = 550;              % maximum distance for bin generation [m] (make larger than the largeset measured distance)
    binSize = 2.5;                % the bin to average over [m]
    bins = 0:binSize:maxDist;   % distance bin vector
    
    % 2GHz, 2m, land    
    binnedDist = discretize(rfData.freq2.h2.land.allDistData,bins);
    [rfData.freq2.h2.land.rssiMean,rfData.freq2.h2.land.rssiSigma,...
        rfData.freq2.h2.land.rssiConf95] = meanConfBin(bins,...
        binnedDist,rfData.freq2.h2.land.allRssiRxTxData);
    
    % 2GHz, 2m, sea
    binnedDist = discretize(rfData.freq2.h2.sea.allDistData,bins);
    [rfData.freq2.h2.sea.rssiMean,rfData.freq2.h2.sea.rssiSigma,...
        rfData.freq2.h2.sea.rssiConf95] = meanConfBin(bins,...
        binnedDist,rfData.freq2.h2.sea.allRssiRxTxData);
    
    % 2GHz, 5m, land
    binnedDist = discretize(rfData.freq2.h5.land.allDistData,bins);
    [rfData.freq2.h5.land.rssiMean,rfData.freq2.h5.land.rssiSigma,...
        rfData.freq2.h5.land.rssiConf95] = meanConfBin(bins,...
        binnedDist,rfData.freq2.h5.land.allRssiRxTxData);
    
    % 2GHz, 5m, sea
    binnedDist = discretize(rfData.freq2.h5.sea.allDistData,bins);
    [rfData.freq2.h5.sea.rssiMean,rfData.freq2.h5.sea.rssiSigma,...
        rfData.freq2.h5.sea.rssiConf95] = meanConfBin(bins,...
        binnedDist,rfData.freq2.h5.sea.allRssiRxTxData);
    
    % 5GHz, 2m, land    
    binnedDist = discretize(rfData.freq5.h2.land.allDistData,bins);
    [rfData.freq5.h2.land.rssiMean,rfData.freq5.h2.land.rssiSigma,...
        rfData.freq5.h2.land.rssiConf95] = meanConfBin(bins,...
        binnedDist,rfData.freq5.h2.land.allRssiRxTxData);
    
    % 5GHz, 2m, sea
    binnedDist = discretize(rfData.freq5.h2.sea.allDistData,bins);
    [rfData.freq5.h2.sea.rssiMean,rfData.freq5.h2.sea.rssiSigma,...
        rfData.freq5.h2.sea.rssiConf95] = meanConfBin(bins,...
        binnedDist,rfData.freq5.h2.sea.allRssiRxTxData);
    
    % 5GHz, 5m, land
    binnedDist = discretize(rfData.freq5.h5.land.allDistData,bins);
    [rfData.freq5.h5.land.rssiMean,rfData.freq5.h5.land.rssiSigma,...
        rfData.freq5.h5.land.rssiConf95] = meanConfBin(bins,...
        binnedDist,rfData.freq5.h5.land.allRssiRxTxData);
    
    % 5GHz, 5m, sea
    binnedDist = discretize(rfData.freq5.h5.sea.allDistData,bins);
    [rfData.freq5.h5.sea.rssiMean,rfData.freq5.h5.sea.rssiSigma,...
        rfData.freq5.h5.sea.rssiConf95] = meanConfBin(bins,...
        binnedDist,rfData.freq5.h5.sea.allRssiRxTxData); 

    % Save bin vector to output strcture
    rfData.bins = bins';
    
    % Display statistics information
    disp(' ');
    disp(['Mean standard deviation of 2GHz, 2m, land = ',num2str(mean(rmmissing(rfData.freq2.h2.land.rssiSigma)))]);
    disp(['Mean standard deviation of 2GHz, 2m, sea = ',num2str(mean(rmmissing(rfData.freq2.h2.sea.rssiSigma)))]);
    disp(['Mean standard deviation of 2GHz, 5m, land = ',num2str(mean(rmmissing(rfData.freq2.h5.land.rssiSigma)))]);
    disp(['Mean standard deviation of 2GHz, 5m, sea = ',num2str(mean(rmmissing(rfData.freq2.h5.sea.rssiSigma)))]);
    disp(['Mean standard deviation of 5GHz, 2m, land = ',num2str(mean(rmmissing(rfData.freq5.h2.land.rssiSigma)))]);
    disp(['Mean standard deviation of 5GHz, 2m, sea = ',num2str(mean(rmmissing(rfData.freq5.h2.sea.rssiSigma)))]);
    disp(['Mean standard deviation of 5GHz, 5m, land = ',num2str(mean(rmmissing(rfData.freq5.h5.land.rssiSigma)))]);
    disp(['Mean standard deviation of 5GHz, 5m, sea = ',num2str(mean(rmmissing(rfData.freq5.h5.sea.rssiSigma)))]);
    disp(' ');
    disp(['Mean confidence interval of 2GHz, 2m, land = ',num2str(mean(rmmissing(rfData.freq2.h2.land.rssiConf95)))]);
    disp(['Mean confidence interval of 2GHz, 2m, sea = ',num2str(mean(rmmissing(rfData.freq2.h2.sea.rssiConf95)))]);
    disp(['Mean confidence interval of 2GHz, 5m, land = ',num2str(mean(rmmissing(rfData.freq2.h5.land.rssiConf95)))]);
    disp(['Mean confidence interval of 2GHz, 5m, sea = ',num2str(mean(rmmissing(rfData.freq2.h5.sea.rssiConf95)))]);
    disp(['Mean confidence interval of 5GHz, 2m, land = ',num2str(mean(rmmissing(rfData.freq5.h2.land.rssiConf95)))]);
    disp(['Mean confidence interval of 5GHz, 2m, sea = ',num2str(mean(rmmissing(rfData.freq5.h2.sea.rssiConf95)))]);
    disp(['Mean confidence interval of 5GHz, 5m, land = ',num2str(mean(rmmissing(rfData.freq5.h5.land.rssiConf95)))]);
    disp(['Mean confidence interval of 5GHz, 5m, sea = ',num2str(mean(rmmissing(rfData.freq5.h5.sea.rssiConf95)))]);
        
end

function [meanVec,sigmaVec,conf95Vec] = meanConfBin(bins,binnedDist,rssiData)

    % Set verbose to true to debug
    verbose = false;

    % Preallocate output vectors
    nBins = length(bins)-1;     % number of bins; this is one less than the length of the bins vector
    meanVec = zeros(nBins,1);
    sigmaVec = zeros(nBins,1);
    conf95Vec = zeros(nBins,1);

    for i = 1:1:nBins
        
        % Determine which data points occured in this bin
        binData = rssiData(binnedDist == i);    % data points in this bin
        
        % Calculate statistics
        N = length(binData);                % number of data points
        ave = mean(binData);                % mean of data points
        sigma = std(binData);               % standard deviation of data points
        conf95 = 1.96.*(sigma)./(sqrt(N));  % 95% confidence interval
        
        % Save to output vectors
        meanVec(i,1) = ave;
        sigmaVec(i,1) = sigma;
        conf95Vec(i,1) = conf95;
        
        if verbose == true
        
            % Print debug info
            disp(['In bin ',num2str(i),', (range ',num2str(bins(i)),' to ',num2str(bins(i+1)),' m), the RSSI was:']);
            disp(['mean = ',num2str(ave),'; sigma = ',num2str(sigma),'; 95% CI = ',num2str(conf95),'; N = ',num2str(N)]);
            disp(' ');
            
        end
        
    end
    
end

function plotBins(rfData,figNum)

    % Create new figure
    figure(figNum);
    
    % Plot variables
    xMin = 0;
    xMax = 550;
    yMin = -100;
    yMax = -20;
    titleFontSize = 22;
    defaultFontSize = 20;
    
    % 2GHz, 2m, land
    f2h2l = subplot(2,4,1);
    hold on;
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq2.h2.land.rssiMean,...
        'Color',[0 1 0],'LineWidth',1.75);
    sigmaY = [rfData.freq2.h2.land.rssiMean-...
        rfData.freq2.h2.land.rssiSigma,...
        rfData.freq2.h2.land.rssiSigma.*2];
    sigmaPlot = area(rfData.bins(1:end-1,1),sigmaY);
    sigmaPlot(1).FaceColor = 'k';
    sigmaPlot(1).FaceAlpha = 0;
    sigmaPlot(1).LineStyle = 'none';
    set(get(get(sigmaPlot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    sigmaPlot(2).FaceColor = 'm';
    sigmaPlot(2).FaceAlpha = 0.25;
    sigmaPlot(2).LineStyle = 'none';
    conf95Y = [rfData.freq2.h2.land.rssiMean-...
        rfData.freq2.h2.land.rssiConf95,...
        rfData.freq2.h2.land.rssiConf95.*2];
    conf95Plot = area(rfData.bins(1:end-1,1),conf95Y);
    conf95Plot(1).FaceColor = 'k';
    conf95Plot(1).FaceAlpha = 0;
    conf95Plot(1).LineStyle = 'none';
    set(get(get(conf95Plot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    conf95Plot(2).FaceColor = 'c';
    conf95Plot(2).FaceAlpha = 0.25;
    conf95Plot(2).LineStyle = 'none';
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq2.h2.land.rssiMean,...
        'Color',[0 1 0],'LineWidth',1.75);
    set(get(get(meanPlot,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('mean RSSI over land','+/-\sigma','+/-95% confidence interval');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 2 m, Over Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 2m, sea
    f2h2s = subplot(2,4,5);
    hold on;
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq2.h2.sea.rssiMean,...
        'Color',[0 0 1],'LineWidth',1.75);
    sigmaY = [rfData.freq2.h2.sea.rssiMean-...
        rfData.freq2.h2.sea.rssiSigma,...
        rfData.freq2.h2.sea.rssiSigma.*2];
    sigmaPlot = area(rfData.bins(1:end-1,1),sigmaY);
    sigmaPlot(1).FaceColor = 'k';
    sigmaPlot(1).FaceAlpha = 0;
    sigmaPlot(1).LineStyle = 'none';
    set(get(get(sigmaPlot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    sigmaPlot(2).FaceColor = 'm';
    sigmaPlot(2).FaceAlpha = 0.25;
    sigmaPlot(2).LineStyle = 'none';
    conf95Y = [rfData.freq2.h2.sea.rssiMean-...
        rfData.freq2.h2.sea.rssiConf95,...
        rfData.freq2.h2.sea.rssiConf95.*2];
    conf95Plot = area(rfData.bins(1:end-1,1),conf95Y);
    conf95Plot(1).FaceColor = 'k';
    conf95Plot(1).FaceAlpha = 0;
    conf95Plot(1).LineStyle = 'none';
    set(get(get(conf95Plot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    conf95Plot(2).FaceColor = 'c';
    conf95Plot(2).FaceAlpha = 0.25;
    conf95Plot(2).LineStyle = 'none';
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq2.h2.sea.rssiMean,...
        'Color',[0 0 1],'LineWidth',1.75);
    set(get(get(meanPlot,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('mean RSSI over sea','+/-\sigma','+/-95% confidence interval');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 2 m, Over Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
        
    % 2GHz, 5m, land
    f2h5l = subplot(2,4,2);
    hold on;
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq2.h5.land.rssiMean,...
        'Color',[0 1 0],'LineWidth',1.75);
    sigmaY = [rfData.freq2.h5.land.rssiMean-...
        rfData.freq2.h5.land.rssiSigma,...
        rfData.freq2.h5.land.rssiSigma.*2];
    sigmaPlot = area(rfData.bins(1:end-1,1),sigmaY);
    sigmaPlot(1).FaceColor = 'k';
    sigmaPlot(1).FaceAlpha = 0;
    sigmaPlot(1).LineStyle = 'none';
    set(get(get(sigmaPlot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    sigmaPlot(2).FaceColor = 'm';
    sigmaPlot(2).FaceAlpha = 0.25;
    sigmaPlot(2).LineStyle = 'none';
    conf95Y = [rfData.freq2.h5.land.rssiMean-...
        rfData.freq2.h5.land.rssiConf95,...
        rfData.freq2.h5.land.rssiConf95.*2];
    conf95Plot = area(rfData.bins(1:end-1,1),conf95Y);
    conf95Plot(1).FaceColor = 'k';
    conf95Plot(1).FaceAlpha = 0;
    conf95Plot(1).LineStyle = 'none';
    set(get(get(conf95Plot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    conf95Plot(2).FaceColor = 'c';
    conf95Plot(2).FaceAlpha = 0.25;
    conf95Plot(2).LineStyle = 'none';
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq2.h5.land.rssiMean,...
        'Color',[0 1 0],'LineWidth',1.75);
    set(get(get(meanPlot,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 5 m, Over Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 5m, sea
    f2h5s = subplot(2,4,6);
    hold on;
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq2.h5.sea.rssiMean,...
        'Color',[0 0 1],'LineWidth',1.75);
    sigmaY = [rfData.freq2.h5.sea.rssiMean-...
        rfData.freq2.h5.sea.rssiSigma,...
        rfData.freq2.h5.sea.rssiSigma.*2];
    sigmaPlot = area(rfData.bins(1:end-1,1),sigmaY);
    sigmaPlot(1).FaceColor = 'k';
    sigmaPlot(1).FaceAlpha = 0;
    sigmaPlot(1).LineStyle = 'none';
    set(get(get(sigmaPlot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    sigmaPlot(2).FaceColor = 'm';
    sigmaPlot(2).FaceAlpha = 0.25;
    sigmaPlot(2).LineStyle = 'none';
    conf95Y = [rfData.freq2.h5.sea.rssiMean-...
        rfData.freq2.h5.sea.rssiConf95,...
        rfData.freq2.h5.sea.rssiConf95.*2];
    conf95Plot = area(rfData.bins(1:end-1,1),conf95Y);
    conf95Plot(1).FaceColor = 'k';
    conf95Plot(1).FaceAlpha = 0;
    conf95Plot(1).LineStyle = 'none';
    set(get(get(conf95Plot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    conf95Plot(2).FaceColor = 'c';
    conf95Plot(2).FaceAlpha = 0.25;
    conf95Plot(2).LineStyle = 'none';
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq2.h5.sea.rssiMean,...
        'Color',[0 0 1],'LineWidth',1.75);
    set(get(get(meanPlot,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 5 m, Over Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 2m, land
    f5h2l = subplot(2,4,3);
    hold on;
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq5.h2.land.rssiMean,...
        'Color',[0 1 0],'LineWidth',1.75);
    sigmaY = [rfData.freq5.h2.land.rssiMean-...
        rfData.freq5.h2.land.rssiSigma,...
        rfData.freq5.h2.land.rssiSigma.*2];
    sigmaPlot = area(rfData.bins(1:end-1,1),sigmaY);
    sigmaPlot(1).FaceColor = 'k';
    sigmaPlot(1).FaceAlpha = 0;
    sigmaPlot(1).LineStyle = 'none';
    set(get(get(sigmaPlot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    sigmaPlot(2).FaceColor = 'm';
    sigmaPlot(2).FaceAlpha = 0.25;
    sigmaPlot(2).LineStyle = 'none';
    conf95Y = [rfData.freq5.h2.land.rssiMean-...
        rfData.freq5.h2.land.rssiConf95,...
        rfData.freq5.h2.land.rssiConf95.*2];
    conf95Plot = area(rfData.bins(1:end-1,1),conf95Y);
    conf95Plot(1).FaceColor = 'k';
    conf95Plot(1).FaceAlpha = 0;
    conf95Plot(1).LineStyle = 'none';
    set(get(get(conf95Plot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    conf95Plot(2).FaceColor = 'c';
    conf95Plot(2).FaceAlpha = 0.25;
    conf95Plot(2).LineStyle = 'none';
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq5.h2.land.rssiMean,...
        'Color',[0 1 0],'LineWidth',1.75);
    set(get(get(meanPlot,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 2 m, Over Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 2m, sea
    f5h2s = subplot(2,4,7);
    hold on;
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq5.h2.sea.rssiMean,...
        'Color',[0 0 1],'LineWidth',1.75);
    sigmaY = [rfData.freq5.h2.sea.rssiMean-...
        rfData.freq5.h2.sea.rssiSigma,...
        rfData.freq5.h2.sea.rssiSigma.*2];
    sigmaPlot = area(rfData.bins(1:end-1,1),sigmaY);
    sigmaPlot(1).FaceColor = 'k';
    sigmaPlot(1).FaceAlpha = 0;
    sigmaPlot(1).LineStyle = 'none';
    set(get(get(sigmaPlot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    sigmaPlot(2).FaceColor = 'm';
    sigmaPlot(2).FaceAlpha = 0.25;
    sigmaPlot(2).LineStyle = 'none';
    conf95Y = [rfData.freq5.h2.sea.rssiMean-...
        rfData.freq5.h2.sea.rssiConf95,...
        rfData.freq5.h2.sea.rssiConf95.*2];
    conf95Plot = area(rfData.bins(1:end-1,1),conf95Y);
    conf95Plot(1).FaceColor = 'k';
    conf95Plot(1).FaceAlpha = 0;
    conf95Plot(1).LineStyle = 'none';
    set(get(get(conf95Plot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    conf95Plot(2).FaceColor = 'c';
    conf95Plot(2).FaceAlpha = 0.25;
    conf95Plot(2).LineStyle = 'none';
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq5.h2.sea.rssiMean,...
        'Color',[0 0 1],'LineWidth',1.75);
    set(get(get(meanPlot,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 2 m, Over Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 5m, land
    f5h5l = subplot(2,4,4);
    hold on;
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq5.h5.land.rssiMean,...
        'Color',[0 1 0],'LineWidth',1.75);
    sigmaY = [rfData.freq5.h5.land.rssiMean-...
        rfData.freq5.h5.land.rssiSigma,...
        rfData.freq5.h5.land.rssiSigma.*2];
    sigmaPlot = area(rfData.bins(1:end-1,1),sigmaY);
    sigmaPlot(1).FaceColor = 'k';
    sigmaPlot(1).FaceAlpha = 0;
    sigmaPlot(1).LineStyle = 'none';
    set(get(get(sigmaPlot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    sigmaPlot(2).FaceColor = 'm';
    sigmaPlot(2).FaceAlpha = 0.25;
    sigmaPlot(2).LineStyle = 'none';
    conf95Y = [rfData.freq5.h5.land.rssiMean-...
        rfData.freq5.h5.land.rssiConf95,...
        rfData.freq5.h5.land.rssiConf95.*2];
    conf95Plot = area(rfData.bins(1:end-1,1),conf95Y);
    conf95Plot(1).FaceColor = 'k';
    conf95Plot(1).FaceAlpha = 0;
    conf95Plot(1).LineStyle = 'none';
    set(get(get(conf95Plot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    conf95Plot(2).FaceColor = 'c';
    conf95Plot(2).FaceAlpha = 0.25;
    conf95Plot(2).LineStyle = 'none';
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq5.h5.land.rssiMean,...
        'Color',[0 1 0],'LineWidth',1.75);
    set(get(get(meanPlot,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 5 m, Over Land','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 5m, sea
    f5h5s = subplot(2,4,8);
    hold on;
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq5.h5.sea.rssiMean,...
        'Color',[0 0 1],'LineWidth',1.75);
    sigmaY = [rfData.freq5.h5.sea.rssiMean-...
        rfData.freq5.h5.sea.rssiSigma,...
        rfData.freq5.h5.sea.rssiSigma.*2];
    sigmaPlot = area(rfData.bins(1:end-1,1),sigmaY);
    sigmaPlot(1).FaceColor = 'k';
    sigmaPlot(1).FaceAlpha = 0;
    sigmaPlot(1).LineStyle = 'none';
    set(get(get(sigmaPlot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    sigmaPlot(2).FaceColor = 'm';
    sigmaPlot(2).FaceAlpha = 0.25;
    sigmaPlot(2).LineStyle = 'none';
    conf95Y = [rfData.freq5.h5.sea.rssiMean-...
        rfData.freq5.h5.sea.rssiConf95,...
        rfData.freq5.h5.sea.rssiConf95.*2];
    conf95Plot = area(rfData.bins(1:end-1,1),conf95Y);
    conf95Plot(1).FaceColor = 'k';
    conf95Plot(1).FaceAlpha = 0;
    conf95Plot(1).LineStyle = 'none';
    set(get(get(conf95Plot(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    conf95Plot(2).FaceColor = 'c';
    conf95Plot(2).FaceAlpha = 0.25;
    conf95Plot(2).LineStyle = 'none';
    meanPlot = plot(rfData.bins(1:end-1,1),rfData.freq5.h5.sea.rssiMean,...
        'Color',[0 0 1],'LineWidth',1.75);
    set(get(get(meanPlot,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 5 m, Over Sea','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % Link axes
    linkaxes([f2h2l,f2h2s,f2h5l,f2h5s,f5h2l,f5h2s,f5h5l,f5h5s],'x');
    linkaxes([f2h2l,f2h2s,f2h5l,f2h5s,f5h2l,f5h2s,f5h5l,f5h5s],'y');
    
end

function rfModel = lossModels(rfData)
    
    % Distance vectors
    rfModel.dd = linspace(0,500,50000);   % analytical model distance vector [m]
    
    % Phyiscal consatnts
    R = -1;                         % ideal reflection coefficient [ ]
    
    % Two ray ground reflection model (full model)
    rfModel.trgr.f2h2 = 20.*log10(rfData.lambda2./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10))./(sqrt(rfModel.dd.^2+(rfData.hTx2-rfData.hRx).^2)))+(R.*(sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx2+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx2-rfData.hRx).^2))))./rfData.lambda2)))./(sqrt(rfModel.dd.^2+(rfData.hTx2+rfData.hRx).^2)))))+rfData.p2;
    rfModel.trgr.f2h5 = 20.*log10(rfData.lambda2./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10))./(sqrt(rfModel.dd.^2+(rfData.hTx5-rfData.hRx).^2)))+(R.*(sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx5+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx5-rfData.hRx).^2))))./rfData.lambda2)))./(sqrt(rfModel.dd.^2+(rfData.hTx5+rfData.hRx).^2)))))+rfData.p2;
    rfModel.trgr.f5h2 = 20.*log10(rfData.lambda5./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10))./(sqrt(rfModel.dd.^2+(rfData.hTx2-rfData.hRx).^2)))+(R.*(sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx2+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx2-rfData.hRx).^2))))./rfData.lambda5)))./(sqrt(rfModel.dd.^2+(rfData.hTx2+rfData.hRx).^2)))))+rfData.p5;
    rfModel.trgr.f5h5 = 20.*log10(rfData.lambda5./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10))./(sqrt(rfModel.dd.^2+(rfData.hTx5-rfData.hRx).^2)))+(R.*(sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx5+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx5-rfData.hRx).^2))))./rfData.lambda5)))./(sqrt(rfModel.dd.^2+(rfData.hTx5+rfData.hRx).^2)))))+rfData.p5;
    
    % Two-ray ground reflection region two aproximation model (also free space path loss model)
    rfModel.trgrR2.f2h2 = rfData.p2-(-10*log10((10^(rfData.g2/10))*(10^(rfData.g2/10))*(rfData.lambda2./(4*pi*rfModel.dd)).^2));
    rfModel.trgrR2.f2h5 = rfData.p2-(-10*log10((10^(rfData.g2/10))*(10^(rfData.g2/10))*(rfData.lambda2./(4*pi*rfModel.dd)).^2));
    rfModel.trgrR2.f5h2 = rfData.p5-(-10*log10((10^(rfData.g5/10))*(10^(rfData.g5/10))*(rfData.lambda5./(4*pi*rfModel.dd)).^2));
    rfModel.trgrR2.f5h5 = rfData.p5-(-10*log10((10^(rfData.g5/10))*(10^(rfData.g5/10))*(rfData.lambda5./(4*pi*rfModel.dd)).^2));
    
    % Two ray ground reflection region three approximation model
    rfModel.trgrR3.f2h2 = rfData.p2+rfData.g2+rfData.g2-40*log10(rfModel.dd)+20*log10(rfData.hTx2)+20*log10(rfData.hRx);
    rfModel.trgrR3.f2h5 = rfData.p2+rfData.g2+rfData.g2-40*log10(rfModel.dd)+20*log10(rfData.hTx5)+20*log10(rfData.hRx);
    rfModel.trgrR3.f5h2 = rfData.p5+rfData.g5+rfData.g5-40*log10(rfModel.dd)+20*log10(rfData.hTx2)+20*log10(rfData.hRx);
    rfModel.trgrR3.f5h5 = rfData.p5+rfData.g5+rfData.g5-40*log10(rfModel.dd)+20*log10(rfData.hTx5)+20*log10(rfData.hRx);    
    
    % Crossover distance
    rfModel.dc.f2h2 = (4*pi*rfData.hTx2*rfData.hRx)/(rfData.lambda2);
    rfModel.dc.f2h5 = (4*pi*rfData.hTx5*rfData.hRx)/(rfData.lambda2);
    rfModel.dc.f5h2 = (4*pi*rfData.hTx2*rfData.hRx)/(rfData.lambda5);
    rfModel.dc.f5h5 = (4*pi*rfData.hTx5*rfData.hRx)/(rfData.lambda5);

end

function plotLossModels(rfData,rfModel,figNum)

    % Create new figure
    figure(figNum);
    
    % Plot variables
    xMin = 0;
    xMax = 550;
    yMin = -120;
    yMax = 0;
    titleFontSize = 24;
    defaultFontSize = 22;
    
    % 2GHz, 2m, land + sea
    f2h2 = subplot(2,2,1);
    hold on;
    plot(rfData.freq2.h2.land.allDistData,...
        rfData.freq2.h2.land.allRssiRxTxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq2.h2.sea.allDistData,...
        rfData.freq2.h2.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgr.f2h2,'c',...
        'LineStyle','-.','LineWidth',2,'Marker','none');
    plot(rfModel.dd,rfModel.trgrR2.f2h2,'m',...
        'LineStyle','--','LineWidth',2,'Marker','none');
    plot(rfModel.dd,rfModel.trgrR3.f2h2,'r:',...
        'LineStyle',':','LineWidth',2,'Marker','none');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('land RSSI data',...
        'sea RSSI data',...
        'P_r, full two-ray',...
        'P_r, apprx. two-ray reg. 2 (h_t < d <d_c)',...
        'P_r, apprx. two-ray reg. 3 (d > d_c)');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 2 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 5m, land + sea
    f2h5 = subplot(2,2,3);
    hold on;
    plot(rfData.freq2.h5.land.allDistData,...
        rfData.freq2.h5.land.allRssiRxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq2.h5.sea.allDistData,...
        rfData.freq2.h5.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgr.f2h5,'c',...
        'LineStyle','-.','LineWidth',2,'Marker','none');
    plot(rfModel.dd,rfModel.trgrR2.f2h5,'m',...
        'LineStyle','--','LineWidth',2,'Marker','none');
    plot(rfModel.dd,rfModel.trgrR3.f2h5,'r:',...
        'LineStyle',':','LineWidth',2,'Marker','none');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 2m, land + sea
    f5h2 = subplot(2,2,2);
    hold on;
    plot(rfData.freq5.h2.land.allDistData,...
        rfData.freq5.h2.land.allRssiRxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq5.h2.sea.allDistData,...
        rfData.freq5.h2.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgr.f2h5,'c',...
        'LineStyle','-.','LineWidth',2,'Marker','none');
    plot(rfModel.dd,rfModel.trgrR2.f2h5,'m',...
        'LineStyle','--','LineWidth',2,'Marker','none');
    plot(rfModel.dd,rfModel.trgrR3.f5h2,'r:',...
        'LineStyle',':','LineWidth',2,'Marker','none');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 2 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 5m, land + sea
    f5h5 = subplot(2,2,4);
    hold on;
    plot(rfData.freq5.h5.land.allDistData,...
        rfData.freq5.h5.land.allRssiRxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq5.h5.sea.allDistData,...
        rfData.freq5.h5.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgr.f5h5,'c',...
        'LineStyle','-.','LineWidth',2,'Marker','none');
    plot(rfModel.dd,rfModel.trgrR2.f5h5,'m',...
        'LineStyle','--','LineWidth',2,'Marker','none');
    plot(rfModel.dd,rfModel.trgrR3.f5h5,'r:',...
        'LineStyle',':','LineWidth',2,'Marker','none');
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % Link axes
    linkaxes([f2h2,f2h5,f5h2,f5h5],'x');
    linkaxes([f2h2,f2h5,f5h2,f5h5],'y');

end

function rfData = removeOutsideCrossoverDistance(rfData,rfModel)

    disp(' ');
    disp(['2GHz, 2m crossover distance: ',num2str(rfModel.dc.f2h2)]);
    disp(['2GHz, 2m crossover distance: ',num2str(rfModel.dc.f2h5)]);
    disp(['2GHz, 2m crossover distance: ',num2str(rfModel.dc.f5h2)]);
    disp(['2GHz, 2m crossover distance: ',num2str(rfModel.dc.f5h5)]);

    % 2GHz, 2m, land
    maxDist = rfModel.dc.f2h2;
    [rfData.freq2.h2.land.run1.distTsR2Only,rfData.freq2.h2.land.run1.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq2.h2.land.run1.distTs,...
        rfData.freq2.h2.land.run1.rssiTs,maxDist);
    [rfData.freq2.h2.land.run2.distTsR2Only,rfData.freq2.h2.land.run2.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq2.h2.land.run2.distTs,...
        rfData.freq2.h2.land.run2.rssiTs,maxDist);
    rfData.freq2.h2.land.allDistDataR2Only = [...
        rfData.freq2.h2.land.run1.distTsR2Only.Data;
        rfData.freq2.h2.land.run2.distTsR2Only.Data];
    rfData.freq2.h2.land.allRssiRxDataR2Only = [...
        rfData.freq2.h2.land.run1.rssiTsR2Only.Data(:,1);
        rfData.freq2.h2.land.run2.rssiTsR2Only.Data(:,1)];
    rfData.freq2.h2.land.allRssiTxDataR2Only = [...
        rfData.freq2.h2.land.run1.rssiTsR2Only.Data(:,2);
        rfData.freq2.h2.land.run2.rssiTsR2Only.Data(:,2)];
    rfData.freq2.h2.land.allRssiRxTxDataR2Only =...
        mean([rfData.freq2.h2.land.allRssiRxDataR2Only,rfData.freq2.h2.land.allRssiTxDataR2Only],2);
    
    % 2GHz, 2m, sea
    maxDist = rfModel.dc.f2h2;
    [rfData.freq2.h2.sea.run1.distTsR2Only,rfData.freq2.h2.sea.run1.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq2.h2.sea.run1.distTs,...
        rfData.freq2.h2.sea.run1.rssiTs,maxDist);
    [rfData.freq2.h2.sea.run2.distTsR2Only,rfData.freq2.h2.sea.run2.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq2.h2.sea.run2.distTs,...
        rfData.freq2.h2.sea.run2.rssiTs,maxDist);
    rfData.freq2.h2.sea.allDistDataR2Only = [...
        rfData.freq2.h2.sea.run1.distTsR2Only.Data;
        rfData.freq2.h2.sea.run2.distTsR2Only.Data];
    rfData.freq2.h2.sea.allRssiRxDataR2Only = [...
        rfData.freq2.h2.sea.run1.rssiTsR2Only.Data(:,1);
        rfData.freq2.h2.sea.run2.rssiTsR2Only.Data(:,1)];
    rfData.freq2.h2.sea.allRssiTxDataR2Only = [...
        rfData.freq2.h2.sea.run1.rssiTsR2Only.Data(:,2);
        rfData.freq2.h2.sea.run2.rssiTsR2Only.Data(:,2)];
    rfData.freq2.h2.sea.allRssiRxTxDataR2Only =...
        mean([rfData.freq2.h2.sea.allRssiRxDataR2Only,rfData.freq2.h2.sea.allRssiTxDataR2Only],2);
    
    % 2GHz, 5m, land
    maxDist = rfModel.dc.f2h5;
    [rfData.freq2.h5.land.run1.distTsR2Only,rfData.freq2.h5.land.run1.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq2.h5.land.run1.distTs,...
        rfData.freq2.h5.land.run1.rssiTs,maxDist);
    [rfData.freq2.h5.land.run2.distTsR2Only,rfData.freq2.h5.land.run2.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq2.h5.land.run2.distTs,...
        rfData.freq2.h5.land.run2.rssiTs,maxDist);
    rfData.freq2.h5.land.allDistDataR2Only = [...
        rfData.freq2.h5.land.run1.distTsR2Only.Data;
        rfData.freq2.h5.land.run2.distTsR2Only.Data];
    rfData.freq2.h5.land.allRssiRxDataR2Only = [...
        rfData.freq2.h5.land.run1.rssiTsR2Only.Data(:,1);
        rfData.freq2.h5.land.run2.rssiTsR2Only.Data(:,1)];
    rfData.freq2.h5.land.allRssiTxDataR2Only = [...
        rfData.freq2.h5.land.run1.rssiTsR2Only.Data(:,2);
        rfData.freq2.h5.land.run2.rssiTsR2Only.Data(:,2)];
    rfData.freq2.h5.land.allRssiRxTxDataR2Only =...
        mean([rfData.freq2.h5.land.allRssiRxDataR2Only,rfData.freq2.h5.land.allRssiTxDataR2Only],2);    
    
    % 2GHz, 5m, sea
    maxDist = rfModel.dc.f2h5;
    [rfData.freq2.h5.sea.run1.distTsR2Only,rfData.freq2.h5.sea.run1.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq2.h5.sea.run1.distTs,...
        rfData.freq2.h5.sea.run1.rssiTs,maxDist);
    [rfData.freq2.h5.sea.run2.distTsR2Only,rfData.freq2.h5.sea.run2.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq2.h5.sea.run2.distTs,...
        rfData.freq2.h5.sea.run2.rssiTs,maxDist);
    rfData.freq2.h5.sea.allDistDataR2Only = [...
        rfData.freq2.h5.sea.run1.distTsR2Only.Data;
        rfData.freq2.h5.sea.run2.distTsR2Only.Data];
    rfData.freq2.h5.sea.allRssiRxDataR2Only = [...
        rfData.freq2.h5.sea.run1.rssiTsR2Only.Data(:,1);
        rfData.freq2.h5.sea.run2.rssiTsR2Only.Data(:,1)];
    rfData.freq2.h5.sea.allRssiTxDataR2Only = [...
        rfData.freq2.h5.sea.run1.rssiTsR2Only.Data(:,2);
        rfData.freq2.h5.sea.run2.rssiTsR2Only.Data(:,2)];
    rfData.freq2.h5.sea.allRssiRxTxDataR2Only =...
        mean([rfData.freq2.h5.sea.allRssiRxDataR2Only,rfData.freq2.h5.sea.allRssiTxDataR2Only],2);
    
    % 5GHz, 2m, land
    maxDist = rfModel.dc.f5h2;
    [rfData.freq5.h2.land.run1.distTsR2Only,rfData.freq5.h2.land.run1.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq5.h2.land.run1.distTs,...
        rfData.freq5.h2.land.run1.rssiTs,maxDist);
    [rfData.freq5.h2.land.run2.distTsR2Only,rfData.freq5.h2.land.run2.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq5.h2.land.run2.distTs,...
        rfData.freq5.h2.land.run2.rssiTs,maxDist);
    [rfData.freq5.h2.land.run3.distTsR2Only,rfData.freq5.h2.land.run3.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq5.h2.land.run3.distTs,...
        rfData.freq5.h2.land.run3.rssiTs,maxDist);
    rfData.freq5.h2.land.allDistDataR2Only = [...
        rfData.freq5.h2.land.run1.distTsR2Only.Data;
        rfData.freq5.h2.land.run2.distTsR2Only.Data;
        rfData.freq5.h2.land.run3.distTsR2Only.Data];
    rfData.freq5.h2.land.allRssiRxDataR2Only = [...
        rfData.freq5.h2.land.run1.rssiTsR2Only.Data(:,1);
        rfData.freq5.h2.land.run2.rssiTsR2Only.Data(:,1);
        rfData.freq5.h2.land.run3.rssiTsR2Only.Data(:,1)];
    rfData.freq5.h2.land.allRssiTxDataR2Only = [...
        rfData.freq5.h2.land.run1.rssiTsR2Only.Data(:,2);
        rfData.freq5.h2.land.run2.rssiTsR2Only.Data(:,2);
        rfData.freq5.h2.land.run3.rssiTsR2Only.Data(:,2)];
    rfData.freq5.h2.land.allRssiRxTxDataR2Only =...
        mean([rfData.freq5.h2.land.allRssiRxDataR2Only,rfData.freq5.h2.land.allRssiTxDataR2Only],2);
    
    % 5GHz, 2m, sea
    maxDist = rfModel.dc.f5h2;
    [rfData.freq5.h2.sea.run1.distTsR2Only,rfData.freq5.h2.sea.run1.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq5.h2.sea.run1.distTs,...
        rfData.freq5.h2.sea.run1.rssiTs,maxDist);
    [rfData.freq5.h2.sea.run2.distTsR2Only,rfData.freq5.h2.sea.run2.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq5.h2.sea.run2.distTs,...
        rfData.freq5.h2.sea.run2.rssiTs,maxDist);
    rfData.freq5.h2.sea.allDistDataR2Only = [...
        rfData.freq5.h2.sea.run1.distTsR2Only.Data;
        rfData.freq5.h2.sea.run2.distTsR2Only.Data];
    rfData.freq5.h2.sea.allRssiRxDataR2Only = [...
        rfData.freq5.h2.sea.run1.rssiTsR2Only.Data(:,1);
        rfData.freq5.h2.sea.run2.rssiTsR2Only.Data(:,1)];
    rfData.freq5.h2.sea.allRssiTxDataR2Only = [...
        rfData.freq5.h2.sea.run1.rssiTsR2Only.Data(:,2);
        rfData.freq5.h2.sea.run2.rssiTsR2Only.Data(:,2)];
    rfData.freq5.h2.sea.allRssiRxTxDataR2Only =...
        mean([rfData.freq5.h2.sea.allRssiRxDataR2Only,rfData.freq5.h2.sea.allRssiTxDataR2Only],2);
    
    % 5GHz, 5m, land
    maxDist = rfModel.dc.f5h5;
    [rfData.freq5.h5.land.run1.distTsR2Only,rfData.freq5.h5.land.run1.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq5.h5.land.run1.distTs,...
        rfData.freq5.h5.land.run1.rssiTs,maxDist);
    [rfData.freq5.h5.land.run2.distTsR2Only,rfData.freq5.h5.land.run2.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq5.h5.land.run2.distTs,...
        rfData.freq5.h5.land.run2.rssiTs,maxDist);
    rfData.freq5.h5.land.allDistDataR2Only = [...
        rfData.freq5.h5.land.run1.distTsR2Only.Data;
        rfData.freq5.h5.land.run2.distTsR2Only.Data];
    rfData.freq5.h5.land.allRssiRxDataR2Only = [...
        rfData.freq5.h5.land.run1.rssiTsR2Only.Data(:,1);
        rfData.freq5.h5.land.run2.rssiTsR2Only.Data(:,1)];
    rfData.freq5.h5.land.allRssiTxDataR2Only = [...
        rfData.freq5.h5.land.run1.rssiTsR2Only.Data(:,2);
        rfData.freq5.h5.land.run2.rssiTsR2Only.Data(:,2)];
    rfData.freq5.h5.land.allRssiRxTxDataR2Only =...
        mean([rfData.freq5.h5.land.allRssiRxDataR2Only,rfData.freq5.h5.land.allRssiTxDataR2Only],2);
    
    % 5GHz, 5m, sea
    maxDist = rfModel.dc.f5h5;
    [rfData.freq5.h5.sea.run1.distTsR2Only,rfData.freq5.h5.sea.run1.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq5.h5.sea.run1.distTs,...
        rfData.freq5.h5.sea.run1.rssiTs,maxDist);
    [rfData.freq5.h5.sea.run2.distTsR2Only,rfData.freq5.h5.sea.run2.rssiTsR2Only] =...
        removeDistRssiTsMaxDist(rfData.freq5.h5.sea.run2.distTs,...
        rfData.freq5.h5.sea.run2.rssiTs,maxDist);
    rfData.freq5.h5.sea.allDistDataR2Only = [...
        rfData.freq5.h5.sea.run1.distTsR2Only.Data;
        rfData.freq5.h5.sea.run2.distTsR2Only.Data];
    rfData.freq5.h5.sea.allRssiRxDataR2Only = [...
        rfData.freq5.h5.sea.run1.rssiTsR2Only.Data(:,1);
        rfData.freq5.h5.sea.run2.rssiTsR2Only.Data(:,1)];
    rfData.freq5.h5.sea.allRssiTxDataR2Only = [...
        rfData.freq5.h5.sea.run1.rssiTsR2Only.Data(:,2);
        rfData.freq5.h5.sea.run2.rssiTsR2Only.Data(:,2)];
    rfData.freq5.h5.sea.allRssiRxTxDataR2Only =...
        mean([rfData.freq5.h5.sea.allRssiRxDataR2Only,rfData.freq5.h5.sea.allRssiTxDataR2Only],2);
    
end

function [distTs,rssiTs] = removeDistRssiTsMaxDist(distTs,rssiTs,maxDist)

    iRemove = distTs.Data > maxDist;                    % indexed array of all distance values smaller than minDist
    distTs = delsample(distTs,'Index',find(iRemove));   % remove indexed array from distance timeseries
    rssiTs = delsample(rssiTs,'Index',find(iRemove));   % remove indexed array from RSSI timeseries

end

function rfModel = fitLossModels(rfModel,rfData)

%     % Other relevant variables
%     rfData.f2 = 2.412*1E9;          % 2.4 GHz frequency [Hz] 
%     rfData.f5 = 5.240*1E9;          % 5 GHz frequency [Hz]
%     rfData.lambda2 = c/rfData.f2;   % wavelength [m]
%     rfData.lambda5 = c/rfData.f5;   % wavelength [m]
%     rfData.p2 = 18;                 % 2.4 GHz transmit power setting [dBm]
%     rfData.p5 = 16;                 % 5 GHz transmit power setting [dBm]
%     rfData.g2 = 5;                  % 2.4 GHz antenna gain [dBi]
%     rfData.g5 = 7;                  % 5 GHz antenna gain [dBi]
%     rfData.bw2 = deg2rad(30);       % 2 GHz vertical half-power beamwidth [deg]
%     rfData.bw5 = deg2rad(15);       % 5 GHz vertical half-power beanwidth [deg]
%     rfData.hRx = 2;                 % receiving antenna height [m]
%     rfData.hTx2 = 2;                % transmitting antenna height low [m]
%     rfData.hTx5 = 5;                % transmitting antenna height high [m]

    R = -1;
    
    % 2GHz, 2m, land TRGR R2 fit
    rfModel.trgrR2Fun.f2h2l = @(PL,x) rfData.p2-(-10*log10((10^(rfData.g2/10))*(10^(rfData.g2/10))*(rfData.lambda2./(4*pi*x)).^2))-PL;
    x = rfData.freq2.h2.land.allDistDataR2Only;
    y = rfData.freq2.h2.land.allRssiRxTxDataR2Only;
    [rfModel.trgrR2FitCoef.f2h2l,rfModel.trgrR2Rsquared.f2h2l] = fitTrgrR2(x,y,rfModel.trgrR2Fun.f2h2l,10,1);
    rfModel.trgrR2Fit.f2h2l = rfData.p2-(-10*log10((10^(rfData.g2/10))*(10^(rfData.g2/10))*(rfData.lambda2./(4*pi*rfModel.dd)).^2))-rfModel.trgrR2FitCoef.f2h2l;
    
    % 2GHz, 2m, sea TRGR R2 fit
    rfModel.trgrR2Fun.f2h2s = @(PL,x) rfData.p2-(-10*log10((10^(rfData.g2/10))*(10^(rfData.g2/10))*(rfData.lambda2./(4*pi*x)).^2))-PL;
    x = rfData.freq2.h2.sea.allDistDataR2Only;
    y = rfData.freq2.h2.sea.allRssiRxTxDataR2Only;
    [rfModel.trgrR2FitCoef.f2h2s,rfModel.trgrR2Rsquared.f2h2s] = fitTrgrR2(x,y,rfModel.trgrR2Fun.f2h2s,10,1);
    rfModel.trgrR2Fit.f2h2s = rfData.p2-(-10*log10((10^(rfData.g2/10))*(10^(rfData.g2/10))*(rfData.lambda2./(4*pi*rfModel.dd)).^2))-rfModel.trgrR2FitCoef.f2h2s;
    
    % 2GHz, 5m, land TRGR R2 fit
    rfModel.trgrR2Fun.f2h5l = @(PL,x) rfData.p2-(-10*log10((10^(rfData.g2/10))*(10^(rfData.g2/10))*(rfData.lambda2./(4*pi*x)).^2))-PL;
    x = rfData.freq2.h5.land.allDistDataR2Only;
    y = rfData.freq2.h5.land.allRssiRxTxDataR2Only;
    [rfModel.trgrR2FitCoef.f2h5l,rfModel.trgrR2Rsquared.f2h5l] = fitTrgrR2(x,y,rfModel.trgrR2Fun.f2h5l,10,1);
    rfModel.trgrR2Fit.f2h5l = rfData.p2-(-10*log10((10^(rfData.g2/10))*(10^(rfData.g2/10))*(rfData.lambda2./(4*pi*rfModel.dd)).^2))-rfModel.trgrR2FitCoef.f2h5l;
    
    % 2GHz, 5m, sea TRGR R2 fit
    rfModel.trgrR2Fun.f2h5s = @(PL,x) rfData.p2-(-10*log10((10^(rfData.g2/10))*(10^(rfData.g2/10))*(rfData.lambda2./(4*pi*x)).^2))-PL;
    x = rfData.freq2.h5.sea.allDistDataR2Only;
    y = rfData.freq2.h5.sea.allRssiRxTxDataR2Only;
    [rfModel.trgrR2FitCoef.f2h5s,rfModel.trgrR2Rsquared.f2h5s] = fitTrgrR2(x,y,rfModel.trgrR2Fun.f2h5s,10,1);
    rfModel.trgrR2Fit.f2h5s = rfData.p2-(-10*log10((10^(rfData.g2/10))*(10^(rfData.g2/10))*(rfData.lambda2./(4*pi*rfModel.dd)).^2))-rfModel.trgrR2FitCoef.f2h5s;
    
    % 5GHz, 2m, land TRGR R2 fit
    rfModel.trgrR2Fun.f5h2l = @(PL,x) rfData.p5-(-10*log10((10^(rfData.g5/10))*(10^(rfData.g5/10))*(rfData.lambda5./(4*pi*x)).^2))-PL;
    x = rfData.freq5.h2.land.allDistDataR2Only;
    y = rfData.freq5.h2.land.allRssiRxTxDataR2Only;
    [rfModel.trgrR2FitCoef.f5h2l,rfModel.trgrR2Rsquared.f5h2l] = fitTrgrR2(x,y,rfModel.trgrR2Fun.f5h2l,10,1);
    rfModel.trgrR2Fit.f5h2l = rfData.p5-(-10*log10((10^(rfData.g5/10))*(10^(rfData.g5/10))*(rfData.lambda5./(4*pi*rfModel.dd)).^2))-rfModel.trgrR2FitCoef.f5h2l;
    
    % 5GHz, 2m, sea TRGR R2 fit
    rfModel.trgrR2Fun.f5h2s = @(PL,x) rfData.p5-(-10*log10((10^(rfData.g5/10))*(10^(rfData.g5/10))*(rfData.lambda5./(4*pi*x)).^2))-PL;
    x = rfData.freq5.h2.sea.allDistDataR2Only;
    y = rfData.freq5.h2.sea.allRssiRxTxDataR2Only;
    [rfModel.trgrR2FitCoef.f5h2s,rfModel.trgrR2Rsquared.f5h2s] = fitTrgrR2(x,y,rfModel.trgrR2Fun.f5h2s,10,1);
    rfModel.trgrR2Fit.f5h2s = rfData.p5-(-10*log10((10^(rfData.g5/10))*(10^(rfData.g5/10))*(rfData.lambda5./(4*pi*rfModel.dd)).^2))-rfModel.trgrR2FitCoef.f5h2s;
    
    % 5GHz, 5m, land TRGR R2 fit
    rfModel.trgrR2Fun.f5h5l = @(PL,x) rfData.p5-(-10*log10((10^(rfData.g5/10))*(10^(rfData.g5/10))*(rfData.lambda5./(4*pi*x)).^2))-PL;
    x = rfData.freq5.h5.land.allDistDataR2Only;
    y = rfData.freq5.h5.land.allRssiRxTxDataR2Only;
    [rfModel.trgrR2FitCoef.f5h5l,rfModel.trgrR2Rsquared.f5h5l] = fitTrgrR2(x,y,rfModel.trgrR2Fun.f5h5l,10,1);
    rfModel.trgrR2Fit.f5h5l = rfData.p5-(-10*log10((10^(rfData.g5/10))*(10^(rfData.g5/10))*(rfData.lambda5./(4*pi*rfModel.dd)).^2))-rfModel.trgrR2FitCoef.f5h5l;
    
    % 5GHz, 5m, sea TRGR R2 fit
    rfModel.trgrR2Fun.f5h5s = @(PL,x) rfData.p5-(-10*log10((10^(rfData.g5/10))*(10^(rfData.g5/10))*(rfData.lambda5./(4*pi*x)).^2))-PL;
    x = rfData.freq5.h5.sea.allDistDataR2Only;
    y = rfData.freq5.h5.sea.allRssiRxTxDataR2Only;
    [rfModel.trgrR2FitCoef.f5h5s,rfModel.trgrR2Rsquared.f5h5s] = fitTrgrR2(x,y,rfModel.trgrR2Fun.f5h5s,10,1);
    rfModel.trgrR2Fit.f5h5s = rfData.p5-(-10*log10((10^(rfData.g5/10))*(10^(rfData.g5/10))*(rfData.lambda5./(4*pi*rfModel.dd)).^2))-rfModel.trgrR2FitCoef.f5h5s;
    
    % 2GHz, 2m, land TRGR fit
    rfModel.trgrFun.f2h2l = @(p,x) 20.*log10(rfData.lambda2./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10))./(sqrt(x.^2+(rfData.hTx2+p(2)-rfData.hRx).^2)))+((R+p(3)).*(sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rfData.hTx2+p(2)+rfData.hRx).^2))-(sqrt(x.^2+(rfData.hTx2+p(2)-rfData.hRx).^2))))./rfData.lambda2)))./(sqrt(x.^2+(rfData.hTx2+p(2)+rfData.hRx).^2)))))+rfData.p2-p(1);
    x = rfData.freq2.h2.land.allDistData;
    y = rfData.freq2.h2.land.allRssiRxTxData;
    [rfModel.trgrFitCoef.f2h2l,rfModel.trgrRsquared.f2h2l] = fitTrgr(x,y,rfModel.trgrFun.f2h2l,[8,0,0.5],1);
    rfModel.trgrFit.f2h2l = 20.*log10(rfData.lambda2./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10))./(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f2h2l(2)-rfData.hRx).^2)))+((R+rfModel.trgrFitCoef.f2h2l(3)).*(sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f2h2l(2)+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f2h2l(2)-rfData.hRx).^2))))./rfData.lambda2)))./(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f2h2l(2)+rfData.hRx).^2)))))+rfData.p2-rfModel.trgrFitCoef.f2h2l(1);

    % 2GHz, 2m, sea TRGR fit
    rfModel.trgrFun.f2h2s = @(p,x) 20.*log10(rfData.lambda2./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10))./(sqrt(x.^2+(rfData.hTx2+p(2)-rfData.hRx).^2)))+((R+p(3)).*(sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rfData.hTx2+p(2)+rfData.hRx).^2))-(sqrt(x.^2+(rfData.hTx2+p(2)-rfData.hRx).^2))))./rfData.lambda2)))./(sqrt(x.^2+(rfData.hTx2+p(2)+rfData.hRx).^2)))))+rfData.p2-p(1);
    x = rfData.freq2.h2.sea.allDistData;
    y = rfData.freq2.h2.sea.allRssiRxTxData;
    [rfModel.trgrFitCoef.f2h2s,rfModel.trgrRsquared.f2h2s] = fitTrgr(x,y,rfModel.trgrFun.f2h2s,[8,0,0.5],1);
    rfModel.trgrFit.f2h2s = 20.*log10(rfData.lambda2./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10))./(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f2h2s(2)-rfData.hRx).^2)))+((R+rfModel.trgrFitCoef.f2h2s(3)).*(sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f2h2s(2)+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f2h2s(2)-rfData.hRx).^2))))./rfData.lambda2)))./(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f2h2s(2)+rfData.hRx).^2)))))+rfData.p2-rfModel.trgrFitCoef.f2h2s(1);
    
    % 2GHz, 5m, land TRGR fit
    rfModel.trgrFun.f2h5l = @(p,x) 20.*log10(rfData.lambda2./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10))./(sqrt(x.^2+(rfData.hTx5+p(2)-rfData.hRx).^2)))+((R+p(3)).*(sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rfData.hTx5+p(2)+rfData.hRx).^2))-(sqrt(x.^2+(rfData.hTx5+p(2)-rfData.hRx).^2))))./rfData.lambda2)))./(sqrt(x.^2+(rfData.hTx5+p(2)+rfData.hRx).^2)))))+rfData.p2-p(1);
    x = rfData.freq2.h5.land.allDistData;
    y = rfData.freq2.h5.land.allRssiRxTxData;
    [rfModel.trgrFitCoef.f2h5l,rfModel.trgrRsquared.f2h5l] = fitTrgr(x,y,rfModel.trgrFun.f2h5l,[8,0,0.5],1);
    rfModel.trgrFit.f2h5l = 20.*log10(rfData.lambda2./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10))./(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f2h5l(2)-rfData.hRx).^2)))+((R+rfModel.trgrFitCoef.f2h5l(3)).*(sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f2h5l(2)+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f2h5l(2)-rfData.hRx).^2))))./rfData.lambda2)))./(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f2h5l(2)+rfData.hRx).^2)))))+rfData.p2-rfModel.trgrFitCoef.f2h5l(1);

    % 2GHz, 5m, sea TRGR fit
    rfModel.trgrFun.f2h5s = @(p,x) 20.*log10(rfData.lambda2./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10))./(sqrt(x.^2+(rfData.hTx5+p(2)-rfData.hRx).^2)))+((R+p(3)).*(sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rfData.hTx5+p(2)+rfData.hRx).^2))-(sqrt(x.^2+(rfData.hTx5+p(2)-rfData.hRx).^2))))./rfData.lambda2)))./(sqrt(x.^2+(rfData.hTx5+p(2)+rfData.hRx).^2)))))+rfData.p2-p(1);
    x = rfData.freq2.h5.sea.allDistData;
    y = rfData.freq2.h5.sea.allRssiRxTxData;
    [rfModel.trgrFitCoef.f2h5s,rfModel.trgrRsquared.f2h5s] = fitTrgr(x,y,rfModel.trgrFun.f2h5s,[8,0,0.5],1);
    rfModel.trgrFit.f2h5s = 20.*log10(rfData.lambda2./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10))./(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f2h5s(2)-rfData.hRx).^2)))+((R+rfModel.trgrFitCoef.f2h5s(3)).*(sqrt(10.^(rfData.g2./10).*10.^(rfData.g2./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f2h5s(2)+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f2h5s(2)-rfData.hRx).^2))))./rfData.lambda2)))./(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f2h5s(2)+rfData.hRx).^2)))))+rfData.p2-rfModel.trgrFitCoef.f2h5s(1);
    
    % 5GHz, 2m, land TRGR fit
    rfModel.trgrFun.f5h2l = @(p,x) 20.*log10(rfData.lambda5./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10))./(sqrt(x.^2+(rfData.hTx2+p(2)-rfData.hRx).^2)))+((R+p(3)).*(sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rfData.hTx2+p(2)+rfData.hRx).^2))-(sqrt(x.^2+(rfData.hTx2+p(2)-rfData.hRx).^2))))./rfData.lambda5)))./(sqrt(x.^2+(rfData.hTx2+p(2)+rfData.hRx).^2)))))+rfData.p5-p(1);
    x = rfData.freq5.h2.land.allDistData;
    y = rfData.freq5.h2.land.allRssiRxTxData;
    [rfModel.trgrFitCoef.f5h2l,rfModel.trgrRsquared.f5h2l] = fitTrgr(x,y,rfModel.trgrFun.f5h2l,[8,0,0.5],1);
    rfModel.trgrFit.f5h2l = 20.*log10(rfData.lambda5./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10))./(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f5h2l(2)-rfData.hRx).^2)))+((R+rfModel.trgrFitCoef.f5h2l(3)).*(sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f5h2l(2)+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f5h2l(2)-rfData.hRx).^2))))./rfData.lambda5)))./(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f5h2l(2)+rfData.hRx).^2)))))+rfData.p5-rfModel.trgrFitCoef.f5h2l(1);

    % 5GHz, 2m, sea TRGR fit
    rfModel.trgrFun.f5h2s = @(p,x) 20.*log10(rfData.lambda5./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10))./(sqrt(x.^2+(rfData.hTx2+p(2)-rfData.hRx).^2)))+((R+p(3)).*(sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rfData.hTx2+p(2)+rfData.hRx).^2))-(sqrt(x.^2+(rfData.hTx2+p(2)-rfData.hRx).^2))))./rfData.lambda5)))./(sqrt(x.^2+(rfData.hTx2+p(2)+rfData.hRx).^2)))))+rfData.p5-p(1);
    x = rfData.freq5.h2.sea.allDistData;
    y = rfData.freq5.h2.sea.allRssiRxTxData;
    [rfModel.trgrFitCoef.f5h2s,rfModel.trgrRsquared.f5h2s] = fitTrgr(x,y,rfModel.trgrFun.f5h2s,[8,0,0.5],1);
    rfModel.trgrFit.f5h2s = 20.*log10(rfData.lambda5./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10))./(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f5h2s(2)-rfData.hRx).^2)))+((R+rfModel.trgrFitCoef.f5h2s(3)).*(sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f5h2s(2)+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f5h2s(2)-rfData.hRx).^2))))./rfData.lambda5)))./(sqrt(rfModel.dd.^2+(rfData.hTx2+rfModel.trgrFitCoef.f5h2s(2)+rfData.hRx).^2)))))+rfData.p5-rfModel.trgrFitCoef.f5h2s(1);
    
    % 5GHz, 5m, land TRGR fit
    rfModel.trgrFun.f5h5l = @(p,x) 20.*log10(rfData.lambda5./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10))./(sqrt(x.^2+(rfData.hTx5+p(2)-rfData.hRx).^2)))+((R+p(3)).*(sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rfData.hTx5+p(2)+rfData.hRx).^2))-(sqrt(x.^2+(rfData.hTx5+p(2)-rfData.hRx).^2))))./rfData.lambda5)))./(sqrt(x.^2+(rfData.hTx5+p(2)+rfData.hRx).^2)))))+rfData.p5-p(1);
    x = rfData.freq5.h5.land.allDistData;
    y = rfData.freq5.h5.land.allRssiRxTxData;
    [rfModel.trgrFitCoef.f5h5l,rfModel.trgrRsquared.f5h5l] = fitTrgr(x,y,rfModel.trgrFun.f5h5l,[8,0,0.5],1);
    rfModel.trgrFit.f5h5l = 20.*log10(rfData.lambda5./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10))./(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f5h5l(2)-rfData.hRx).^2)))+((R+rfModel.trgrFitCoef.f5h5l(3)).*(sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f5h5l(2)+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f5h5l(2)-rfData.hRx).^2))))./rfData.lambda5)))./(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f5h5l(2)+rfData.hRx).^2)))))+rfData.p5-rfModel.trgrFitCoef.f5h5l(1);

    % 5GHz, 5m, sea TRGR fit
    rfModel.trgrFun.f5h5s = @(p,x) 20.*log10(rfData.lambda5./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10))./(sqrt(x.^2+(rfData.hTx5+p(2)-rfData.hRx).^2)))+((R+p(3)).*(sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10)).*exp(-(1i).*((2.*pi.*((sqrt(x.^2+(rfData.hTx5+p(2)+rfData.hRx).^2))-(sqrt(x.^2+(rfData.hTx5+p(2)-rfData.hRx).^2))))./rfData.lambda5)))./(sqrt(x.^2+(rfData.hTx5+p(2)+rfData.hRx).^2)))))+rfData.p5-p(1);
    x = rfData.freq5.h5.sea.allDistData;
    y = rfData.freq5.h5.sea.allRssiRxTxData;
    [rfModel.trgrFitCoef.f5h5s,rfModel.trgrRsquared.f5h5s] = fitTrgr(x,y,rfModel.trgrFun.f5h5s,[8,0,0.5],1);
    rfModel.trgrFit.f5h5s = 20.*log10(rfData.lambda5./(4.*pi))+20.*log10(abs((sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10))./(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f5h5s(2)-rfData.hRx).^2)))+((R+rfModel.trgrFitCoef.f5h5s(3)).*(sqrt(10.^(rfData.g5./10).*10.^(rfData.g5./10)).*exp(-(1i).*((2.*pi.*((sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f5h5s(2)+rfData.hRx).^2))-(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f5h5s(2)-rfData.hRx).^2))))./rfData.lambda5)))./(sqrt(rfModel.dd.^2+(rfData.hTx5+rfModel.trgrFitCoef.f5h5s(2)+rfData.hRx).^2)))))+rfData.p5-rfModel.trgrFitCoef.f5h5s(1);
    
    % Disp coefficients
    disp(' ');
    disp('==== Two-Ray Ground Reflection Region Two Approximation Model Fit Coefficients ====');
    disp('2GHz, 2m, land fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrR2FitCoef.f2h2l)])
    disp(['Rsquared = ',num2str(rfModel.trgrR2Rsquared.f2h2l)]);
    disp('2GHz, 2m, sea fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrR2FitCoef.f2h2s)]);
    disp(['Rsquared = ',num2str(rfModel.trgrR2Rsquared.f2h2s)]);
    disp('2GHz, 5m, land fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrR2FitCoef.f2h5l)]);
    disp(['Rsquared = ',num2str(rfModel.trgrR2Rsquared.f2h5l)]);
    disp('2GHz, 5m, sea fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrR2FitCoef.f2h5s)]);
    disp(['Rsquared = ',num2str(rfModel.trgrR2Rsquared.f2h5s)]);
    disp('5GHz, 2m, land fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrR2FitCoef.f5h2l)]);
    disp(['Rsquared = ',num2str(rfModel.trgrR2Rsquared.f5h2l)]);
    disp('5GHz, 2m, sea fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrR2FitCoef.f5h2s)]);
    disp(['Rsquared = ',num2str(rfModel.trgrR2Rsquared.f5h2s)]);
    disp('5GHz, 5m, land fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrR2FitCoef.f5h5l)]);
    disp(['Rsquared = ',num2str(rfModel.trgrR2Rsquared.f5h5l)]);
    disp('5GHz, 5m, sea fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrR2FitCoef.f5h5s)]);
    disp(['Rsquared = ',num2str(rfModel.trgrR2Rsquared.f5h5s)]);
    disp('===================================================================================');
    
    disp(' ');    
    disp('============== Two-Ray Ground Reflection Full Model Fit Coefficients ==============');
    disp('2GHz, 2m, land fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrFitCoef.f2h2l(1))]);
    disp(['Corrected transmitting antenna height, h_Tx = ',num2str(rfData.hTx2+rfModel.trgrFitCoef.f2h2l(2))]);
    disp(['Corrected ground reflection coefficient, R = ',num2str(R+rfModel.trgrFitCoef.f2h2l(3))]);
    disp(['Rsquared = ',num2str(rfModel.trgrRsquared.f2h2l)]);
    disp('2GHz, 2m, sea fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrFitCoef.f2h2s(1))]);
    disp(['Corrected transmitting antenna height, h_Tx = ',num2str(rfData.hTx2+rfModel.trgrFitCoef.f2h2s(2))]);
    disp(['Corrected ground reflection coefficient, R = ',num2str(R+rfModel.trgrFitCoef.f2h2s(3))]);
    disp(['Rsquared = ',num2str(rfModel.trgrRsquared.f2h2s)]);
    disp('2GHz, 5m, land fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrFitCoef.f2h5l(1))]);
    disp(['Corrected transmitting antenna height, h_Tx = ',num2str(rfData.hTx5+rfModel.trgrFitCoef.f2h5l(2))]);
    disp(['Corrected ground reflection coefficient, R = ',num2str(R+rfModel.trgrFitCoef.f2h5l(3))]);
    disp(['Rsquared = ',num2str(rfModel.trgrRsquared.f2h5l)]);
    disp('2GHz, 5m, sea fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrFitCoef.f2h5s(1))]);
    disp(['Corrected transmitting antenna height, h_Tx = ',num2str(rfData.hTx5+rfModel.trgrFitCoef.f2h5s(2))]);
    disp(['Corrected ground reflection coefficient, R = ',num2str(R+rfModel.trgrFitCoef.f2h5s(3))]);
    disp(['Rsquared = ',num2str(rfModel.trgrRsquared.f2h5s)]);
    disp('5GHz, 2m, land fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrFitCoef.f5h2l(1))]);
    disp(['Corrected transmitting antenna height, h_Tx = ',num2str(rfData.hTx2+rfModel.trgrFitCoef.f5h2l(2))]);
    disp(['Corrected ground reflection coefficient, R = ',num2str(R+rfModel.trgrFitCoef.f5h2l(3))]);
    disp(['Rsquared = ',num2str(rfModel.trgrRsquared.f5h2l)]);
    disp('5GHz, 2m, sea fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrFitCoef.f5h2s(1))]);
    disp(['Corrected transmitting antenna height, h_Tx = ',num2str(rfData.hTx2+rfModel.trgrFitCoef.f5h2s(2))]);
    disp(['Corrected ground reflection coefficient, R = ',num2str(R+rfModel.trgrFitCoef.f5h2s(3))]);
    disp(['Rsquared = ',num2str(rfModel.trgrRsquared.f5h2s)]);
    disp('5GHz, 5m, land fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrFitCoef.f5h5l(1))]);
    disp(['Corrected transmitting antenna height, h_Tx = ',num2str(rfData.hTx5+rfModel.trgrFitCoef.f5h5l(2))]);
    disp(['Corrected ground reflection coefficient, R = ',num2str(R+rfModel.trgrFitCoef.f5h5l(3))]);
    disp(['Rsquared = ',num2str(rfModel.trgrRsquared.f5h5l)]);
    disp('5GHz, 5m, sea fit coefficients: ');
    disp(['Path loss from theoretical, PL = ',num2str(rfModel.trgrFitCoef.f5h5s(1))]);
    disp(['Corrected transmitting antenna height, h_Tx = ',num2str(rfData.hTx5+rfModel.trgrFitCoef.f5h5s(2))]);
    disp(['Corrected ground reflection coefficient, R = ',num2str(R+rfModel.trgrFitCoef.f5h5s(3))]);
    disp(['Rsquared = ',num2str(rfModel.trgrRsquared.f5h5s)]);
    disp('===================================================================================');
    
end

function [PL,Rsq] = fitTrgrR2(x,y,dataFitFun,PL0,fitTrue)

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
        p = fmincon(error,p0,[],[],[],[],[0,-0.3,0],[25,0.3,1]);
        
        % Calculate R-squared
        SStot = sum((mean(y)-y).^2);
        SSres = error(p);
        Rsq = 1-(SSres/SStot);
        
    else
        
        p = p0;
        Rsq = 1;
        
    end
    
end

function plotTrgrR2Fits(rfData,rfModel,figNum)

    % Create new figure
    figure(figNum);
    
    % Plot variables
    xMin = 0;
    xMax = 550;
    yMin = -120;
    yMax = 0;
    titleFontSize = 24;
    defaultFontSize = 22;
    
    % 2GHz, 2m, land + sea
    f2h2 = subplot(2,2,1);
    hold on;
    plot(rfData.freq2.h2.land.allDistData,...
        rfData.freq2.h2.land.allRssiRxTxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq2.h2.sea.allDistData,...
        rfData.freq2.h2.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgrR2Fit.f2h2l,...
        'Color','#000000','LineStyle','--','Linewidth',2);
    plot(rfModel.dd,rfModel.trgrR2Fit.f2h2s,...
        'Color','#000000','LineStyle','-','Linewidth',2);
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('land RSSI data',...
        'sea RSSI data',...
        'P_r, apprx. two-ray fit to land ',...
        'P_r, apprx. two-ray fit to sea');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 2 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 5m, land + sea
    f2h5 = subplot(2,2,3);
    hold on;
    plot(rfData.freq2.h5.land.allDistData,...
        rfData.freq2.h5.land.allRssiRxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq2.h5.sea.allDistData,...
        rfData.freq2.h5.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgrR2Fit.f2h5l,...
        'Color','#000000','LineStyle','--','Linewidth',2);
    plot(rfModel.dd,rfModel.trgrR2Fit.f2h5s,...
        'Color','#000000','LineStyle','-','Linewidth',2);
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 2m, land + sea
    f5h2 = subplot(2,2,2);
    hold on;
    plot(rfData.freq5.h2.land.allDistData,...
        rfData.freq5.h2.land.allRssiRxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq5.h2.sea.allDistData,...
        rfData.freq5.h2.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgrR2Fit.f5h2l,...
        'Color','#000000','LineStyle','--','Linewidth',2);
    plot(rfModel.dd,rfModel.trgrR2Fit.f5h2s,...
        'Color','#000000','LineStyle','-','Linewidth',2);
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 2 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 5m, land + sea
    f5h5 = subplot(2,2,4);
    hold on;
    plot(rfData.freq5.h5.land.allDistData,...
        rfData.freq5.h5.land.allRssiRxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq5.h5.sea.allDistData,...
        rfData.freq5.h5.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgrR2Fit.f5h5l,...
        'Color','#000000','LineStyle','--','Linewidth',2);
    plot(rfModel.dd,rfModel.trgrR2Fit.f5h5s,...
        'Color','#000000','LineStyle','-','Linewidth',2);
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % Link axes
    linkaxes([f2h2,f2h5,f5h2,f5h5],'x');
    linkaxes([f2h2,f2h5,f5h2,f5h5],'y');

end

function plotTrgrFits(rfData,rfModel,figNum)

    % Create new figure
    figure(figNum);
    
    % Plot variables
    xMin = 0;
    xMax = 550;
    yMin = -120;
    yMax = 0;
    titleFontSize = 24;
    defaultFontSize = 22;
    
    % 2GHz, 2m, land + sea
    f2h2 = subplot(2,2,1);
    hold on;
    plot(rfData.freq2.h2.land.allDistData,...
        rfData.freq2.h2.land.allRssiRxTxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq2.h2.sea.allDistData,...
        rfData.freq2.h2.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgrFit.f2h2l,...
        'Color','#000000','LineStyle','--','Linewidth',2);
    plot(rfModel.dd,rfModel.trgrFit.f2h2s,...
        'Color','#000000','LineStyle','-','Linewidth',2);
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    legend('land RSSI data',...
        'sea RSSI data',...
        'P_r, full two-ray fit to land ',...
        'P_r, full two-ray fit to sea');
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 2 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 2GHz, 5m, land + sea
    f2h5 = subplot(2,2,3);
    hold on;
    plot(rfData.freq2.h5.land.allDistData,...
        rfData.freq2.h5.land.allRssiRxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq2.h5.sea.allDistData,...
        rfData.freq2.h5.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgrFit.f2h5l,...
        'Color','#000000','LineStyle','--','Linewidth',2);
    plot(rfModel.dd,rfModel.trgrFit.f2h5s,...
        'Color','#000000','LineStyle','-','Linewidth',2);
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 2.412 GHz, h_T_x = 5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 2m, land + sea
    f5h2 = subplot(2,2,2);
    hold on;
    plot(rfData.freq5.h2.land.allDistData,...
        rfData.freq5.h2.land.allRssiRxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq5.h2.sea.allDistData,...
        rfData.freq5.h2.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgrFit.f5h2l,...
        'Color','#000000','LineStyle','--','Linewidth',2);
    plot(rfModel.dd,rfModel.trgrFit.f5h2s,...
        'Color','#000000','LineStyle','-','Linewidth',2);
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 2 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % 5GHz, 5m, land + sea
    f5h5 = subplot(2,2,4);
    hold on;
    plot(rfData.freq5.h5.land.allDistData,...
        rfData.freq5.h5.land.allRssiRxData,...
        'Color','#77AC30','LineStyle','None','Marker','x','MarkerSize',5);
    plot(rfData.freq5.h5.sea.allDistData,...
        rfData.freq5.h5.sea.allRssiRxData,...
        'Color','#0072BD','LineStyle','None','Marker','+','MarkerSize',5);
    plot(rfModel.dd,rfModel.trgrFit.f5h5l,...
        'Color','#000000','LineStyle','--','Linewidth',2);
    plot(rfModel.dd,rfModel.trgrFit.f5h5s,...
        'Color','#000000','LineStyle','-','Linewidth',2);
    hold off;
    xlabel('antenna separation distance [m]');
    ylabel('RSSI [dBm]');
    xlim([xMin,xMax]);
    ylim([yMin,yMax]);
    set(gca,'FontName','Times New Roman','FontSize',defaultFontSize);
    title('f = 5.240 GHz, h_T_x = 5 m','FontName','Times New Roman','FontSize',titleFontSize);
    grid on;
    
    % Link axes
    linkaxes([f2h2,f2h5,f5h2,f5h5],'x');
    linkaxes([f2h2,f2h5,f5h2,f5h5],'y');

end