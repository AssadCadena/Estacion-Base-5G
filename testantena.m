% Design reflector-backed dipole antenna element
fq = 3.5e9; % 3.5 GHz
%myelement = design(refl,fq);
%myelement.Exciter = design(myelement.Exciter,fq);
%*******************************************
azvec = -180:180;
elvec = -90:90;
Am = 30; % Maximum attenuation (dB)
tilt = 0; % Tilt angle
az3dB = 65; % 3 dB bandwidth in azimuth
el3dB = 65; % 3 dB bandwidth in elevation
%******************************************
Frequency = 3500000000;
PropagationSpeed = 300000000;


% Tilt antenna element to radiate in xy-plane, with boresight along x-axis
%myelement.Tilt = 90;
%myelement.TiltAxis = "y";
%myelement.Exciter.Tilt = 90;
%myelement.Exciter.TiltAxis = "y";
%*****************************************************************************
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

% Create 7-by-7 antenna array                            
nrow = 64;
ncol = 64;

lambda = physconst('lightspeed')/fq;
drow = lambda/2;
dcol = lambda/2;

dBdown = 30;
taperz = chebwin(nrow,dBdown);
tapery = chebwin(ncol,dBdown);
tap = taperz*tapery.'; % Multiply vector tapers to get 8-by-8 taper values

myarray = phased.URA("Size",[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol],...
    'Taper',tap, ...
    'ArrayNormal','x');

% Define element spacing to be half-wavelength at 10 GHz, and specify 
% array plane as yz-plane, which directs radiation in x-axis direction
lambda = physconst("lightspeed")/fq;
drow = lambda/4;
dcol = lambda/4; 
myarray.ElementSpacing = [drow dcol];
myarray.ArrayNormal = "x";
    
% Display radiation pattern
f = figure;
az = -180:1:180;
el = -90:1:90;  
pattern(myarray,fq,az,el)
w = ones(getNumElements(myarray), length(Frequency));

% Plot 2d azimuth graph
format = 'polar';
cutAngle = 0;
plotType = 'Directivity';
plotStyle = 'Overlay';
figure;
pattern(myarray, Frequency, az, cutAngle, 'PropagationSpeed', PropagationSpeed,...
    'CoordinateSystem', format ,'weights', w, ...
    'Type', plotType, 'PlotStyle', plotStyle);

% Find the weights
w = ones(getNumElements(myarray), length(Frequency));

format = 'uv';
plotType = 'Directivity';
plotStyle = 'Overlay';
figure;
pattern(myarray, Frequency, -1:0.01:1, 0, 'PropagationSpeed', PropagationSpeed,...
    'CoordinateSystem', format,'weights', w, ...
    'Type', plotType, 'PlotStyle', plotStyle);
