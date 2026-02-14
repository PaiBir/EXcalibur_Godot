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

#Aspects from ATM_DEF
var Hadley_Cell_Width : float #radians
var InterTropicalConvergenceZone_Position : float #radians

var eccentricity : float
var precession : float
var obliquity : float

var t2m_glob_ann : float = 0
var dt2m_glob_ann_cum : float = 0

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


func Clouds():
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
		var clotl : float = min(10.0, atmosphere_parameters.c_CloudOpticalThickness[2] * ftemp * ((atm_grid.OutputArray[j] as ATM_CELL).cloud))
		
