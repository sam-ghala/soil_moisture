Variables stored in separate files (Header+values)

Filename

	Data_separate_files_header_startdate(YYYYMMDD)_enddate(YYYYMMDD)_userid_randomstring_currrentdate(YYYYMMDD).zip
	
	e.g., Data_separate_files_header_20050316_20050601.zip

	
Folder structure

	Networkname
		Stationname

		
Dataset Filename

	CSE_Network_Station_Variablename_depthfrom_depthto_startdate_enddate.ext

	CSE	- Continental Scale Experiment (CSE) acronym, if not applicable use Networkname
	Network	- Network abbreviation (e.g., OZNET)
	Station	- Station name (e.g., Widgiewa)
	Variablename - Name of the variable in the file (e.g., Soil-Moisture)
	depthfrom - Depth in the ground in which the variable was observed (upper boundary)
	depthto	- Depth in the ground in which the variable was observed (lower boundary)
	startdate -	Date of the first dataset in the file (format YYYYMMDD)
	enddate	- Date of the last dataset in the file (format YYYYMMDD)
	ext	- Extension .stm (Soil Temperature and Soil Moisture Data Set see CEOP standard)
	
	e.g., OZNET_OZNET_Widgiewa_Soil-Temperature_0.150000_0.150000_20010103_20090812.stm

	
File Content Sample
	
	REMEDHUS   REMEDHUS        Zamarron          41.24100    -5.54300  855.00    0.05    0.05  (Header)
	2005/03/16 00:00    10.30 U	M	(Records)
	2005/03/16 01:00     9.80 U M

	
Header

	CSE Identifier - Continental Scale Experiment (CSE) acronym, if not applicable use Networkname
	Network	- Network abbreviation (e.g., OZNET)
	Station	- Station name (e.g., Widgiewa)
	Latitude - Decimal degrees. South is negative.
	Longitude - Decimal degrees. West is negative.
	Elevation - Meters above sea level
	Depth from - Depth in the ground in which the variable was observed (upper boundary)
	Depth to - Depth in the ground in which the variable was observed (lower boundary)

	
Record

	UTC Actual Date and Time
	yyyy/mm/dd HH:MM
	Variable Value
	ISMN Quality Flag
	Data Provider Quality Flag, if existing


Network Information

	Berlin
		Abstract: 
		Continent: Europe
		Country: Germany
		Stations: 23
		Status: running
		Data Range: from 2022-12-01 
		Type: campaign
		Url: 
		Reference: We acknowledge the work of Martin Schreiner and the Berlin network team in support of the ISMN;
		Variables: soil moisture, soil temperature, 
		Soil Moisture Depths: 0.05 - 0.05 m, 0.15 - 0.15 m, 0.25 - 0.25 m, 0.35 - 0.35 m, 0.45 - 0.45 m, 0.55 - 0.55 m, 0.65 - 0.65 m, 0.75 - 0.75 m, 0.85 - 0.85 m
		Soil Moisture Sensors: TriScan Drill&Drop, 

	DWD
		Abstract: The soil-physical boundary conditions of the soil moisture probes used were determined for the individual sites during installation by means of simple soil sampling and finger tests on the basis of the Soil Science Mapping Guide (KA 5). At present, however, calibration sampling is still being carried out at the sites and, in the future, site-specific soil physics laboratory tests are also planned. The measured values should therefore be regarded and used as preliminary raw data, particularly with regard to the absolute level.


************************************************************************************************************
Die bodenphysikalischen Randbedingungen der eingesetzten Bodenfeuchtesonden sind für die einzelnen Standorte beim Einbau durch einfache Bodenansprachen und Fingerproben auf der Basis der Bodenkundlichen Kartieranleitung (KA 5) festgelegt worden. Derzeit werden an den Standorten aber noch Kalibrierbeprobungen vorgenommen und perspektivisch sind auch standörtliche bodenphysikalische Laboruntersuchungen geplant. Die Messwerte sollten deshalb insbesondere bezüglich des absoluten Niveaus als vorläufige Rohdaten betrachtet und verwendet werden.
		Continent: Europe
		Country: Germany
		Stations: 20
		Status: operational
		Data Range: from 2024-01-01 
		Type: continous measuring network
		Url: 
		Reference: We acknowledge the work of the DWD and its agrometeorological team for their contributions in support of the ISMN
		Variables: precipitation, soil moisture, soil temperature, 
		Soil Moisture Depths: 0.05 - 0.05 m, 0.15 - 0.15 m, 0.25 - 0.25 m, 0.35 - 0.35 m, 0.45 - 0.45 m, 0.55 - 0.55 m, 0.65 - 0.65 m, 0.75 - 0.75 m, 0.85 - 0.85 m
		Soil Moisture Sensors: Sentek Drill and drop, 

	FR_Aqui
		Abstract: The Fr_Aqui network is located in France and hosted by the Institue of Agricultural Research (INRA); it consists of 5 stations with soil moisture and soil temperature measurements in 6 different  depths.
		Continent: Europe
		Country: France
		Stations: 5
		Status: running
		Data Range: from 2010-01-01 
		Type: meteo
		Url: 
		Reference: Al-Yaari, A., Dayau, S., Chipeaux, C., Aluome, C., Kruszewski, A., Loustau, D. & Wigneron, J.-P. (2018), ‘The aqui soil moisture network for satellite microwave remote sensing validation in south-western france’, Remote Sensing 10(11), https://doi.org/10.3390/rs10111839;

Wigneron, J.-P., Dayan, S., Kruszewski, A., Aluome, C., Al-Yaari, A., Fan, L., Guven, S., Chipeaux, C., Moisy, C., Guyon, D. & Loustau, D. (2018), The aqui network: Soil moisture sites in the “les landes” forest and graves vineyards (bordeaux aquitaine region, france), pp. 3739–3742., https://doi.org/10.1109/IGARSS.2018.8517392;
		Variables: soil moisture, soil temperature, 
		Soil Moisture Depths: 0.01 - 0.01 m, 0.03 - 0.03 m, 0.05 - 0.05 m, 0.10 - 0.10 m, 0.15 - 0.15 m, 0.20 - 0.20 m, 0.21 - 0.21 m, 0.25 - 0.25 m, 0.30 - 0.30 m, 0.34 - 0.34 m, 0.40 - 0.40 m, 0.45 - 0.45 m, 0.50 - 0.50 m, 0.55 - 0.55 m, 0.56 - 0.56 m, 0.70 - 0.70 m, 0.80 - 0.80 m, 0.90 - 0.90 m
		Soil Moisture Sensors: ThetaProbe ML2X, 

	REMEDHUS
		Abstract: 
		Continent: Europe
		Country: Spain
		Stations: 24
		Status: running
		Data Range: from 2005-01-01 
		Type: project
		Url: http://campus.usal.es/~hidrus/
		Reference: Gonzalez-Zamora, A., Sanchez, N., Pablos, M. & Martinez-Fernandez, J. (2018), ‘Cci soil moisture assessment with smos soil moisture and in situ data under different environmental conditions and spatial scales in spain’, Remote Sensing of Environment 225, https://doi.org/10.1016/j.rse.2018.02.010;
		Variables: soil temperature, soil moisture, 
		Soil Moisture Depths: 0.00 - 0.05 m
		Soil Moisture Sensors: Stevens Hydra Probe, 

	RSMN
		Abstract: The project proposal aims at paving the way for the utilisation of satellite derived soil moisture products in Romania, creating the framework for the validation and evaluation of actual & future satellite microwave soil moisture derived products, demonstrating its value, and by developing the necessary expertise for successfuly approaching implementations in the Societal Benefit Areas (as they were defined in GEOSS)

		Continent: Europe
		Country: Romania
		Stations: 20
		Status: running
		Data Range: from 2014-04-09 
		Type: meteo
		Url: http://assimo.meteoromania.ro
		Reference: We acknowledge the work of Andrei Diamandi and Adelina Mihai and the Romanian National Meteorological Administration team in support of the ISMN;
		Variables: air temperature, precipitation, soil moisture, soil temperature, 
		Soil Moisture Depths: 0.00 - 0.05 m
		Soil Moisture Sensors: 5TM, 

	SMOSMANIA
		Abstract: 
		Continent: Europe
		Country: France
		Stations: 22
		Status: running
		Data Range: from 2003-01-01 
		Type: project
		Url: http://www.hymex.org
		Reference: Calvet, J.-C., Fritz, N., Berne, C., Piguet, B., Maurel, W. & Meurey, C. (2016), ‘Deriving pedotransfer functions for soil quartz fraction in southern france from reverse modeling’, SOIL 2(4), 615–629, https://doi.org/10.5194/soil-2-615-2016;

Albergel, C., Rüdiger, C., Pellarin, T., Calvet, J.-C., Fritz, N., Froissard, F., Suquia, D., Petitpa, A., Piguet, B., and Martin, E.: From near-surface to
root-zone soil moisture using an exponential filter: an assessment of the method based
on insitu observations and model simulations, Hydrol. Earth Syst. Sci., 12, 1323–1337, 2008, https://doi.org/10.5194/hess-12-1323-2008;

Calvet, J.-C., Fritz, N., Froissard, F., Suquia, D., Petitpa, A., and Piguet, B.: In situ soil moisture observations for the CAL/VAL of SMOS: the SMOSMANIA network, International Geoscience and Remote Sensing Symposium, IGARSS, Barcelona, Spain, 23-28 July 2007, 1196-1199, https://doi.org/10.1109/IGARSS.2007.4423019, 2007.;
		Variables: soil moisture, soil temperature, 
		Soil Moisture Depths: 0.05 - 0.05 m, 0.10 - 0.10 m, 0.20 - 0.20 m, 0.30 - 0.30 m
		Soil Moisture Sensors: ThetaProbe ML2X, ThetaProbe ML3, 

	STEMS
		Abstract: Soil Moisture Network installed in rainfed vineyard plots, with different inter-rows soil management. The plots are also monitored for runoff and soil erosion. Weather data available from a station near the plots.
		Continent: Europe
		Country: Italy
		Stations: 11
		Status: running
		Data Range: from 2015-12-04 
		Type: campaign
		Url: https://sustag.to.cnr.it/index.php/cannona-db
		Reference: Darouich, H., Ramos, T.B., Pereira, L.S., Rabino, D., Bagagiolo, G., Capello, G., Simionesei, L., Cavallo, E., Biddoccu, M. Water Use and Soil Water Balance of Mediterranean Vineyards under Rainfed and Drip Irrigation Management: Evapotranspiration Partition and Soil Management Modelling for Resource Conservation. Water 2022, 14, 554. https://doi.org/10.3390/w14040554;

Capello G, Biddoccu M, Ferraris S, Cavallo E, 2019. Effects of tractor passes on hydrological and soil erosion processes in tilled and grassed vineyards. Water 2019, 11(10), 2118, https://doi.org/10.3390/w11102118;
		Variables: air temperature, precipitation, soil moisture, soil temperature, 
		Soil Moisture Depths: 0.10 - 0.10 m, 0.20 - 0.20 m, 0.30 - 0.30 m, 0.40 - 0.40 m, 0.50 - 0.50 m
		Soil Moisture Sensors: 5TM, EC5, HD3910.1.5, 

	TERENO
		Abstract: Soil moisture network in Germany, There are 4 observatories: in Northeastern Germany- Lowlan Observatory coordinated by German Research Centre of Geosciences, in Harz/Central Germany-  Lowland Observatory coordinated by Helmholtz Centre for Environmental Research, in Eifel/Lower Rhine Valley- Observatory coordinated by Research Centre Juelich and in Bavarian Alps/pre-Alps- Obervatory coordinated by Karlsruhe Institute of Technology and German Center for Environmental Health
		Continent: Europe
		Country: Germany
		Stations: 5
		Status: running
Data Range: 

		Type: meteo
		Url: https://www.tereno.net/joomla/index.php/overview
		Reference: Bogena, H.R., Montzka, C., Huisman, J.A., Graf, A., Schmidt, M., Stockinger, M., Von Hebel, C., Hendricks-Franssen, H.J., Van der Kruk, J., Tappe, W. and Lücke, A., 2018. The TERENO‐Rur hydrological observatory: A multiscale multi‐compartment research platform for the advancement of hydrological science. Vadose Zone Journal, 17(1), pp.1-22, https://doi.org/10.2136/vzj2018.03.0055;

Bogena, H. R. (2016), ‘Tereno: German network of terrestrial environmental observatories’, Journal of large-scale research facilities JLSRF 2, 52, http://dx.doi.org/10.17815/jlsrf-2-98;

Bogena, H., Kunkel, R., Puetz, T., Vereecken, H., Krueger, E., Zacharias, S., Dietrich, P., Wollschlaeger, U., Kunstmann, H., Papen, H. and Schmid, H.P., 2012. Tereno-long-term monitoring network for terrestrial environmental research. Hydrologie und Wasserbewirtschaftung, 56(3), pp.138-143, https://doi.org/DOI:%10.5675;

Zacharias, S., H.R. Bogena, L. Samaniego, M. Mauder, R. Fuß, T. Pütz, M. Frenzel, M. Schwank, C. Baessler, K. Butterbach-Bahl, O. Bens, E. Borg, A. Brauer, P. Dietrich, I. Hajnsek, G. Helle, R. Kiese, H. Kunstmann, S. Klotz, J.C. Munch, H. Papen, E. Priesack, H. P. Schmid, R. Steinbrecher, U. Rosenbaum, G. Teutsch, H. Vereecken. 2011. A Network of Terrestrial Environmental Observatories in Germany. Vadose Zone J. 10. 955–973, https://doi.org/10.2136/vzj2010.0139;
		Variables: air temperature, precipitation, soil moisture, soil temperature, 
		Soil Moisture Depths: 0.05 - 0.05 m, 0.20 - 0.20 m, 0.50 - 0.50 m
		Soil Moisture Sensors: Hydraprobe II Sdi-12, 

	WEGENERNET
		Abstract: The WegenerNet Feldbach Region is a unique weather and climate observation network comprising more than 150 hydrometeorological stations measuring temperature, humidity, precipitation, and at 14 locations also wind speed and direction. Soil moisture and soil temperature are measured at 12 stations, which are part of the International Soil Moisture Network (ISMN). 


The stations are located in a tightly spaced grid within a core area of 22 km x 16 km centered near the city of Feldbach in southeastern Austria.
With about one station every two square-km (area of about 300 square-km in total), and each station with 5-min time sampling, the network provides fully automated regular measurements since January 2007.


************************************************************************************************************
IMPORTANT NOTE: All data is on version 8.0 For further details please see https://wegenernet.org/downloads/Fuchsberger-etal_2023_WPSv8-release-notes.pdf

************************************************************************************************************

		Continent: Europe
		Country: Austria
		Stations: 13
		Status: running
		Data Range: from 2007-01-01 
		Type: project
		Url: http://www.wegenernet.org/;http://www.wegcenter.at/wegenernet
		Reference: Fuchsberger, J., Kirchengast, G. & Kabas, T. (2021), WegenerNet high-resolution weather and climate data from 2007 to 2020, Earth Syst. Sci. Data, 13, 1307–1334, https://doi.org/10.5194/essd-13-1307-2021, 2021;

Kirchengast, G., Kabas, T., Leuprecht, A., Bichler, C. & Truhetz, H. (2014), ‘Wegenernet: A pioneering high-resolution network for monitoring weather and climate’, Bulletin of the American Meteorological Society 95, https://doi.org/10.1175/BAMS-D-11-00161.1;
		Variables: air temperature, precipitation, soil moisture, soil temperature, 
		Soil Moisture Depths: 0.20 - 0.20 m, 0.30 - 0.30 m
		Soil Moisture Sensors: Hydraprobe II, Hydraprobe Professional, pF-Meter, 

	XMS-CAT
		Abstract: The soil monitoring network is a set of stations with continuous data recording of physics parameters (temperature and moisture of soil) and environmental parameters such as pluviometry, temperature, relative air humidity and solar radiation. Project started at Tremp basin’s, in the crops of vineyards, and it has been continued in high altitude vineyard form Pre-pyrenees and Pyrenees. The main features that set up the stations are the sensors installed into the soils and the basic operation elements, such as the acquisition data system, the power system and the data transmission system. Generally, there are 4 multi parametric sensors to 5, 20, 50 and 100 cm of depth, when parent material allows it, these sensors measure soil moisture and temperature. Each station also has environmental sensors such as a rain gauge, a pyranometer and a air temperature and relative humidity probes for the necessary comparison of the soil and environmental parameters.
		Continent: Europe
		Country: Spain
		Stations: 20
		Status: running
		Data Range: from 2016-08-01 
		Type: project
		Url: https://visors.icgc.cat/mesurasols/#9/42.1765/1.1132
		Reference: We acknowledge the work of Agnès Lladós and Lola Boquera as well as the XMS-CAT network team in support of the ISMN.
		Variables: air temperature, precipitation, soil moisture, soil temperature, 
		Soil Moisture Depths: 0.05 - 0.05 m, 0.10 - 0.10 m, 0.20 - 0.20 m, 0.30 - 0.30 m, 0.40 - 0.40 m, 0.50 - 0.50 m, 0.60 - 0.60 m, 0.70 - 0.70 m, 0.75 - 0.75 m, 1.00 - 1.00 m
		Soil Moisture Sensors: CS655, DeltaOHM, SoilVUE10, 

