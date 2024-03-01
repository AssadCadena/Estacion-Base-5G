centerSite = txsite("Name","Small cell transmitter", ...
    "Latitude",-16.50060, ...
    "Longitude",-68.12302);
numCellSites = 7;
siteDistances = zeros(1,numCellSites);
siteAngles = zeros(1,numCellSites);
isd = 200; % Inter-site distance
siteDistances(2:7) = isd;
siteAngles(2:7) = 30:60:360;
siteDistances(8:13) = 2*isd*cosd(30);
siteAngles(8:13) = 0:60:300;
siteDistances(14:19) = 2*isd;
siteAngles(14:19) = 30:60:360;
% Initialize arrays for cell transmitter parameters
numCells = numCellSites*3;
cellLats = zeros(1,numCells);
cellLons = zeros(1,numCells);
cellNames = strings(1,numCells);
cellAngles = zeros(1,numCells);
% Define cell sector angles
cellSectorAngles = [30 150 270];
% For each cell site location, populate data for each cell transmitter
cellInd = 1;
for siteInd = 1:numCellSites
 % Compute site location using distance and angle from center site
 [cellLat,cellLon] = location(centerSite, siteDistances(siteInd), siteAngles(siteInd));
 
 % Assign values for each cell
 for cellSectorAngle = cellSectorAngles
 cellNames(cellInd) = "Cell " + cellInd;
 cellLats(cellInd) = cellLat;
 cellLons(cellInd) = cellLon;
 cellAngles(cellInd) = cellSectorAngle;
 cellInd = cellInd + 1;
 end
end
% Define transmitter parameters using Table 8-2 (b) of Report ITU-R M.[IMT-2020.EVAL]
fq = 3.5e9; % Carrier frequency (4 GHz) for Dense Urban-eMBB
antHeight = 10; % m
txPowerDBm = 44; % Total transmit power in dBm
txPower = 10.^((txPowerDBm-30)/10);
txs = txsite('Name',cellNames, ...
 'Latitude',cellLats, ...
 'Longitude',cellLons, ...
 'AntennaAngle',cellAngles, ...
 'AntennaHeight',antHeight, ...
 'TransmitterFrequency',fq, ...
 'TransmitterPower',txPower);

viewer = siteviewer("Buildings","EstadioSiles.osm", "Basemap","topographic");
show(txs);
% Define pattern parameters
azvec = -180:180;
elvec = -90:90;
Am = 30; % Maximum attenuation (dB)
tilt = 0; % Tilt angle
az3dB = 65; % 3 dB bandwidth in azimuth
el3dB = 65; % 3 dB bandwidth in elevation
% Define antenna pattern
[az,el] = meshgrid(azvec,elvec);
azMagPattern = -12*(az/az3dB).^2;
elMagPattern = -12*((el-tilt)/el3dB).^2;
combinedMagPattern = azMagPattern + elMagPattern;
combinedMagPattern(combinedMagPattern<-Am) = -Am; % Saturate at max attenuation
phasepattern = zeros(size(combinedMagPattern));
% Create antenna element
antennaElement = phased.CustomAntennaElement(...
 'AzimuthAngles',azvec, ...
 'ElevationAngles',elvec, ...
 'MagnitudePattern',combinedMagPattern, ...
 'PhasePattern',phasepattern);
 
% Display radiation pattern
f = figure;
pattern(antennaElement,fq);
% Assign the antenna element for each cell transmitter
for tx = txs
 tx.Antenna = antennaElement;
end
% Define receiver parameters using Table 8-2 (b) of Report ITU-R M.[IMT-2020.EVAL] 
bw = 20e6; % 20 MHz bandwidth
rxNoiseFigure = 7; % dB
rxNoisePower = -174 + 10*log10(bw) + rxNoiseFigure;
rxGain = 0; % dBi
rxAntennaHeight = 1.5; % m
% Define array size
nrow = 64;
ncol = 64;
% Define element spacing
lambda = physconst('lightspeed')/fq;
drow = lambda/2;
dcol = lambda/2;
% Define taper to reduce sidelobes 
dBdown = 30;
taperz = chebwin(nrow,dBdown);
tapery = chebwin(ncol,dBdown);
tap = taperz*tapery.'; % Multiply vector tapers to get 8-by-8 taper values
% Create 8-by-8 antenna array
cellAntenna = phased.URA('Size',[nrow ncol], ...
 'Element',antennaElement, ...
 'ElementSpacing',[drow dcol], ...
 'Taper',tap, ...
 'ArrayNormal','x');
 
% Display radiation pattern
f = figure;
% pattern(cellAntenna,fq);
% Assign the antenna array for each cell transmitter, and apply downtilt.
% Without downtilt, pattern is too narrow for transmitter vicinity.
downtilt = 15;
for tx = txs
 tx.Antenna = cellAntenna;
 tx.AntennaAngle = [tx.AntennaAngle; -downtilt];
end
% Display SINR map
if isvalid(f)
 close(f)
end
sinr(txs,'close-in', ...
 'ReceiverGain',rxGain, ...
 'ReceiverAntennaHeight',rxAntennaHeight, ...
 'ReceiverNoisePower',rxNoisePower, ... 
 'MaxRange',isd, ...
 'Resolution',isd/20)
