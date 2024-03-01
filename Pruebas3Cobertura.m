viewer = siteviewer("Buildings","EstadioSiles.osm","Basemap","topographic");

tx = txsite("Name","Small cell transmitter", ...
    "Latitude",-16.50060, ...
    "Longitude",-68.12302, ...
    "AntennaHeight",10, ...
    "TransmitterPower",2, ...
    "TransmitterFrequency", 3.5e9);
show(tx)

coverage(tx, ...
    "SignalStrengths",-120:-5, ...
    "MaxRange",250, ...
    "Resolution",3, ...
    "Transparency",0.6)
