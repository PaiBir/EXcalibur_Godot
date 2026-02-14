class_name CLIMBER_X_ATMO
extends Node

#ADIFA
var atmosphere_parameters : ATM_PARAM
var atm_grid : ATM_GRID
var model_timer : MODELTIMER
var controller : CLIMBER_X_CONTROL

var pl : float
var zl : float

var Atm_CO2 : float #ppmv
var Equivalent_CO2 : float #ppmv
var Atm_CH4 : float #ppb
var Atm_N2O : float #ppb
var Atm_CFC11 : float #ppt
var Atk_CFC12 : float #ppt

#CRISA
var z_reference := 100.0 #meters, reference height

#Aspects from ATM_DEF
var Hadley_Cell_Width : float #radians
var InterTropicalConvergenceZone_Position : float #radians

var eccentricity : float
var precession : float
var obliquity : float

var t2m_glob_ann : float = 0
var dt2m_glob_ann_cum : float = 0

func sum(a,b):
	return a+b

##Adifa
func Flux():
	for j in (range(atm_grid.OutputArray.size())):
		var neighbors = []
		for tri in atm_grid.MeshTris:
			if (tri.find(j) != -1):
				if(neighbors.find(tri[0]) == -1):
					neighbors.append(tri[0])
				if(neighbors.find(tri[1]) == -1):
					neighbors.append(tri[1])
				if(neighbors.find(tri[2]) == -1):
					neighbors.append(tri[2])
		if(neighbors.find(j) != -1):
			neighbors.remove_at(neighbors.find(j))
		#Initialize flux arrays (Note: flux is stored on a per-neighbor basis)
		(atm_grid.OutputArray[j] as ATM_CELL).fa_energy = []
		(atm_grid.OutputArray[j] as ATM_CELL).fa_energy.resize(neighbors.size())
		(atm_grid.OutputArray[j] as ATM_CELL).fa_water = []
		(atm_grid.OutputArray[j] as ATM_CELL).fa_water.resize(neighbors.size())
		(atm_grid.OutputArray[j] as ATM_CELL).fa_dust = []
		(atm_grid.OutputArray[j] as ATM_CELL).fa_dust.resize(neighbors.size())
		(atm_grid.OutputArray[j] as ATM_CELL).fa_co2 = []
		(atm_grid.OutputArray[j] as ATM_CELL).fa_co2.resize(neighbors.size())
		(atm_grid.OutputArray[j] as ATM_CELL).fd_energy = []
		(atm_grid.OutputArray[j] as ATM_CELL).fd_energy.resize(neighbors.size())
		(atm_grid.OutputArray[j] as ATM_CELL).fd_water = []
		(atm_grid.OutputArray[j] as ATM_CELL).fd_water.resize(neighbors.size())
		(atm_grid.OutputArray[j] as ATM_CELL).fd_dust = []
		(atm_grid.OutputArray[j] as ATM_CELL).fd_dust.resize(neighbors.size())
		(atm_grid.OutputArray[j] as ATM_CELL).fd_co2 = []
		(atm_grid.OutputArray[j] as ATM_CELL).fd_co2.resize(neighbors.size())
		
		
		#Integrating fluxes vertically
		for k in range(atm_grid.km):
			var temperaturePotential_main := (atm_grid.OutputArray[j] as ATM_CELL).Temperature_Potential[k]
			var specific_humidity_main := (atm_grid.OutputArray[j] as ATM_CELL).Specific_Humidity[k]
			var dust_mass_ratio_main := (atm_grid.OutputArray[j] as ATM_CELL).Dust_Mass_Mixing[k]
			var c3_main := (atm_grid.OutputArray[j] as ATM_CELL).Cam
			var fa_main := (atm_grid.OutputArray[j] as ATM_CELL).fa[k]
			
			var temperaturePotential_neighbor := 0.0
			var specific_humidity_neighbor := 0.0
			var dust_mass_ratio_neighbor := 0.0
			var c3_neighbor := 0.0
			
			var tpup : float
			var qup : float
			var dup : float
			var cup : float
			
			for i in range(neighbors):
				temperaturePotential_neighbor = (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).Temperature_Potential[k]
				specific_humidity_neighbor = (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).Specific_Humidity[k]
				dust_mass_ratio_neighbor = (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).Dust_Mass_Mixing[k]
				c3_neighbor = (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).Cam
				
				##Advective flux
				#This is both zonal and meridional, because neighbors aren't following lines of latitude or longitude
				if(fa_main > 0):
					tpup = temperaturePotential_main
					qup = specific_humidity_main
					dup = dust_mass_ratio_main
					fa_main = c3_main
				else:
					tpup = temperaturePotential_neighbor
					qup = specific_humidity_neighbor
					dup = dust_mass_ratio_neighbor
					fa_main = c3_neighbor
				(atm_grid.OutputArray[j] as ATM_CELL).fa_energy[i] += (fa_main*tpup)
				(atm_grid.OutputArray[j] as ATM_CELL).fa_water[i] += (fa_main*qup)
				(atm_grid.OutputArray[j] as ATM_CELL).fa_dust[i] += (fa_main*dup)
				(atm_grid.OutputArray[j] as ATM_CELL).fa_co2[i] += (fa_main*cup)
				
				##Diffusive flux
				if(k<atm_grid.km-1):
					var dpl = atm_grid.dpl[j]
					(atm_grid.OutputArray[j] as ATM_CELL).fd_energy[i] = (atm_grid.OutputArray[j] as ATM_CELL).fd_energy[i] + (atm_grid.OutputArray[j] as ATM_CELL).diff_Energy * atm_grid.dy * dpl * (temperaturePotential_neighbor - temperaturePotential_main)/atm_grid.dxt #m2/s * K * kg/m2 = kg/s * K
					(atm_grid.OutputArray[j] as ATM_CELL).fd_water[i] = (atm_grid.OutputArray[j] as ATM_CELL).fd_water[i] + (atm_grid.OutputArray[j] as ATM_CELL).diff_Water * atm_grid.dy * dpl * (specific_humidity_neighbor - specific_humidity_main)/atm_grid.dxt
					(atm_grid.OutputArray[j] as ATM_CELL).fd_dust[i] = (atm_grid.OutputArray[j] as ATM_CELL).fd_dust[i] + (atm_grid.OutputArray[j] as ATM_CELL).diff_Dust * atm_grid.dy * dpl * (dust_mass_ratio_neighbor - dust_mass_ratio_main)/atm_grid.dxt
					(atm_grid.OutputArray[j] as ATM_CELL).fd_co2[i] = (atm_grid.OutputArray[j] as ATM_CELL).fd_co2[i] + (atm_grid.OutputArray[j] as ATM_CELL).diff_Dust * atm_grid.dy * dpl * (c3_neighbor - c3_main)/atm_grid.dxt
					#Skipping meridional diffusive flux calculations. While the calculations look different, the geodesic grid doesn't make it easy to handle the difference in shape.
		
		#I am not currently including the code to set the poles, because I don't need to worry about polar stuff being sent to the void. This might be an error, I don't know yet.
	
	for j in (range(atm_grid.OutputArray.size())):
		var neighbors : Array[int] = []
		for tri in atm_grid.MeshTris:
			if (tri.find(j) != -1):
				if(neighbors.find(tri[0]) == -1):
					neighbors.append(tri[0])
				if(neighbors.find(tri[1]) == -1):
					neighbors.append(tri[1])
				if(neighbors.find(tri[2]) == -1):
					neighbors.append(tri[2])
		if(neighbors.find(j) != -1):
			neighbors.remove_at(neighbors.find(j))
		var anti_neighbors = []
		for neighbor in neighbors:
			var an : Array[int] = []
			for tri in atm_grid.MeshTris:
				if (tri.find(neighbor) != -1):
					if(neighbors.find(tri[0]) == -1):
						an.append(tri[0])
					if(neighbors.find(tri[1]) == -1):
						an.append(tri[1])
					if(neighbors.find(tri[2]) == -1):
						an.append(tri[2])
			if(an.find(neighbor) != -1):
				an.remove_at(an.find(neighbor))
			anti_neighbors.append(an.find(j))
		
		if((atm_grid.OutputArray[j] as ATM_CELL).conv_energy.size() != neighbors.size()):
			(atm_grid.OutputArray[j] as ATM_CELL).conv_energy.resize(neighbors.size())
		if((atm_grid.OutputArray[j] as ATM_CELL).conv_water.size() != neighbors.size()):
			(atm_grid.OutputArray[j] as ATM_CELL).conv_water.resize(neighbors.size())
		if((atm_grid.OutputArray[j] as ATM_CELL).conv_dust.size() != neighbors.size()):
			(atm_grid.OutputArray[j] as ATM_CELL).conv_dust.resize(neighbors.size())
		if((atm_grid.OutputArray[j] as ATM_CELL).conv_co2.size() != neighbors.size()):
			(atm_grid.OutputArray[j] as ATM_CELL).conv_co2.resize(neighbors.size())
		
		(atm_grid.OutputArray[j] as ATM_CELL).conv_energy.fill(0)
		for i in range((atm_grid.OutputArray[j] as ATM_CELL).conv_water.size()):
			(atm_grid.OutputArray[j] as ATM_CELL).conv_water[i] = (0.9 * (atm_grid.OutputArray[j] as ATM_CELL).conv_water[i])
		(atm_grid.OutputArray[j] as ATM_CELL).conv_dust.fill(0)
		(atm_grid.OutputArray[j] as ATM_CELL).conv_co2.fill(0)
		for i in (range(neighbors.size())):
			(atm_grid.OutputArray[j] as ATM_CELL).conv_energy[i] += (((atm_grid.OutputArray[j] as ATM_CELL).fa_energy[i] - (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).fa_energy[anti_neighbors[i]]) + ((atm_grid.OutputArray[j] as ATM_CELL).fd_energy[i] - (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).fdenergy[anti_neighbors[i]])) / (atm_grid.OutputArray[i] as ATM_CELL).sqr * atmosphere_parameters.cp
			(atm_grid.OutputArray[j] as ATM_CELL).conv_water[i] += (0.1 * ((((atm_grid.OutputArray[j] as ATM_CELL).fa_water[i] - (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).fa_water[anti_neighbors[i]]) + ((atm_grid.OutputArray[j] as ATM_CELL).fd_water[i] - (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).fdwater[anti_neighbors[i]])) / (atm_grid.OutputArray[i] as ATM_CELL).sqr))
			(atm_grid.OutputArray[j] as ATM_CELL).conv_dust[i] += (((atm_grid.OutputArray[j] as ATM_CELL).fa_dust[i] - (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).fa_dust[anti_neighbors[i]]) + ((atm_grid.OutputArray[j] as ATM_CELL).fd_dust[i] - (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).fddust[anti_neighbors[i]])) / (atm_grid.OutputArray[i] as ATM_CELL).sqr
			(atm_grid.OutputArray[j] as ATM_CELL).conv_co2[i] += (((atm_grid.OutputArray[j] as ATM_CELL).fa_co2[i] - (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).fa_co2[anti_neighbors[i]]) + ((atm_grid.OutputArray[j] as ATM_CELL).fd_co2[i] - (atm_grid.OutputArray[neighbors[i]] as ATM_CELL).fd_CO2[anti_neighbors[i]])) / (atm_grid.OutputArray[i] as ATM_CELL).sqr

##Clouds
func Clouds():
	var cldlw : Array[float] = []
	for j in range(atm_grid.OutputArray.size()):
		(atm_grid.OutputArray[j] as ATM_CELL).fweff = tanh(atmosphere_parameters.c_Cloud[2] * (atm_grid.OutputArray[j] as ATM_CELL).weff)
		##Cloud Fraction
		#"near-surface relative humidity gradient, a measure of surface inversion"
		var dr : float = max(min((atm_grid.OutputArray[j] as ATM_CELL).Rskina - (atm_grid.OutputArray[j] as ATM_CELL).Extrapolated_Surface_Relative_Humidity, atmosphere_parameters.c_Cloud[6]), -atmosphere_parameters.c_Cloud[6])
		
		#Low clouds based on "surface inversion", "freezedry" reduction of cloud cover, based on a paper by Vavrus & Walliser (2008)
		var f_freezedry : float = min(0.1 + ((0.9 * (atm_grid.OutputArray[j] as ATM_CELL).Extrapolated_Surface_Specific_Humidity) / (atmosphere_parameters.c_Cloud[7] + 1e-20)), 1.0)
		#Cloud weight
		var fr : float = f_freezedry * (dr + atmosphere_parameters.c_Cloud[6]) / (2.0 * atmosphere_parameters.c_Cloud[6] + 1e-20)
		if (atmosphere_parameters.l_Cloud_low_ice):
			(atm_grid.OutputArray[j] as ATM_CELL).Cloud_Fraction_Low = atmosphere_parameters.c_Cloud[4] * fr * pow((atm_grid.OutputArray[j] as ATM_CELL).Extrapolated_Surface_Relative_Humidity, atmosphere_parameters.c_Cloud[5])
		else:
			(atm_grid.OutputArray[j] as ATM_CELL).Cloud_Fraction_Low = (1.0 - (atm_grid.OutputArray[j] as ATM_CELL).frst[(atm_grid.surfaceTypes.ICE as int)] ) * atmosphere_parameters.c_Cloud[4] * fr * pow((atm_grid.OutputArray[j] as ATM_CELL).Extrapolated_Surface_Relative_Humidity, atmosphere_parameters.c_Cloud[5])
		
		#large scale atmospheric relative humidity clouds
		(atm_grid.OutputArray[j] as ATM_CELL).Cloud_Fraction_RH = (atmosphere_parameters.c_Cloud[0]+atmosphere_parameters.c_Cloud[1]*(atm_grid.OutputArray[j] as ATM_CELL).fweff) * pow((atm_grid.OutputArray[j] as ATM_CELL).Extrapolated_Surface_Relative_Humidity, atmosphere_parameters.c_Cloud[3]) + atmosphere_parameters.c_Cloud[8] * max(0, (atm_grid.OutputArray[j] as ATM_CELL).sam2 - 20)
		
		##Cloud height
		(atm_grid.OutputArray[j] as ATM_CELL).Cloud_Height = (0.9 * (atm_grid.OutputArray[j] as ATM_CELL).Cloud_Height) + (0.1 * (max(min(atmosphere_parameters.c_Cloud[0] + atmosphere_parameters.c_Cloud[1] * (atm_grid.OutputArray[j] as ATM_CELL).Tropopause_Height * (1+atmosphere_parameters.c_Cloud[2]*((atm_grid.OutputArray[j] as ATM_CELL).wCloud-atmosphere_parameters.c_Cloud[3])), (atm_grid.OutputArray[j] as ATM_CELL).Tropopause_Height - 1e3), (atm_grid.OutputArray[j] as ATM_CELL).Surface + 2.5e3)))
		
		##Cloud Optical Thickness
		var tcldm : float = (atm_grid.OutputArray[j] as ATM_CELL).T2a - Constants.ZeroCelsius - atmosphere_parameters.c_CloudOpticalThickness[0]
		var ftemp : float = min(1.0, 1.0 + tanh(-tcldm / atmosphere_parameters.c_CloudOpticalThickness[1]))
		var clotl : float = min(10.0, atmosphere_parameters.c_CloudOpticalThickness[2] * ftemp * pow((atm_grid.OutputArray[j] as ATM_CELL).Cloud_Fraction * (atm_grid.OutputArray[j] as ATM_CELL).AtmosphericWaterContent, atmosphere_parameters.c_CloudOpticalThickness[3]))
		
		#account for sulfate aerosols
		if (atmosphere_parameters.l_so4_ie):
			##anthropogenic influence
			#m^-2
			var anthro_so4 : float = (atm_grid.OutputArray[j] as ATM_CELL).SO4_Load / (atmosphere_parameters.density_so4 * 4 / 3 * PI * pow(atmosphere_parameters.r_so4,3))
			#m^-3
			var N_anthro_so4 : float = anthro_so4 / atmosphere_parameters.height_so4
			#anthropogenic influence at cloud base (m^-3)
			var cloud_so4 : float = N_anthro_so4 * exp(-1) + atmosphere_parameters.N_so4_nat
			
			var f_mod = (1.0 - exp(-atmosphere_parameters.alpha_c * cloud_so4)) / (1 - exp(-atmosphere_parameters.alpha_c * atmosphere_parameters.N_so4_nat))
			
			clotl = clotl * pow(f_mod, 0.33)
			
		(atm_grid.OutputArray[j] as ATM_CELL).Cloud_Optical_Thickness = (0.1 * clotl) + (0.9 * (atm_grid.OutputArray[j] as ATM_CELL).Cloud_Optical_Thickness)
		cldlw.append((atm_grid.OutputArray[j] as ATM_CELL).Cloud_Fraction_Low)
	
	var smthed_cldlow = atm_grid.smooth_atm_mod.smooth2(cldlw,atm_grid.MeshTris,atmosphere_parameters.nsmooth_Cloud)
	
	for i in range(atm_grid.OutputArray.size()):
		(atm_grid.OutputArray[i] as ATM_CELL).Cloud_Fraction_Low = smthed_cldlow[i]
		var cldn = min(max(1 - (1 - (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Fraction_RH) * (1 - (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Fraction_Low), atmosphere_parameters.minimum_cloud_fraction), atmosphere_parameters.Cloud_max)
		(atm_grid.OutputArray[i] as ATM_CELL).Cloud_Fraction = (0.1 * cldn) + (0.9 * (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Fraction)

##Crisa
#Computation of the "cross-isobar angle", which I believe is basically the direction of change in the pressure level
func Crisa():
	var acbar_temp : Array[float] = []
	var acbar_sc_temp : Array[float] = []
	for i in range(atm_grid.OutputArray.size()):
		## Drag coefficient
		for n in range(5): #This number needs to be manually updated if more surface types are added
			if ((n as ATM_GRID.surfaceTypes) == atm_grid.surfaceTypes.OCEAN): #OCEAN
				(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient[n] = atmosphere_parameters.cd0_ocn
				(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_NoMountains[n] = atmosphere_parameters.cd0_ocn
			if ((n as ATM_GRID.surfaceTypes) == atm_grid.surfaceTypes.SIC): #SEA ICE
				(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient[n] = atmosphere_parameters.cd0_sic
				(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_NoMountains[n] = atmosphere_parameters.cd0_sic
			if ((n as ATM_GRID.surfaceTypes) == atm_grid.surfaceTypes.LAKE): #LAKE
				(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient[n] = atmosphere_parameters.cd0_ocn
				(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_NoMountains[n] = atmosphere_parameters.cd0_ocn
			else: #LAND OR ICE SHEET
				if ((atm_grid.OutputArray[i] as ATM_CELL).frst[n] > 0):
					(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient[n] = pow((Constants.karman/log(z_reference/((atm_grid.OutputArray[i] as ATM_CELL).Surface_Roughness[n] + (atm_grid.OutputArray[i] as ATM_CELL).Mountain_Roughness))),2)
					(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_NoMountains[n] = (Constants.karman/log(z_reference / (atm_grid.OutputArray[i] as ATM_CELL).Surface_Roughness[n]))
				else:
					(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient[n] = 0.01
					(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient[n] = 0.01
		
		#Grid cell average
		(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_Average = (atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient.reduce(sum,.0) * (atm_grid.OutputArray[i] as ATM_CELL).frst
		#Average without mountains (orography)
		(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_NoMountains_Average = (atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_NoMountains.reduce(sum,.0) * (atm_grid.OutputArray[i] as ATM_CELL).frst
		
		## The "Fun" part: Cross-Isobar Angles
		
		var rhs : float = 0
		if (atmosphere_parameters.i_acbar == 1):
			rhs = (atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_Average / sqrt(abs(max(abs(2 * (Constants.EarthAngularVelocity * atmosphere_parameters.Planet.DaysSpeed) * sin(PI * (-atm_grid.OutputArray[i].LatLong.y) / 180.0)),atmosphere_parameters.fcoramin)))
		elif (atmosphere_parameters.i_acbar == 2):
			rhs = ((atm_grid.OutputArray[i] as ATM_CELL).frst[(atm_grid.surfaceTypes.SIC as int)] * (atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_NoMountains_Average + (1-(atm_grid.OutputArray[i] as ATM_CELL).frst[(atm_grid.surfaceTypes.SIC as int)]) * (atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_Average) / sqrt(abs(max(abs(2 * (Constants.EarthAngularVelocity * atmosphere_parameters.Planet.DaysSpeed) * sin(PI * (-atm_grid.OutputArray[i].LatLong.y) / 180.0)),atmosphere_parameters.fcoramin)))
		
		var alfa := 0.0
		var alfa0 := 0.0
		var alfa1 := PI/4.0
		for j in range(10): #Don't know why 10
			alfa = 0.5*(alfa0 + alfa1)
			var rhsn = sin(alfa)/sqrt(1.0-sin(2.0*alfa))
			if (rhsn > rhs):
				alfa1 = alfa
			else:
				alfa0 = alfa
		alfa = min(max(alfa * atmosphere_parameters.acbar_scale, 0.05), atmosphere_parameters.acbar_max)
		(atm_grid.OutputArray[i] as ATM_CELL).Acbar = alfa
		(atm_grid.OutputArray[i] as ATM_CELL).sin_cos_Acbar = sin(alfa) * cos(alfa)
		
		acbar_temp.append(alfa)
		acbar_sc_temp.append(sin(alfa) * cos(alfa))
		
		#solving cross-isobar angle per surface
		for n in range(5): #Manually update if more surface types are added
			rhs = (atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient[n] / sqrt(abs(max(abs(2 * (Constants.EarthAngularVelocity * atmosphere_parameters.Planet.DaysSpeed) * sin(PI * (-atm_grid.OutputArray[i].LatLong.y) / 180.0)),atmosphere_parameters.fcoramin)))
			alfa0 = 0
			alfa1 = PI/4.0
			for j in range(10):
				alfa = 0.5*(alfa0 + alfa1)
				var rhsn = sin(alfa)/sqrt(1.0-sin(2.0*alfa))
				if (rhsn > rhs):
					alfa1 = alfa
				else:
					alfa0 = alfa
			alfa = min(max(alfa * atmosphere_parameters.acbar_scale, 0.05), atmosphere_parameters.acbar_max)
			(atm_grid.OutputArray[i] as ATM_CELL).cos_Acbar[n] = cos(alfa)
			(atm_grid.OutputArray[i] as ATM_CELL).sin_Acbar[n] = cos(alfa)
			(atm_grid.OutputArray[i] as ATM_CELL).epsa[n] = sqrt(1 - sin(2 * alfa))
	
	var sm_acbar = atm_grid.smooth_atm_mod.smooth2(acbar_temp,atm_grid.MeshTris,atmosphere_parameters.nsmooth_acbar)
	var sm_acbar_sc = atm_grid.smooth_atm_mod.smooth2(acbar_sc_temp,atm_grid.MeshTris,atmosphere_parameters.nsmooth_acbar)
	
	for i in range(atm_grid.OutputArray.size()):
		(atm_grid.OutputArray[i] as ATM_CELL).Acbar = sm_acbar[i]
		(atm_grid.OutputArray[i] as ATM_CELL).sin_cos_Acbar = sm_acbar_sc[i]

##Dust
func Dust():
	for i in range(atm_grid.OutputArray.size()):
		# Dust load
		var heff = (atm_grid.OutputArray[i] as ATM_CELL).Dust_Height_scale * atmosphere_parameters.atmosphere_scale / ((atm_grid.OutputArray[i] as ATM_CELL).Dust_Height_scale + atmosphere_parameters.atmosphere_scale)
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Load = (atm_grid.OutputArray[i] as ATM_CELL).Surface_Dust_Ratio
		
		#Dry and wet dust deposition
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Dry_Deposition = atmosphere_parameters.c_dust_dry / (atm_grid.OutputArray[i] as ATM_CELL).Dust_Height_scale * (atm_grid.OutputArray[i] as ATM_CELL).Dust_Load
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Wet_Deposition = atmosphere_parameters.c_dust_wet * (atm_grid.OutputArray[i] as ATM_CELL).Precipitation_Total * (atm_grid.OutputArray[i] as ATM_CELL).Dust_Load
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Deposition = (atm_grid.OutputArray[i] as ATM_CELL).Dust_Dry_Deposition + (atm_grid.OutputArray[i] as ATM_CELL).Dust_Wet_Deposition
		
		#Optical thickness
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Optical_Thickness = (atm_grid.OutputArray[i] as ATM_CELL).Dust_Load * atmosphere_parameters.c_dust_mec

##VESTA
#computation of lapse rate and height scales of moisture and dust
func hscales():
	for i in range(atm_grid.OutputArray.size()):
		#Lapse Rate
		var gs : Array[float] = []
		gs.resize(5)
		for n in range(5): #Manually set if the number of surfaces changes
			var dt : float = ((atm_grid.OutputArray[i] as ATM_CELL).Skin_Temp[n]-(atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Temp)
			if ((n as ATM_GRID.surfaceTypes) == atm_grid.surfaceTypes.OCEAN): #over ocean
				if dt > 0:
					gs[n] = (atmosphere_parameters.c_gam[3] * sqrt(dt))
				else:
					gs[n] = 10e-3 * dt
				gs[n] = max(min(atmosphere_parameters.gams_max_ocn,gs[n]),atmosphere_parameters.gams_min_ocn)
			elif ((n as ATM_GRID.surfaceTypes) == atm_grid.surfaceTypes.LAND): #over land
				if ((atm_grid.OutputArray[i] as ATM_CELL).frst[n] > 0):
					if (dt > 0):
						gs[n] = atmosphere_parameters.c_gam[4] * dt
					else:
						gs[n] = atmosphere_parameters.c_gam[5] * dt
					if ((atm_grid.OutputArray[i] as ATM_CELL).rb_sur > 50):
						gs[n] = max(5e-3,gs[n]) #minimum lapse rate over land when rb_sur > 30 W/m2
					gs[n] = max(min(atmosphere_parameters.gams_max_lnd,gs[n]), -atmosphere_parameters.gams_max_lnd)
				#If the ground is frozen, screw it I guess
			elif ((n as ATM_GRID.surfaceTypes) == atm_grid.surfaceTypes.LAKE): #over a lake
				var gsl = [0,0]
				if ((atm_grid.OutputArray[i] as ATM_CELL).frst[n] > 0): #icefree lakes are the same as the ocean 
					if dt > 0:
						gsl[0] = (atmosphere_parameters.c_gam[3] * sqrt(dt))
					else:
						gsl[0] = 10e-3 * dt
					gsl[0] = max(min(atmosphere_parameters.gams_max_ocn,gs[n]),atmosphere_parameters.gams_min_ocn)
				# icy lakes however, are the same as sea ice
				gsl[2] = max(min(atmosphere_parameters.c_gam[4]*dt, atmosphere_parameters.gams_max_lnd), -atmosphere_parameters.gams_max_lnd)
				gs[n] = (1.0-(atm_grid.OutputArray[i] as ATM_CELL).f_ice_lake) * gsl[0] + ((atm_grid.OutputArray[i] as ATM_CELL).f_ice_lake * gsl[1])
		var gam_s

#vertical structure
func vesta():
	pass

#compute vertical temperature profile
func t_proof():
	pass

#compute vertical relative humidity profile
func rh_proof():
	pass

#compute height of tropopause
func tropo_height():
	pass
