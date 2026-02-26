class_name CLIMBER_X_ATMO
extends Node

#ADIFA
var atmosphere_parameters : ATM_PARAM
var atm_grid : ATM_GRID
var model_timer : MODELTIMER
var controller : CLIMBER_X_CONTROL

var Atm_CO2 : float #ppmv
var Equivalent_CO2 : float #ppmv
var Atm_CH4 : float #ppb
var Atm_N2O : float #ppb
var Atm_CFC11 : float #ppt
var Atk_CFC12 : float #ppt

#CRISA
var z_reference := 100.0 #meters, reference height

#VESTA
var hrs_min : float = 1e3
var hrs_max : float = 10e3

#SHORT-WAVE RADIATION
var p_sw : Array[float] = [-1.97, 0.82, 0.35, 0.67]
var alf_sw : Array[float] = [7.73e-2, 2.39e-2, 1.51e2]
var gam_ar_sw : Array[float] = [2.75,0.636]
var gl_c_sw : float = 0.14
var cld_gt : float = 1000
var c_itf_o = 0.98

#Aspects from ATM_DEF
var Hadley_Cell_Width : float #radians
var InterTropicalConvergenceZone_Position : float #radians

var eccentricity : float
var precession : float
var obliquity : float

var t2m_glob_ann : float = 0
var dt2m_glob_ann_cum : float = 0

func sum(a : Array,b : Array, o : int) -> float: #o = 0: addition, o = 1: subtraction, o = 2: multiplication, o = 3: division
	var total : float = 0
	for i in range(a.size()):
		if o == 0:
			total += (a[i] + b[i])
		elif o == 1:
			total += (a[i] - b[i])
		elif o == 2:
			total += (a[i] * b[i])
		elif o == 3:
			total += (a[i] / b[i])
	return total


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
		for n in range(atm_grid.numSurfaceTypes):
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
		(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_Average = sum((atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient, (atm_grid.OutputArray[i] as ATM_CELL).frst, 2)
		#Average without mountains (orography)
		(atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_NoMountains_Average = sum((atm_grid.OutputArray[i] as ATM_CELL).Drag_Coefficient_NoMountains, (atm_grid.OutputArray[i] as ATM_CELL).frst, 2)
		
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
		for n in range(atm_grid.numSurfaceTypes):
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
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Load = (atm_grid.OutputArray[i] as ATM_CELL).Surface_Dust_Ratio * heff * (atm_grid.OutputArray[i] as ATM_CELL).ra_2_Average
		
		#Dry and wet dust deposition
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Dry_Deposition = atmosphere_parameters.c_dust_dry / (atm_grid.OutputArray[i] as ATM_CELL).Dust_Height_scale * (atm_grid.OutputArray[i] as ATM_CELL).Dust_Load
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Wet_Deposition = atmosphere_parameters.c_dust_wet * (atm_grid.OutputArray[i] as ATM_CELL).Precipitation_Total * (atm_grid.OutputArray[i] as ATM_CELL).Dust_Load
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Deposition = (atm_grid.OutputArray[i] as ATM_CELL).Dust_Dry_Deposition + (atm_grid.OutputArray[i] as ATM_CELL).Dust_Wet_Deposition
		
		#Optical thickness
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Optical_Thickness = (atm_grid.OutputArray[i] as ATM_CELL).Dust_Load * atmosphere_parameters.c_dust_mec

##VESTA
#computation of lapse rate and height scales of moisture and dust
func hscales():
	var gam_s : Array[float] = []
	var gam_b : Array[float] = []
	var gam_t : Array[float] = []
	for i in range(atm_grid.OutputArray.size()):
		#Lapse Rate
		var gs : Array[float] = []
		gs.resize(atm_grid.numSurfaceTypes)
		for n in range(atm_grid.numSurfaceTypes):
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
		gam_s.append(sum(gs, (atm_grid.OutputArray[i] as ATM_CELL).frst, 2))
		#Bottom
		gam_b.append(atmosphere_parameters.c_gam[0] - atmosphere_parameters.c_gam[1] * (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Specific_Humidity)
		#Top
		gam_t.append((atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Lower_Tropo - atmosphere_parameters.c_gam[1] * (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Specific_Humidity + atmosphere_parameters.c_gam[2])
		
		#Height scale for relative humidity
		var fi : float = max(min(atmosphere_parameters.c_hrs[5] * ((PI * (-(atm_grid.OutputArray[i] as ATM_CELL).LatLong.y) / 180.0) - InterTropicalConvergenceZone_Position) / (0.5 * Hadley_Cell_Width), PI/2.0), -PI/2.0)
		var f_trop : float = 1-sin(fi)
		var hrs : float = min(max(f_trop * atmosphere_parameters.c_hrs[0] * exp(atmosphere_parameters.c_hrs1 * (atm_grid.OutputArray[i] as ATM_CELL).wCloud) + (1-f_trop) * atmosphere_parameters.c_hrs[0] * atmosphere_parameters.c_hrs[2], hrs_min), hrs_max)
		(atm_grid.OutputArray[i] as ATM_CELL).Vertical_Humidity_Scale = (0.9 * (atm_grid.OutputArray[i] as ATM_CELL).Vertical_Humidity_Scale) + (0.1 * hrs)
		
		(atm_grid.OutputArray[i] as ATM_CELL).Vertical_Effective_Humidity_Scale = (atm_grid.OutputArray[i] as ATM_CELL).AtmosphericWaterContent / ((atm_grid.OutputArray[i] as ATM_CELL).ra_2_Average * (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Specific_Humidity)
		
		(atm_grid.OutputArray[i] as ATM_CELL).Dust_Height_scale = atmosphere_parameters.c_dhs_1 + atmosphere_parameters.c_dhs_2 * (atm_grid.OutputArray[i] as ATM_CELL).wCloud

	gam_s = atm_grid.smooth_atm_mod.smooth2(gam_s, atm_grid.MeshTris, atmosphere_parameters.nsmooth_gam)
	gam_b = atm_grid.smooth_atm_mod.smooth2(gam_b, atm_grid.MeshTris, atmosphere_parameters.nsmooth_gam)
	gam_t = atm_grid.smooth_atm_mod.smooth2(gam_t, atm_grid.MeshTris, atmosphere_parameters.nsmooth_gam)
	
	for i in range(atm_grid.OutputArray.size()):
		(atm_grid.OutputArray[i] as ATM_CELL).LapseRate_BoundaryLayer = atmosphere_parameters.c_gam_rel * gam_s[i] + (1.0 - atmosphere_parameters.c_gam_rel) * gam_s[i]
		(atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Lower_Tropo = atmosphere_parameters.c_gam_rel * gam_b[i] + (1.0 - atmosphere_parameters.c_gam_rel) * gam_b[i]
		(atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Upper_Tropo = atmosphere_parameters.c_gam_rel * gam_t[i] + (1.0 - atmosphere_parameters.c_gam_rel) * gam_t[i]

#vertical structure
func vesta():
	
	for i in range(atm_grid.OutputArray.size()):
		#2D fields
		var z_sur : float = (atm_grid.OutputArray[i] as ATM_CELL).Surface
		var taml : float = (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Temp
		var gamsl : float = (atm_grid.OutputArray[i] as ATM_CELL).LapseRate_BoundaryLayer
		var gambl : float = (atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Lower_Tropo
		var gamtl : float = (atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Upper_Tropo
		var htropl : float = (atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Height
		var rsur : float = (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Relative_Humidity
		var hrml : float = (atm_grid.OutputArray[i] as ATM_CELL).Vertical_Humidity_Scale
		
		#3D fields
		var wconl : float = 0
		var t : float = 0
		var flag_strat : bool = false
		for k in range(atm_grid.km):
			var z : float = 0.5 * (atm_grid.zl[k])
			var rh : float = 0
			var qsat : float = 0
			var q : float = 0
			if (!flag_strat):
				#Construct a vertical temperature profile
				t = t_prof(z_sur, z, taml, gamsl, gambl, gamtl, htropl, 1)
				#Derive specific humidity from temperature and relative humidity
				rh = rh_prof(z_sur, z, rsur, hrml, htropl)
				qsat = Constants.FQSAT_sp(t, (atm_grid.OutputArray[i] as ATM_CELL).Pressure_At_Surface * atm_grid.exp_zc[k])
				q = rh * qsat
			
			# vertical for water content
			if (atm_grid.zl[k] > z_sur):
				wconl = wconl + q * atmosphere_parameters.ra * atm_grid.exp_zc[k] * (atm_grid.zl[k+1]-atm_grid.zl[k])
			elif ((atm_grid.zl[k] < z_sur) and (atm_grid.zl[k + 1] > z_sur)):
				wconl = wconl + q * atmosphere_parameters.ra * atm_grid.exp_zc[k] * (atm_grid.zl[k+1] - z_sur)
			
			(atm_grid.OutputArray[i] as ATM_CELL).Temperature[k] = t
			(atm_grid.OutputArray[i] as ATM_CELL).Specific_Humidity[k] = q
			
			(atm_grid.OutputArray[i] as ATM_CELL).Temperature_Potential[k] = t + atmosphere_parameters.gad * min(z, atmosphere_parameters.zmax)
			
			if (controller.flagDust):
				(atm_grid.OutputArray[i] as ATM_CELL).Dust_Mass_Mixing[k] = (atm_grid.OutputArray[i] as ATM_CELL).Surface_Dust_Ratio * min(1,exp(-(z-z_sur) / (atm_grid.OutputArray[i] as ATM_CELL).Dust_Height_scale))
			
			if (z > htropl):
				flag_strat = true
		
		(atm_grid.OutputArray[i] as ATM_CELL).AtmosphericWaterContent = wconl
		
		(atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Temperature = t

#compute vertical temperature profile
func t_prof(zs : float, z : float, tam : float, gams : float, gamb : float, gamt : float, htrop : float, iflag : int) -> float:
	
	var return_t_prof : float = 0
	
	var zk : float = min(z,htrop)
	
	if (iflag == 0):
		#Ignore the surface (screw the surface)
		
		return_t_prof = tam - gamb * (zk - zs) - (gamt - gamb) * (pow(zk, 2) - pow(zs, 2)) / (2 * atmosphere_parameters.hgamt)
	
	else:
		#Use the surface (we like the surface)
		if (zk < zs):
			#Below surface
			return_t_prof = tam - gamb * (zk - zs) - (gamt - gamb) * (pow(zk, 2) - pow(zs, 2)) / (2 * atmosphere_parameters.hgamt)
		elif (zk > (zs+atmosphere_parameters.hgams)):
			#Above boundary layer
			return_t_prof = tam - (gams*atmosphere_parameters.hgams) - (gamt - gamb) * (pow(zk, 2) - pow(zs, 2)) / (2 * atmosphere_parameters.hgamt)
		else:
			#Just right
			return_t_prof = tam - gams * (zk - zs) - (gamt - gamb) * (pow(zk, 2) - pow(zs, 2)) / (2 * atmosphere_parameters.hgamt)
	
	return return_t_prof

#compute vertical relative humidity profile
func rh_prof(zs : float, z : float, ram : float, h_rh : float, htrop : float) -> float:
	
	var return_rh_prof : float = 0
	
	var z_pbl : float = zs+atmosphere_parameters.c_hrs[4]
	
	if (z < z_pbl):
		return_rh_prof = ram
	elif ((z>z_pbl) and (z<(zs+atmosphere_parameters.c_hrs[3]))):
		return_rh_prof = ram * exp(-(z-z_pbl) / h_rh)
	elif ((z>(zs + atmosphere_parameters.c_hrs[3])) and (z<(htrop+1))):
		return_rh_prof = ram * exp(-(z-atmosphere_parameters.c_hrs[3]-z_pbl) / h_rh)
	else:
		return_rh_prof = atmosphere_parameters.rh_strat
	
	return return_rh_prof

#compute height of tropopause
func tropo_height():
	#Don't know why these values are what they are
	var x1 = asin(pow(0.1,1.0/8.0))
	var h_trop_min = 6e3
	var h_trop_max = 25e3
	for i in range(atm_grid.OutputArray.size()):
		var fic : float = Hadley_Cell_Width/2
		var x : float = x1-fic
		var fi : float = x * ((PI * (-(atm_grid.OutputArray[i] as ATM_CELL).LatLong.y) / 180.0) - InterTropicalConvergenceZone_Position)
		if (fi > PI/2.0):
			fi = PI/2.0
		elif (fi < -PI/2.0):
			fi = -PI/2.0
		var sheat : float = atmosphere_parameters.c_trop[1] * (1 - atmosphere_parameters.c_trop[2] * (1 - pow(sin(fi), 8)))
		(atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Pressure = 0
		var rbstr : float = (atm_grid.OutputArray[i] as ATM_CELL).rb_str + sheat
		var dhtrop = -atmosphere_parameters.c_trop[0] * rbstr 
		var htropp = min(max(max((atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Height + dhtrop),h_trop_min,(atm_grid.OutputArray[i] as ATM_CELL).Cloud_Height), h_trop_max)
		
		(atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Height = htropp
		
		#I have left a variable out of this equation as I currently don't have a way to supply it. Will see how that affects output.
		(atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Pressure = (atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Pressure + exp(-(atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Height / atmosphere_parameters.atmosphere_scale)

##Wvel
#vertical velocities for parameterisations
func wvel(wind : Array[float]):
	var t_wcld : Array[float] = []
	var t_woro : Array[float] = []
	var t_weff : Array[float] = []
	for i in range(atm_grid.OutputArray.size()):
		t_wcld.append((atm_grid.OutputArray[i] as ATM_CELL).w3[(atm_grid.OutputArray[i] as ATM_CELL).K_Index_Effective])
		t_woro.append(atmosphere_parameters.c_woro * wind[i] * (atm_grid.OutputArray[i] as ATM_CELL).sigoro)
		t_weff.append((atm_grid.OutputArray[i] as ATM_CELL).w3[(atm_grid.OutputArray[i] as ATM_CELL).K_Index_Effective] + atmosphere_parameters.c_weff * ((atm_grid.OutputArray[i] as ATM_CELL).Synoptic_Wind + (atm_grid.OutputArray[i] as ATM_CELL).woro))
	t_wcld = atm_grid.smooth_atm_mod.smooth2(t_wcld,atm_grid.MeshTris,atmosphere_parameters.nsmooth_weff)
	t_woro = atm_grid.smooth_atm_mod.smooth2(t_woro,atm_grid.MeshTris,atmosphere_parameters.nsmooth_weff)
	t_weff = atm_grid.smooth_atm_mod.smooth2(t_weff,atm_grid.MeshTris,atmosphere_parameters.nsmooth_weff)
	for i in range(atm_grid.OutputArray.size()):
		(atm_grid.OutputArray[i] as ATM_CELL).wCloud = t_wcld[i]
		(atm_grid.OutputArray[i] as ATM_CELL).woro = t_woro[i]
		(atm_grid.OutputArray[i] as ATM_CELL).weff = t_weff[i]

##SW_RADIATION

#driver for short-wave radiation at the top and bottom of the atmosphere
func sw_radiation(frost_power : float, run_dswd_dalb : bool = false):
	
	for i in range(atm_grid.OutputArray.size()):
		
		var fswr_top : Array[float] = []
		var fswr_top_cs : Array[float] = []
		var fswr_top_cld : Array[float] = []
		fswr_top.resize(atm_grid.numSurfaceTypes)
		fswr_top_cs.resize(atm_grid.numSurfaceTypes)
		fswr_top_cld.resize(atm_grid.numSurfaceTypes)
		
		var temp_frost : Array[float] = []
		temp_frost.resize(atm_grid.numSurfaceTypes)
		#Possibility: Increase ice-albedo feedback by increasing the effective ice fraction in a grid cell for SW radiation
		temp_frost[(atm_grid.surfaceTypes.ICE as int)] = pow((atm_grid.OutputArray[i] as ATM_CELL).frst[(atm_grid.surfaceTypes.ICE as int)], frost_power)
		for n in range(atm_grid.numSurfaceTypes):
			if(n == (atm_grid.surfaceTypes.ICE as int)):
				if(temp_frost[atm_grid.surfaceTypes.ICE as int] < 1):
					temp_frost[n] = (atm_grid.OutputArray[i] as ATM_CELL).frst[n] * (1 - temp_frost[n]) / (1 - (atm_grid.OutputArray[i] as ATM_CELL).frst[n])
				else:
					temp_frost[n] = 0
			if (temp_frost[n] > 0) and ((atm_grid.OutputArray[i] as ATM_CELL).swr_dw_top > atmosphere_parameters.epsilon):
				var col_out : Dictionary = sw_radiation_col((atm_grid.OutputArray[i] as ATM_CELL).swr_dw_top, (atm_grid.OutputArray[i] as ATM_CELL).cosZM, (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Fraction, sum((atm_grid.OutputArray[i] as ATM_CELL).Specific_Humidity_2m, temp_frost, 2), sum((atm_grid.OutputArray[i] as ATM_CELL).ra_2, temp_frost, 2), sum((atm_grid.OutputArray[i] as ATM_CELL).Albedo_Clear_VisUV, temp_frost, 2), sum((atm_grid.OutputArray[i] as ATM_CELL).Albedo_Clear_VisUV, temp_frost, 2), sum((atm_grid.OutputArray[i] as ATM_CELL).Albedo_Cloudy_VisUV, temp_frost, 2), sum((atm_grid.OutputArray[i] as ATM_CELL).Albedo_Cloudy_IR, temp_frost, 2), (atm_grid.OutputArray[i] as ATM_CELL).Aerosol_Optical_Thickness, (atm_grid.OutputArray[i] as ATM_CELL).Aersol_Imaginary_Refractive_Index, (atm_grid.OutputArray[i] as ATM_CELL).SO4_Load, (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Optical_Thickness, (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Height, (atm_grid.OutputArray[i] as ATM_CELL).Vertical_Effective_Humidity_Scale)
				
				#Net shortwave radiation at TOA (no clue what TOA is)
				fswr_top[n] = (atm_grid.OutputArray[i] as ATM_CELL).swr_dw_top - col_out["solar_top_up"]
				fswr_top_cs[n] = (atm_grid.OutputArray[i] as ATM_CELL).swr_dw_top - col_out["solar_top_up_s"]
				fswr_top_cld[n] = (atm_grid.OutputArray[i] as ATM_CELL).swr_dw_top - col_out["solar_top_up_c"]
				#Net shortwave radiation at the surface
				(atm_grid.OutputArray[i] as ATM_CELL).fswr_sur[n] = col_out["solar_sur"]
				(atm_grid.OutputArray[i] as ATM_CELL).fswr_sur_cs[n] = col_out["solar_sur_s"]
				(atm_grid.OutputArray[i] as ATM_CELL).fswr_sur_Cloud[n] = col_out["solar_sur_c"]
				(atm_grid.OutputArray[i] as ATM_CELL).Cloud_Albed = col_out["alb_cld"]
			else:
				fswr_top[n] = 0
				fswr_top_cs[n] = 0
				fswr_top_cld[n] = 0
				(atm_grid.OutputArray[i] as ATM_CELL).fswr_sur[n] = 0
				(atm_grid.OutputArray[i] as ATM_CELL).fswr_sur_cs[n] = 0
				(atm_grid.OutputArray[i] as ATM_CELL).fswr_sur_Cloud[n] = 0
		
		(atm_grid.OutputArray[i] as ATM_CELL).swr_top = sum(fswr_top, temp_frost, 2)
		(atm_grid.OutputArray[i] as ATM_CELL).swr_top_Clear = sum(fswr_top_cs, temp_frost, 2)
		(atm_grid.OutputArray[i] as ATM_CELL).swr_top_Cloudy = sum(fswr_top_cld, temp_frost, 2)
		(atm_grid.OutputArray[i] as ATM_CELL).swr_sur = sum((atm_grid.OutputArray[i] as ATM_CELL).fswr_sur, temp_frost, 2)
		
		if run_dswd_dalb:
			#some partial derivative nonsense of downwar surface solar radiation based on surface albedo and elevation
			if ((atm_grid.OutputArray[i] as ATM_CELL).swr_dw_top > atmosphere_parameters.epsilon):
				#find a better alternative to cosZM
				var col_out : Dictionary = sw_radiation_col((atm_grid.OutputArray[i] as ATM_CELL).swr_dw_top, (atm_grid.OutputArray[i] as ATM_CELL).cosZM, (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Fraction, sum((atm_grid.OutputArray[i] as ATM_CELL).Specific_Humidity_2m, temp_frost, 2), sum((atm_grid.OutputArray[i] as ATM_CELL).ra_2, temp_frost, 2), sum((atm_grid.OutputArray[i] as ATM_CELL).Albedo_Clear_VisUV, temp_frost, 2), sum((atm_grid.OutputArray[i] as ATM_CELL).Albedo_Clear_VisUV, temp_frost, 2), sum((atm_grid.OutputArray[i] as ATM_CELL).Albedo_Cloudy_VisUV, temp_frost, 2), sum((atm_grid.OutputArray[i] as ATM_CELL).Albedo_Cloudy_IR, temp_frost, 2), (atm_grid.OutputArray[i] as ATM_CELL).Aerosol_Optical_Thickness, (atm_grid.OutputArray[i] as ATM_CELL).Aersol_Imaginary_Refractive_Index, (atm_grid.OutputArray[i] as ATM_CELL).SO4_Load, (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Optical_Thickness, (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Height, (atm_grid.OutputArray[i] as ATM_CELL).Vertical_Effective_Humidity_Scale, run_dswd_dalb)
				
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dalb_Clear_VisUV = col_out["DALB_CS_VU"]
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dalb_Cloudy_VisUV = col_out["DALB_CD_VU"]
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dalb_Clear_IR = col_out["DALB_CS_IR"]
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dalb_Cloudy_IR = col_out["DALB_CD_IR"]
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dz_Clear_IR = col_out["DZ_CS_IR"]
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dz_Cloudy_IR = col_out["DZ_CD_IR"]
				(atm_grid.OutputArray[i] as ATM_CELL).swr_dw_sur_Clear_Visible = col_out["SWR_CS_VIS"]
				(atm_grid.OutputArray[i] as ATM_CELL).swr_dw_sur_Cloudy_Visible = col_out["SWR_CD_VIS"]
				(atm_grid.OutputArray[i] as ATM_CELL).swr_dw_sur_Clear_NearIR = col_out["SWR_CS_IR"]
				(atm_grid.OutputArray[i] as ATM_CELL).swr_dw_sur_Cloudy_NearIR = col_out["SWR_CD_IR"]
				(atm_grid.OutputArray[i] as ATM_CELL).Cloud_Albed = col_out["alb_cld"]
			else:
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dalb_Clear_VisUV = 0
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dalb_Cloudy_VisUV = 0
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dalb_Clear_IR = 0
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dalb_Cloudy_IR = 0
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dz_Clear_IR = 0
				(atm_grid.OutputArray[i] as ATM_CELL).dswd_dz_Cloudy_IR = 0
				(atm_grid.OutputArray[i] as ATM_CELL).swr_dw_sur_Clear_Visible = 0
				(atm_grid.OutputArray[i] as ATM_CELL).swr_dw_sur_Cloudy_Visible = 0
				(atm_grid.OutputArray[i] as ATM_CELL).swr_dw_sur_Clear_NearIR = 0
				(atm_grid.OutputArray[i] as ATM_CELL).swr_dw_sur_Cloudy_NearIR = 0

#calculation of the short-wave radiation at the top and bototm of the atmosphere in a single column using two-stream approximation
func sw_radiation_col(solar_top : float, coszen : float, cld : float, q2 : float, ra2 : float, alb_sur_vu_s : float, alb_sur_ir_s : float, alb_sur_vu_c : float, alb_sur_ir_c : float, aerosol_ot : float, aerosol_im : float, so4 : float, cld_ot : float, h_c : float, h_q : float, run_dswd_dalb : bool = false) -> Dictionary:
	var out_col : Dictionary = {}
	var alb_cld : float = 0
	#This function comes with a key!
	# ift_			integral transmission function
	#    _atm_		entire atmosphere
	#    _w_		water
	#    _a_		aerosol
	#    _o_		ozone
	#    _c_		clouds
	#      _vu_		visible & UV
	#      _ir_		infrared
	#         _s	clear sky
	#         _c	cloudy sky
	#
	# alb_			albedo
	#    _sur_		surface
	#    _sct_		scattering
	#    _cld_		clouds
	#
	# frac_vu		fraction of VU radiation in total radiation
	# cld_ot		optical thickness of clouds
	# cld_gt		geometrical thickness of clouds
	# aerosol_ot	optical thickness of aerosol
	# aerosol_im	imaginary part of aerosol refractive index (WHAT MAKES IT IMAGINARY????)
	#The fact there is a key can NOT be good...
	
	##ALBEDO
	#AEROSOLS
	var alb_a_s : float = 0
	var alb_a_c : float = 0
	#MAGIC
	var alb_sa_vu_s : float = 0
	var alb_sa_ir_s : float = 0
	var alb_sa_vu_c : float = 0
	var alb_sa_ir_c : float = 0
	#SCATTERING
	var alb_sct_ir : float = 0
	var alb_sct_vu : float = 0
	#CLOUDS
	var alb_cld_ir : float = 0
	var alb_cld_vu : float = 0
	var alb_sct_ir_0 : float = 0
	var alb_sct_vu_0 : float = 0
	#MAGIC 2
	var alb_sa_ir_0 : float = 0
	var alb_sa_vu_0 : float = 0
	#ATMOSPHERE
	var alb_atm_ir_s : float = 0
	var alb_atm_vu_s : float = 0
	var alb_atm_ir_c : float = 0
	var alb_atm_vu_c : float = 0
	#BARB
	var b_arb : float = 0
	var b_arb_d1 : float = 0
	var b_arb_d2 : float = 0
	#THE CORPSE OF rgb
	var rqh : float = 0
	##INTEGRAL TRANSMISSION FUNCTION
	#WATER
	var itf_w_vu_s : float = 0
	var itf_w_ir_s : float = 0
	#AEROSOLS
	var itf_a_vu_s : float = 0
	var itf_a_ir_s : float = 0
	#OZONE
	var itf_o_vu_s : float = 0
	var itf_o_ir_s : float = 0
	#WATER
	var itf_w_vu_c : float = 0
	var itf_w_ir_c : float = 0
	#AEROSOLS
	var itf_a_vu_c : float = 0
	var itf_a_ir_c : float = 0
	#OZONE
	var itf_o_vu_c : float = 0
	var itf_o_ir_c : float = 0
	#CLOUDS
	var itf_c_vu : float = 0
	var itf_c_ir : float = 0
	#CLOUDS
	var itf_c_vu_d1 : float = 0
	var itf_c_ir_d1 : float = 0
	var itf_c_vu_d2 : float = 0
	var itf_c_ir_d2 : float = 0
	var itf_o_vu_d1 : float = 0
	var itf_o_ir_d1 : float = 0
	var itf_o_vu_d2 : float = 0
	var itf_o_ir_d2 : float = 0
	#WATER
	var itf_w_vu_s_d1 : float = 0
	var itf_w_ir_s_d1 : float = 0
	var itf_w_vu_s_d2 : float = 0
	var itf_w_ir_s_d2 : float = 0
	var itf_w_vu_c_d1 : float = 0
	var itf_w_ir_c_d1 : float = 0
	var itf_w_vu_c_d2 : float = 0
	var itf_w_ir_c_d2 : float = 0
	#AEROSOL
	var itf_a_vu_d1 : float = 0
	var itf_a_ir_d1 : float = 0
	var itf_a_vu_d2 : float = 0
	var itf_a_ir_d2 : float = 0
	#ATM
	var itf_atm_vu_s : float = 0
	var itf_atm_ir_s : float = 0
	var itf_atm_vu_c : float = 0
	var itf_atm_ir_c : float = 0
	##MAGIC
	#WATER
	var m_w_s_d1 : float = 0
	var m_w_c_d1 : float = 0
	var m_w_s_d2 : float = 0
	var m_w_c_d2 : float = 0
	var exp_1 : float = 0
	var exp_2 : float = 0
	var m_w_c : float = 0
	var m_w_s : float = 0
	#DELTA CORPSE OF rgb
	var drqh_dz : float = 0
	#DIRECT MESSAGING??? OF LIGHT???
	var dm_w_s_d1_dz : float = 0
	var dm_w_s_d2_dz : float = 0
	var ditf_w_ir_s_d1_dz : float = 0
	var ditf_w_ir_s_d2_dz : float = 0
	var dm_w_c_d1_dz : float = 0
	var dm_w_c_d2_dz : float = 0
	var ditf_w_ir_c_d1_dz : float = 0
	var ditf_w_ir_c_d2_dz : float = 0
	
	var exp_hc_hq : float = exp(-h_c/h_q)
	var cos_zen : float = max(coszen, 0.1)
	var cos_zen_o : float = 1/1.66
	var icos : float = 1.0 / cos_zen + 1 / cos_zen_o
	
	if (atmosphere_parameters.l_so4_de):
		#Direct sulfate aerosol effect
		
		#sulfate aerosol albedo (eq 6 in Bauer et al., 2008)
		alb_a_s = atmosphere_parameters.beta_so4 * atmosphere_parameters.sigma_so4 * so4 / cos_zen
		alb_a_c = atmosphere_parameters.beta_so4 * atmosphere_parameters.sigma_so4 * so4 / cos_zen_o
		
		#combined surface-aerosol albedo following Bauer et al., 2008 (eq. 5)
		alb_sa_vu_s = alb_a_s + (1 - alb_a_s) ** alb_sur_vu_s / (1 - alb_a_s * alb_sur_vu_s)
		alb_sa_ir_s = alb_a_s + (1 - alb_a_s) ** alb_sur_ir_s / (1 - alb_a_s * alb_sur_ir_s)
		alb_sa_vu_c = alb_a_c + (1 - alb_a_c) ** alb_sur_vu_c / (1 - alb_a_c * alb_sur_vu_c)
		alb_sa_ir_c = alb_a_c + (1 - alb_a_c) ** alb_sur_ir_c / (1 - alb_a_c * alb_sur_ir_c)
	else:
		alb_sa_vu_s = alb_sur_vu_s
		alb_sa_ir_s = alb_sur_ir_s
		alb_sa_vu_c = alb_sur_vu_c
		alb_sa_ir_c = alb_sur_vu_c
	
	if (atmosphere_parameters.l_alb_0):
		alb_sa_vu_0 = alb_sur_vu_c
		alb_sa_ir_0 = alb_sur_ir_c
	else:
		alb_sa_vu_0 = alb_sur_vu_s
		alb_sa_ir_0 = alb_sur_ir_s
	
	## 1. Shortwave flux at the top of the atmosphere
	# 1.1 clear sky conditions
	var b_ar : float =  0.55 * aerosol_ot
	b_arb = b_ar * icos
	var f_1 : float = cos_zen ** p_sw[0]
	var f_2 : float = b_ar ** p_sw[1]
	var f_3 : float = alf_sw[0] - alf_sw[1] * log(1 + alf_sw[3] * aerosol_im)
	
	alb_sct_vu = 1 - (1 - atmosphere_parameters.r_scat) * exp(-f_1 * f_2 * f_3)
	alb_sct_ir = 1 - exp(-f_1*f_2*f_3)
	
	if (atmosphere_parameters.l_sct_0):
		f_1 = cos_zen_o ** p_sw[0]
		alb_sct_vu_0 = 1 - (1 - atmosphere_parameters.r_scat) * exp(-f_1 * f_2 * f_3)
		alb_sct_ir_0 = 1 - exp(-f_1*f_2*f_3)
	else:
		alb_sct_vu_0 = alb_sct_vu
		alb_sct_ir_0 = alb_sct_ir
	
	#Integral transmission function for water
	rqh = 1e-3 * ra2 * q2 * 100 #colum water content in g/cm2
	m_w_s = rqh * icos
	
	itf_w_ir_s = atmosphere_parameters.a1_w * exp(-atmosphere_parameters.b1_w * m_w_s) + atmosphere_parameters.a2_w * exp(-atmosphere_parameters.b2_w * m_w_s)
	itf_w_vu_s = 1
	
	#ITF for aerosol
	itf_a_vu_s = exp(-gam_ar_sw[0] * b_arb * aerosol_im ** gam_ar_sw[1])
	itf_a_ir_s = itf_a_vu_s
	
	#ITF for ozone
	itf_o_vu_s = c_itf_o
	itf_o_ir_s = 1
	
	#planetary albedo
	alb_atm_vu_s = (alb_sct_vu + (((1 - alb_sct_vu) ** 2) * alb_sa_vu_s) / (1 - alb_sct_vu * alb_sa_vu_s)) * itf_w_vu_s * itf_a_vu_s * itf_o_vu_s
	alb_atm_ir_s = (alb_sct_ir + (((1 - alb_sct_ir) ** 2) * alb_sa_ir_s) / (1 - alb_sct_ir * alb_sa_ir_s)) * itf_w_ir_s * itf_a_ir_s * itf_o_ir_s
	
	#solar flux at atmosphere top
	out_col["solar_top_up_s"] = solar_top * (atmosphere_parameters.Planet.Boss.frac_visible_UV * alb_atm_vu_s + (1 - atmosphere_parameters.Planet.Boss.frac_visible_UV) * alb_atm_ir_s)
	
	# 1.2 Cloudy Conditions
	
	#ITF for clouds
	itf_c_ir = atmosphere_parameters.c_itf_c
	itf_c_vu = atmosphere_parameters.c_itf_c
	
	#ITF for water
	m_w_c = rqh * exp_hc_hq * (icos + (1 - exp(-cld_gt / h_q)))
	
	itf_w_ir_c = atmosphere_parameters.a1_w * exp(-atmosphere_parameters.b1_w * m_w_c) + atmosphere_parameters.a2_w * exp(-atmosphere_parameters.b2_w * m_w_c) 
	itf_w_vu_c = 1
	
	#ITF for aerosol
	b_arb = (b_ar * exp_hc_hq) * (icos + (1 - exp(-cld_gt / h_q)))
	itf_a_vu_c = exp(-gam_ar_sw[0] * b_arb * aerosol_im ** gam_ar_sw[1])
	itf_a_ir_c = itf_a_vu_c
	
	#ITF for ozone
	itf_o_vu_c = c_itf_o
	itf_o_ir_c = 1
	
	#Cloud albedo
	var b_c : float = gl_c_sw / cos_zen ** p_sw[2]
	alb_cld_vu = 1 - (1 - alb_sct_vu) * exp(-b_c * cld_ot ** p_sw[3])
	alb_cld_ir = 1 - (1 - alb_sct_ir) * exp(-b_c * cld_ot ** p_sw[3])
	out_col["alb_cld"] = alb_cld_vu
	alb_cld = alb_cld_vu
	
	#Planetary Albedo
	alb_atm_ir_c = (alb_cld_ir + (1 - alb_cld_ir) ** 2 * alb_sa_ir_c) / (1 - alb_cld_ir * alb_sa_ir_s) * itf_w_ir_c * itf_c_ir * itf_a_ir_c * itf_o_ir_c
	alb_atm_vu_c = (alb_cld_vu + (1 - alb_cld_vu) ** 2 * alb_sa_vu_c) / (1 - alb_cld_vu * alb_sa_vu_s) * itf_w_vu_c * itf_c_vu * itf_a_vu_c * itf_o_vu_c
	
	#SW flux at atmosphere top (cloudy)
	out_col["solar_top_up_c"] = solar_top * (atmosphere_parameters.Planet.Boss.frac_visible_UV * alb_atm_vu_c + (1 - atmosphere_parameters.Planet.Boss.frac_visible_UV * alb_atm_ir_c))
	
	#SW flux at atmosphere top
	out_col["solar_top_up"] = (1 - cld) * out_col["solar_top_up_s"] + cld * out_col["solar_top_up_c"]
	
	## 2 Shortwave flux at surface
	
	# 2.1 Clear Sky Conditions
	
	#ITF for ozone
	itf_o_vu_d1 = c_itf_o
	itf_o_ir_d1 = 1
	itf_o_vu_d2 = c_itf_o
	itf_o_ir_d2 = 1
	
	#ITF for water
	m_w_s_d1 = rqh / cos_zen
	m_w_s_d2 = m_w_s_d1 + rqh * (1 - 0.7788008) * 2 / cos_zen_o #apparently, 0.7788008 = exp(-0.25). don't know the importance of exp(-0.25) though
	
	itf_w_vu_s_d1 = 1
	itf_w_vu_s_d2 = 1
	itf_w_ir_s_d1 = atmosphere_parameters.a1_w * exp(-atmosphere_parameters.b1_w * m_w_s_d1) + atmosphere_parameters.a2_w * exp(-atmosphere_parameters.b2_w * m_w_s_d1)
	itf_w_ir_s_d2 = atmosphere_parameters.a1_w * exp(-atmosphere_parameters.b1_w * m_w_s_d2) + atmosphere_parameters.a2_w * exp(-atmosphere_parameters.b2_w * m_w_s_d2)
	
	#ITF for aerosol
	b_arb_d1 = b_ar / cos_zen
	b_arb_d2 = b_arb_d1 + b_ar * (1 - 0.7788008) * 2 / cos_zen_o
	
	itf_a_vu_d1 = exp(-gam_ar_sw[0] * b_arb_d1 * aerosol_im ** gam_ar_sw[1])
	itf_a_ir_d1 = itf_a_vu_d1
	
	itf_a_vu_d2 = exp(-gam_ar_sw[0] * b_arb_d2 * aerosol_im ** gam_ar_sw[1])
	itf_a_ir_d2 = itf_a_vu_d2
	
	#ITF of the atmosphere:
	itf_atm_vu_s = (1 - alb_sct_vu) * (1 - alb_sa_vu_s) * itf_w_vu_s_d1 * itf_a_vu_d1 * itf_o_vu_d1 + (1 - alb_sct_vu) * alb_sa_vu_s * alb_sct_vu_0 * (1 - alb_sa_vu_0) / (1 - alb_sct_vu_0 * alb_sa_vu_0) * itf_w_vu_s_d2 * itf_a_vu_d2 * itf_o_vu_d2
	itf_atm_ir_s = (1 - alb_sct_ir) * (1 - alb_sa_ir_s) * itf_w_ir_s_d1 * itf_a_ir_d1 * itf_o_ir_d1 + (1 - alb_sct_ir) * alb_sa_ir_s * alb_sct_ir_0 * (1 - alb_sa_ir_0) / (1 - alb_sct_ir_0 * alb_sa_ir_0) * itf_w_ir_s_d2 * itf_a_ir_d2 * itf_o_ir_d2 
	
	out_col["solar_sur_s"] = solar_top * (atmosphere_parameters.Planet.Boss.frac_visible_UV * itf_atm_vu_s + (1 - atmosphere_parameters.Planet.Boss.frac_visible_UV) * itf_atm_ir_s)
	
	if run_dswd_dalb:
		out_col["swr_dw_sur_vis_cs"] = solar_top * itf_atm_vu_s / (1-alb_sa_vu_s)
		out_col["swr_dw_sur_nir_cs"] = solar_top * itf_atm_ir_s / (1-alb_sa_ir_s)
		
		out_col["dswd_alb_vu_cs"] = solar_top * ((1 - alb_sct_vu) * alb_sct_vu * alb_sct_vu_0 * (1 - alb_sct_vu_0 * alb_sa_vu_s) - (1 - alb_sct_vu) * alb_sa_vu_s * alb_sct_vu_0 * (-1) * alb_sct_vu_0) / (1 -alb_sct_vu_0 * alb_sa_vu_s) ** 2 * itf_w_vu_s_d2 * itf_a_vu_d2 * itf_o_vu_d2
		out_col["dswd_alb_ir_cs"] = solar_top * ((1 - alb_sct_ir) * alb_sct_ir * alb_sct_ir_0 * (1 - alb_sct_ir_0 * alb_sa_ir_s) - (1 - alb_sct_ir) * alb_sa_ir_s * alb_sct_ir_0 * (-1) * alb_sct_ir_0) / (1 -alb_sct_ir_0 * alb_sa_ir_s) ** 2 * itf_w_ir_s_d2 * itf_a_ir_d2 * itf_o_ir_d2
		
		drqh_dz = 1e-3 * 100 * h_q * (ra2 * q2 / (-100 * h_q) + q2 * ra2 / (-100 * atmosphere_parameters.atmosphere_scale))
		dm_w_s_d1_dz = 1 / cos_zen * drqh_dz
		dm_w_s_d2_dz = dm_w_s_d1_dz + (1 - 0.7788008) * 2 / cos_zen_o * drqh_dz
		ditf_w_ir_s_d1_dz = atmosphere_parameters.a1_w * (atmosphere_parameters.b1_w) * exp(-atmosphere_parameters.b1_w * m_w_s_d1) * dm_w_s_d1_dz + atmosphere_parameters.a2_w * (-atmosphere_parameters.b2_w) * exp(-atmosphere_parameters.b2_w * m_w_s_d1) * dm_w_s_d1_dz
		ditf_w_ir_s_d2_dz = atmosphere_parameters.a1_w * (atmosphere_parameters.b1_w) * exp(-atmosphere_parameters.b1_w * m_w_s_d2) * dm_w_s_d2_dz + atmosphere_parameters.a2_w * (-atmosphere_parameters.b2_w) * exp(-atmosphere_parameters.b2_w * m_w_s_d2) * dm_w_s_d2_dz
		out_col["dswd_dz_ir_cs"] = solar_top * ((1 - alb_sct_ir) * itf_a_vu_d1 * itf_o_vu_d1 * ditf_w_ir_s_d1_dz + (1 - alb_sct_ir) * alb_sa_ir_s * alb_sct_ir / (1 - alb_sct_ir * alb_sa_ir_s) * itf_a_ir_d2 * itf_o_ir_d2 * ditf_w_ir_s_d2_dz) * 100 #W/m2/m
	
	# 2.2 cloudy conditions
	
	#ITF of ozone
	itf_o_vu_d1 = c_itf_o
	itf_o_ir_d1 = 1
	itf_o_vu_d2 = c_itf_o
	itf_o_ir_d2 = 1
	
	#ITF for clouds
	itf_c_vu_d1 = atmosphere_parameters.c_itf_cc
	itf_c_vu_d2 = atmosphere_parameters.c_itf_cc
	itf_c_ir_d1 = atmosphere_parameters.c_itf_cc
	itf_c_ir_d2 = atmosphere_parameters.c_itf_cc
	
	#ITF for water
	exp_1 = exp_hc_hq - exp(-(h_c + cld_gt) / h_q)
	exp_2 = 1 - exp_hc_hq / cos_zen_o
	
	m_w_c_d1 = rqh * (exp_hc_hq / cos_zen + exp_1 + exp_2)
	m_w_c_d2 = m_w_c_d1 + rqh * (2 * exp_2 + exp_1)
	
	itf_w_vu_c_d1 = 1
	itf_w_vu_c_d2 = 1
	itf_w_ir_c_d1 = atmosphere_parameters.a1_w * exp(-atmosphere_parameters.b1_w * m_w_c_d1) + atmosphere_parameters.a2_w * exp(-atmosphere_parameters.b2_w * m_w_c_d1)
	itf_w_ir_c_d2 = atmosphere_parameters.a1_w * exp(-atmosphere_parameters.b1_w * m_w_c_d2) + atmosphere_parameters.a2_w * exp(-atmosphere_parameters.b2_w * m_w_c_d2)
	
	#ITF for aerosol
	b_arb_d1 = b_ar * (exp_hc_hq / cos_zen + exp_1 + exp_2)
	b_arb_d2 = b_arb_d1 + b_ar * (exp_1 + 2 * exp_2)
	
	itf_a_vu_d1 = exp(-gam_ar_sw[0] * b_arb_d1 * aerosol_im ** gam_ar_sw[1])
	itf_a_ir_d1 = itf_a_vu_d1
	
	itf_a_vu_d2 = exp(-gam_ar_sw[0] * b_arb_d2 * aerosol_im ** gam_ar_sw[1])
	itf_a_ir_d2 = itf_a_vu_d2
	
	#Atmospheric ITF
	itf_atm_vu_c = (1 - alb_cld_vu) * (1 - alb_sa_vu_c) * itf_c_vu_d1 * itf_w_vu_c_d1 * itf_a_vu_d1 * itf_o_vu_d1 + (1 - alb_cld_vu) * alb_sa_vu_c * alb_cld_vu * (1 - alb_sa_vu_c) / (1 - alb_cld_vu * alb_sa_vu_c) * itf_c_vu_d2 * itf_w_vu_c_d2 * itf_a_vu_d2 * itf_o_vu_d2
	itf_atm_ir_c = (1 - alb_cld_ir) * (1 - alb_sa_ir_c) * itf_c_ir_d1 * itf_w_ir_c_d1 * itf_a_ir_d1 * itf_o_ir_d1 + (1 - alb_cld_ir) * alb_sa_ir_c * alb_cld_ir * (1 - alb_sa_ir_c) / (1 - alb_cld_ir * alb_sa_ir_c) * itf_c_ir_d2 * itf_w_ir_c_d2 * itf_a_ir_d2 * itf_o_ir_d2
	
	out_col["solar_sur_c"] = solar_top * (atmosphere_parameters.Planet.Boss.frac_visible_UV * itf_atm_vu_c + (1 - atmosphere_parameters.Planet.Boss.frac_visible_UV) * itf_atm_ir_c)
	
	if run_dswd_dalb:
		out_col["swr_dw_sur_vis_cld"] = solar_top * itf_atm_vu_c / (1-alb_sa_vu_c)
		out_col["swr_dw_sur_nir_cld"] = solar_top * itf_atm_ir_c / (1-alb_sa_ir_c)
		
		out_col["dswd_alb_vu_cld"] = solar_top * ((1 - alb_cld_vu) * alb_cld_vu * (1 - alb_cld_vu * alb_sa_vu_c) - (1 - alb_cld_vu) * alb_sa_vu_c * alb_cld_vu * (-1) * alb_cld_vu) / (1 -alb_cld_vu * alb_sa_vu_c) ** 2 * itf_c_vu_d2 * itf_w_vu_s_d2 * itf_a_vu_d2 * itf_o_vu_d2
		out_col["dswd_alb_ir_cld"] = solar_top * ((1 - alb_cld_ir) * alb_cld_ir * (1 - alb_cld_ir * alb_sa_ir_c) - (1 - alb_cld_ir) * alb_sa_ir_c * alb_cld_ir * (-1) * alb_cld_ir) / (1 -alb_cld_ir * alb_sa_ir_c) ** 2 * itf_c_ir_d2 * itf_w_ir_s_d2 * itf_a_ir_d2 * itf_o_ir_d2
		
		drqh_dz = 1e-3 * 100 * h_q * (ra2 * q2 / (-100 * h_q) + q2 * ra2 / (-100 * atmosphere_parameters.atmosphere_scale))
		dm_w_c_d1_dz = 1 / cos_zen * drqh_dz
		dm_w_c_d2_dz = dm_w_s_d1_dz + (1 - 0.7788008) * 2 / cos_zen_o * drqh_dz
		ditf_w_ir_c_d1_dz = atmosphere_parameters.a1_w * (atmosphere_parameters.b1_w) * exp(-atmosphere_parameters.b1_w * m_w_s_d1) * dm_w_s_d1_dz + atmosphere_parameters.a2_w * (-atmosphere_parameters.b2_w) * exp(-atmosphere_parameters.b2_w * m_w_s_d1) * dm_w_s_d1_dz
		ditf_w_ir_c_d2_dz = atmosphere_parameters.a1_w * (atmosphere_parameters.b1_w) * exp(-atmosphere_parameters.b1_w * m_w_s_d2) * dm_w_s_d2_dz + atmosphere_parameters.a2_w * (-atmosphere_parameters.b2_w) * exp(-atmosphere_parameters.b2_w * m_w_s_d2) * dm_w_s_d2_dz
		out_col["dswd_dz_ir_cld"] = solar_top * ((1 - alb_cld_ir) * itf_c_ir_d1 * itf_a_vu_d1 * itf_o_vu_d1 * ditf_w_ir_c_d1_dz + (1 - alb_cld_ir) * alb_sa_ir_s * alb_sct_ir / (1 - alb_sct_ir * alb_sa_ir_s) * itf_c_ir_d2 * itf_a_ir_d2 * itf_o_ir_d2 * ditf_w_ir_s_d2_dz) * 100 #W/m2/m
	
	#Final calculation!
	out_col["solar_sur"] = (1 - cld) * out_col["solar_sur_s"] + cld * out_col["solar_sur_c"]
	
	return out_col
