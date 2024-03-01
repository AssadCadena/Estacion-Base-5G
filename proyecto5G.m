viewer = siteviewer("Buildings","EstadioSiles.osm","Basemap","topographic");

tx = txsite("Name","Small cell transmitter", ...
    "Latitude",-16.50060, ...
    "Longitude",-68.12302, ...
    "AntennaHeight",10, ...
    "TransmitterPower",2, ...
    "TransmitterFrequency", 3.5e9);
show(tx)

%MODELO DE PROPAGACION%
rtpm = propagationModel("raytracing", ...
    "Method","sbr", ...
    "MaxNumReflections",0, ...
    "BuildingsMaterial","perfect-reflector", ...
    "TerrainMaterial","perfect-reflector");

%COVERAGE%
% coverage(tx,rtpm, ...
%     "SignalStrengths",-120:-5, ...
%     "MaxRange",250, ...
%     "Resolution",3, ...
%     "Transparency",0.6)

%RECEPTOR%
rx = rxsite("Name","Small cell receiver", ...
    "Latitude",-16.500163, ...
    "Longitude",-68.122608, ...
    "AntennaHeight",1);
los(tx,rx)

clearMap(viewer)
rtpm.BuildingsMaterial = "concrete";
rtpm.TerrainMaterial = "concrete";
rtPlusWeather = ...
    rtpm + propagationModel("gas") + propagationModel("rain","RainRate",700);
rtPlusWeather.PropagationModels(1).MaxNumReflections = 2;
rtPlusWeather.PropagationModels(1).AngularSeparation = "low";
rtPlusWeather.PropagationModels(1).MaxNumDiffractions = 0;
ss = sigstrength(rx,tx,rtPlusWeather);
disp("Received power with two-reflection and one-diffraction paths: " + ss + " dBm")
raytrace(tx,rx,rtPlusWeather)
clearMap(viewer)
% rtPlusWeather.PropagationModels(1).MaxNumReflections = 1;
% rtPlusWeather.PropagationModels(1).MaxNumDiffractions = 0;

% coverage(tx,rtPlusWeather, ...
%     "SignalStrengths",-120:-5, ...
%     "MaxRange", 250, ...
%     "Resolution",2, ...
%     "Transparency",0.6)

rtPlusWeather.PropagationModels(1).MaxNumReflections = 2;
rtPlusWeather.PropagationModels(1).MaxNumDiffractions = 1;
rtPlusWeather.PropagationModels(1).AngularSeparation = "high";
show(tx)

% load("coverageResultsTwoRefOneDiff.mat");
% contour(coverageResultsTwoRefOneDiff, ...
%     "Type","power", ...
%     "Transparency",0.6)
% coverageResultsTwoRefOneDiff = coverage(tx,rtPlusWeather, ...
%     "SignalStrengths",-120:-5, ...
%     "MaxRange", 250, ...
%     "Resolution",2, ...
%     "Transparency",0.6);

%####ANTENNNA####%
azvec = -180:180; % Azimuth angles (deg)
elvec = -90:90; % Elevation angles (deg)
SLA = 30; % Maximum side-lobe level attenuation (dB)
tilt = 0; % Tilt angle (deg)
az3dB = 65; % 3 dB beamwidth in azimuth (deg)
el3dB = 65; % 3 dB beamwidth in elevation (deg)
lambda = physconst("lightspeed")/tx.TransmitterFrequency; % Wavelength (m)

[az,el] = meshgrid(azvec,elvec);
azMagPattern = -min(12*(az/az3dB).^2,SLA);
elMagPattern = -min(12*((el-tilt)/el3dB).^2,SLA);
combinedMagPattern = -min(-(azMagPattern + elMagPattern),SLA); % Relative antenna gain (dB)

antennaElement = phased.CustomAntennaElement("MagnitudePattern",combinedMagPattern);
tx.Antenna = phased.URA('Size',[64 64],...
    'Lattice','Rectangular','ArrayNormal','x');
tx.Antenna.ElementSpacing = [0.007 0.007];
% Calculate Row taper
sll = 31;
rwind = chebwin(64, sll);
% Calculate Column taper
sll = 30;
cwind = chebwin(64, sll);
% Calculate taper
taper = rwind*cwind.';
tx.Antenna.Taper = taper.';

% Create a cosine antenna element
Elem = phased.CosineAntennaElement;
Elem.CosinePower = [1 1];
Elem.FrequencyRange = [0 3500000000];
tx.Antenna.Element = Elem;
% Assign Frequencies and Propagation Speed
Frequency = 3500000000;
PropagationSpeed = 300000000;

antennaDirectivity = pattern(tx.Antenna, tx.TransmitterFrequency);
antennaDirectivityMax = max(antennaDirectivity(:));
disp("Peak antenna directivity: " + antennaDirectivityMax + " dBi")

tx.AntennaAngle = 80;

clearMap(viewer)
show(rx)
pattern(tx,"Transparency",0.6)
hide(tx)

rtPlusWeather.PropagationModels(1).MaxNumReflections = 3;
rtPlusWeather.PropagationModels(1).MaxNumDiffractions = 1;
ray = raytrace(tx,rx,rtPlusWeather);
disp(ray{1})

aod = ray{1}.AngleOfDeparture;
steeringaz = wrapTo180(aod(1)-tx.AntennaAngle(1));
steeringVector = phased.SteeringVector("SensorArray",tx.Antenna);
sv = steeringVector(tx.TransmitterFrequency,[steeringaz;aod(2)]);
tx.Antenna.Taper = taper;

pattern(tx,"Transparency",0.6)
raytrace(tx,rx,rtPlusWeather);
hide(tx)
    
ss = sigstrength(rx,tx,rtPlusWeather);
disp("Received power with beam steering: " + ss + " dBm")