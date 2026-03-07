class_name CLIMBER_X_ATMO
extends Node

##ADIFA
var atmosphere_parameters : ATM_PARAM
var atm_grid : ATM_GRID
var model_timer : MODELTIMER
var controller : CLIMBER_X_CONTROL

var Atm_CO2 : float #ppmv
var Equivalent_CO2 : float #ppmv
var Atm_CH4 : float #ppb
var Atm_N2O : float #ppb
var Atm_CFC11 : float #ppt
var Atm_CFC12 : float #ppt

##CRISA
var z_reference := 100.0 #meters, reference height

##VESTA
var hrs_min : float = 1e3
var hrs_max : float = 10e3

##SHORT-WAVE RADIATION
var p_sw : Array[float] = [-1.97, 0.82, 0.35, 0.67]
var alf_sw : Array[float] = [7.73e-2, 2.39e-2, 1.51e2]
var gam_ar_sw : Array[float] = [2.75,0.636]
var gl_c_sw : float = 0.14
var cld_gt : float = 1000
var c_itf_o = 0.98

##LONG-WAVE RADIATION
var emis_lw : float = 1 #atmospheric emissivity
var h0_lw : float = 0 #height scale (cm)
var beta0_lw : float = 1.66
#CO2
var a0_co2_lw : float = 0.247
var a1_co2_lw : float = 0.755
#Ozone
var ak_o3_lw : float = 0.6 #"from tuning of total LW contribution by O3
var a_o3_lw : float = 8.246
var beta_o3_lw : float = 0.539

var z_atm_lw : float = 30e3

var feedbackanalysis : bool = false

## FEEDBACKS
var i_control : int = 0
var i_pl : int  = 1
var i_wv : int  = 2
var i_cld : int = 3
var i_lr : int  = 4
var i_alb : int = 5
var i_cld_frac : int = 6
var i_cld_clot : int = 7
var i_cld_hcld : int = 8
var i_lr_gam : int  = 9
var i_lr_tam : int  = 10
var i_temp : int = 11
var i_all : int = 12
var nfb : int = 12

var FB_co2 : float = 0
var FB_tam : Array[Array] = []
var FB_cld : Array[Array] = []
var FB_hcld : Array[Array] = []
var FB_clot : Array[Array] = []
var FB_gams : Array[Array] = []
var FB_gamb : Array[Array] = []
var FB_gamt : Array[Array] = []
var FB_htrop : Array[Array] = []
var FB_ttrop : Array[Array] = []
var FB_ram : Array[Array] = []
var FB_hrm : Array[Array] = []
var FB_hqeff : Array[Array] = []
var FB_aerosol_ot : Array[Array] = [] 
var FB_aerosol_im : Array[Array] = []
var FB_so4 : Array[Array] = []
var FB_frst : Array[Array] = []
var FB_tskin : Array[Array] = []
var FB_t2 : Array[Array] = []
var FB_q2 : Array[Array] = []
var FB_alb_vu_s : Array[Array] = []
var FB_alb_vu_c : Array[Array] = []
var FB_alb_ir_s : Array[Array] = []
var FB_alb_ir_c : Array[Array] = []
var FB_flwr_up_sur : Array[Array] = []

var FB_tg : Array[float] = [0,0]
var FB_delta_t : float = 0
var FB_rf_top_avg : float = 0
var FB_rf_trop_avg : float = 0
var FB_rf_top : Array[float] = []
var FB_rf_trop : Array[float] = []
var FB_dhtrop_rf : Array[float] = []
var FB_flwr_top : Array[Array] = []
var FB_fswr_top : Array[Array] = []
var FB_d_flwr_top : Array[Array] = []
var FB_d_fswr_top : Array[Array] = []
var FB_d_f_top : Array[Array] = []

##Aspects from ATM_DEF
var Hadley_Cell_Width : float #radians
var InterTropicalConvergenceZone_Position : float #radians

var eccentricity : float
var precession : float
var obliquity : float

var t2m_glob_ann : float = 0
var dt2m_glob_ann_cum : float = 0

func sum(a : Array,b : Array, o : int, mask : int = -1) -> float: #o = 0: addition, o = 1: subtraction, o = 2: multiplication, o = 3: division
	var total : float = 0
	if(mask == -1):
		for i in range(a.size()):
			if o == 0:
				total += (a[i] + b[i])
			elif o == 1:
				total += (a[i] - b[i])
			elif o == 2:
				total += (a[i] * b[i])
			elif o == 3:
				total += (a[i] / b[i])
	else:
		for i in range(a.size()):
			if o == 0:
				total += (a[i][mask] + b[i][mask])
			elif o == 1:
				total += (a[i][mask] - b[i][mask])
			elif o == 2:
				total += (a[i][mask] * b[i][mask])
			elif o == 3:
				total += (a[i][mask] / b[i][mask])
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
		ditf_w_ir_c_d1_dz = atmosphere_parameters.a1_w * (atmosphere_parameters.b1_w) * exp(-atmosphere_parameters.b1_w * m_w_s_d1) * dm_w_c_d1_dz + atmosphere_parameters.a2_w * (-atmosphere_parameters.b2_w) * exp(-atmosphere_parameters.b2_w * m_w_s_d1) * dm_w_c_d1_dz
		ditf_w_ir_c_d2_dz = atmosphere_parameters.a1_w * (atmosphere_parameters.b1_w) * exp(-atmosphere_parameters.b1_w * m_w_s_d2) * dm_w_c_d2_dz + atmosphere_parameters.a2_w * (-atmosphere_parameters.b2_w) * exp(-atmosphere_parameters.b2_w * m_w_s_d2) * dm_w_c_d2_dz
		out_col["dswd_dz_ir_cld"] = solar_top * ((1 - alb_cld_ir) * itf_c_ir_d1 * itf_a_vu_d1 * itf_o_vu_d1 * ditf_w_ir_c_d1_dz + (1 - alb_cld_ir) * alb_sa_ir_s * alb_sct_ir / (1 - alb_sct_ir * alb_sa_ir_s) * itf_c_ir_d2 * itf_a_ir_d2 * itf_o_ir_d2 * ditf_w_ir_c_d2_dz) * 100 #W/m2/m
	
	#Final calculation!
	out_col["solar_sur"] = (1 - cld) * out_col["solar_sur_s"] + cld * out_col["solar_sur_c"]
	
	return out_col

##LW_RADIATION

#driver for long-wave radiation
func lw_radiation(ecs_scale : float, flwr_up_sur : Array[Array], gams_q : Array[float] = [], gamb_q : Array[float] = [], gamt_q : Array[float] = [], tam_q : Array[float] = [], ttrop_q : Array[float] = [], htrop_q : Array[float] = []):
	#W/m2/ppm
	var a1 : float = -2.4e-7
	var b1 : float = 7.2e-4
	var c1 : float = -2.1e-4
	var a2 : float = -8e-6
	var b2 : float = 4.2e-6
	var c2 : float = -4.9e-6
	var a3 : float = -1e-6
	var b3 : float = -8.2e-6
	
	
	if(gams_q.size() > 0):
		feedbackanalysis = true
	else:
		feedbackanalysis = false
	
	h0_lw = atmosphere_parameters.atmosphere_scale * 100 #m -> cm
	
	##Compute Effective CO2 concentration for longwave radiation
	#Using table 1 in Etminan et al., 2016
	var co2_bar : float = 0.5 * (Atm_CO2 + controller.co2_ref)
	var ch4_bar : float = 0.5 * (Atm_CH4 + controller.ch4_ref)
	var n2o_bar : float = 0.5 * (Atm_N2O + controller.n2o_ref)
	
	var rf_co2 = (a1 * (Atm_CO2 - controller.co2_ref) ** 2 + b1 * abs(Atm_CO2 + controller.co2_ref) + c1 * controller.n2o_bar + 5.36) * log(Atm_CO2 / controller.co2_ref)
	var rf_n2o = (a2 * co2_bar + b2 * n2o_bar + c2 * ch4_bar + 0.117) * (sqrt(Atm_N2O) - sqrt(controller.n2o_ref))
	var rf_ch4 = (a3 * ch4_bar + b3 * n2o_bar + 0.043) * (sqrt(Atm_CH4) - sqrt(controller.ch4_ref))
	var rf_cfc11 = 0.25 * 1e-3 + Atm_CFC11 #Table 3 from Myhre et al., 1998
	var rf_cfc12 = 0.33 * 1e-3 * Atm_CFC12 #Table 3 from Myhre et al., 1998
	
	#Convert Greenhouse Gases into CO2 concentration
	var co2e = controller.co2_ref * exp((rf_co2 + rf_ch4 + rf_n2o + rf_cfc11 + rf_cfc12) / (a1 * (Atm_CO2 - controller.co2_ref) ** 2 + b1 * abs(Atm_CO2 - controller.co2_ref) + c1 * n2o_bar + 5.36)) #ppmv
	co2e = exp(ecs_scale * log(co2e) + (1 - ecs_scale) * log(controller.co2_ref))
	
	#ppm to mass mixing
	var q_co2 = co2e * 1e-6 * 44.0095 / 28.97 #kg/kg
	
	for i in range(atm_grid.OutputArray.size()):
		var flwr_sur : Array[float] = []
		flwr_sur.resize(atm_grid.numSurfaceTypes)
		var flwr_top : Array[float] = []
		flwr_top.resize(atm_grid.numSurfaceTypes)
		var flwr_top_cs : Array[float] = []
		flwr_top_cs.resize(atm_grid.numSurfaceTypes)
		var flwr_top_cld : Array[float] = []
		flwr_top_cld.resize(atm_grid.numSurfaceTypes)
		var flwr_tro : Array[float] = []
		flwr_tro.resize(atm_grid.numSurfaceTypes)
		var flwr_cld : Array[float] = []
		flwr_cld.resize(atm_grid.numSurfaceTypes)
		(atm_grid.OutputArray[i] as ATM_CELL).flwr_dw_sur.resize(atm_grid.numSurfaceTypes)
		(atm_grid.OutputArray[i] as ATM_CELL).flwr_dw_sur_cs.resize(atm_grid.numSurfaceTypes)
		(atm_grid.OutputArray[i] as ATM_CELL).flwr_dw_sur_Cloud.resize(atm_grid.numSurfaceTypes)
		var fst : Array[float] = []
		fst.resize(atm_grid.numSurfaceTypes)
		for n in atm_grid.numSurfaceTypes:
			var zlwr : Array[float] = []
			var tlwr : Array[float] = []
			var qlwr : Array[float] = []
			var o3lwr : Array[float] = []
			fst[n] = (atm_grid.OutputArray[i] as ATM_CELL).frst[n]
			if((fst[n] > 0) or (n == (atm_grid.surfaceTypes.OCEAN as int))):
				#Atmospheric charactreristics at vertical levels
				if(!feedbackanalysis):
					var Out_Col_L = lwr_column((atm_grid.OutputArray[i] as ATM_CELL).Surface, (atm_grid.OutputArray[i] as ATM_CELL).ZS[n], (atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Height, (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Height, (atm_grid.OutputArray[i] as ATM_CELL).LapseRate_BoundaryLayer,(atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Lower_Tropo,(atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Upper_Tropo, (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Temp, (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Relative_Humidity, (atm_grid.OutputArray[i] as ATM_CELL).Vertical_Humidity_Scale, (atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Temperature, (atm_grid.OutputArray[i] as ATM_CELL).Ozone_Concentration)
					zlwr = Out_Col_L["zlwr"]
					tlwr = Out_Col_L["tlwr"]
					qlwr = Out_Col_L["qlwr"]
					o3lwr = Out_Col_L["o3lwr"]
				else:
					var Out_Col_L = lwr_column((atm_grid.OutputArray[i] as ATM_CELL).Surface, (atm_grid.OutputArray[i] as ATM_CELL).ZS[n], (atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Height, (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Height, (atm_grid.OutputArray[i] as ATM_CELL).LapseRate_BoundaryLayer,(atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Lower_Tropo,(atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Upper_Tropo, (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Temp, (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Relative_Humidity, (atm_grid.OutputArray[i] as ATM_CELL).Vertical_Humidity_Scale, (atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Temperature, (atm_grid.OutputArray[i] as ATM_CELL).Ozone_Concentration, gams_q[i], gamb_q[i], gamt_q[i], tam_q[i], ttrop_q[i], htrop_q[i])
					zlwr = Out_Col_L["zlwr"]
					tlwr = Out_Col_L["tlwr"]
					qlwr = Out_Col_L["qlwr"]
					o3lwr = Out_Col_L["o3lwr"]
				
				#Clear sky and cloudy conditions
				var Out_Col = lwr_transfer((atm_grid.OutputArray[i] as ATM_CELL).ra_2[2], (atm_grid.OutputArray[n] as ATM_CELL).Cloud_Optical_Thickness, zlwr, tlwr, qlwr, o3lwr, q_co2)
				var BSB : Array[float] = Out_Col["BSB"]
				var DCS : Array[Array] = Out_Col["DCS"]
				var DCL : Array[Array] = Out_Col["DCL"]
				
				#Fluxes for clear and cloudy conditions
				Out_Col = lwr_clear_sky(flwr_up_sur[i][n], BSB, DCS)
				var fcs_up = Out_Col["fcs_up"]
				var fcs_dw = Out_Col["fcs_dw"]
				
				Out_Col = lwr_clouds(flwr_up_sur[i][n], BSB, DCL)
				var fcl_up = Out_Col["fcl_up"]
				var fcl_dw = Out_Col["fcl_dw"]
				
				#Total fluxes
				Out_Col = lwr_total((atm_grid.OutputArray[i] as ATM_CELL).Cloud_Fraction, fcs_up, fcs_dw, fcl_up, fcl_dw)
				flwr_sur[n] = Out_Col["flwr_sur"]
				(atm_grid.OutputArray[i] as ATM_CELL).flwr_dw_sur[n] = Out_Col["flwr_dw_sur"]
				(atm_grid.OutputArray[i] as ATM_CELL).flwr_dw_sur_cs[n] = Out_Col["flwr_dw_sur_cs"]
				(atm_grid.OutputArray[i] as ATM_CELL).flwr_dw_sur_Cloud[n] = Out_Col["flwr_dw_sur_cld"]
				flwr_top[n] = Out_Col["flwr_top"]
				flwr_top_cs[n] = Out_Col["flwr_top_cs"]
				flwr_top_cld[n] = Out_Col["flwr_top_cld"]
				flwr_tro[n] = Out_Col["flwr_tro"]
				flwr_cld[n] = Out_Col["flwr_cld"]
			else:
				flwr_sur[n] = 0
				(atm_grid.OutputArray[i] as ATM_CELL).flwr_dw_sur[n] = 0
				(atm_grid.OutputArray[i] as ATM_CELL).flwr_dw_sur_cs[n] = 0
				(atm_grid.OutputArray[i] as ATM_CELL).flwr_dw_sur_Cloud[n] = 0
				flwr_top[n] = 0
				flwr_top_cs[n] = 0
				flwr_top_cld[n] = 0
				flwr_tro[n] = 0
				flwr_cld[n] = 0
		(atm_grid.OutputArray[i] as ATM_CELL).lwr_sur = sum(flwr_sur,fst,2)
		(atm_grid.OutputArray[i] as ATM_CELL).lwr_top = sum(flwr_top,fst,2)
		(atm_grid.OutputArray[i] as ATM_CELL).lwr_top_Clear = sum(flwr_top_cs,fst,2)
		(atm_grid.OutputArray[i] as ATM_CELL).lwr_top_Cloudy = sum(flwr_top_cld,fst,2)
		(atm_grid.OutputArray[i] as ATM_CELL).lwr_tro = sum(flwr_tro,fst,2)
		(atm_grid.OutputArray[i] as ATM_CELL).lwr_Cloudy = sum(flwr_cld,fst,2)

#combine clear sky and cloudy long-wave radiation
func lwr_total(cld : float, fcs_up : Array[float], fcs_dw : Array[float], fcl_up : Array[float], fcl_dw : Array[float]):
	var OutCol : Dictionary = {}
	#Surface Fluxes
	OutCol["flwr_sur"] = (1 - cld) * (fcs_dw[0] - fcs_up[0]) + cld * (fcl_dw[0] - fcl_up[0])
	OutCol["flwr_dw_sur"] = (1 - cld) * fcs_dw[0] + cld * fcl_dw[0]
	OutCol["flwr_dw_sur_cs"] = fcs_dw[0]
	OutCol["flwr_dw_sur_cld"] = fcl_dw[0]
	
	#Net fluxes at TOA, positive down
	OutCol["flwr_top"] = -((1 - cld) * fcs_dw[atm_grid.llwr]) + cld * fcl_up[atm_grid.llwr]
	OutCol["flwr_top_cs"] = -fcs_up[atm_grid.llwr]
	OutCol["flwr_top_cld"] = -fcl_up[atm_grid.llwr]
	
	#Fluxes at the tropopause
	var k : int = atm_grid.llwr_a[2]
	OutCol["flwr_up_tro"] = (1 - cld) * fcs_up[k] + cld * fcl_up[k]
	OutCol["flwr_dw_tro"] = (1 - cld) * fcs_dw[k] + cld * fcl_dw[k]
	OutCol["flwr_tro"] = OutCol["flwr_dw_tro"] - OutCol["flwr_up_tro"]
	
	#Fluxes at cloud base
	k = atm_grid.llwr_a[0]
	OutCol["flwr_up_cld"] = (1 - cld) * fcs_up[k] + cld * fcl_up[k]
	OutCol["flwr_dw_cld"] = (1 - cld) * fcs_dw[k] + cld * fcl_dw[k]
	OutCol["flwr_cld"] = OutCol["flwr_dw_cld"] - OutCol["flwr_up_cld"]
	
	return OutCol

#derive temperature, humidity and ozone at long-wave radiation levels
func lwr_column(zsa : float, zs : float, htrop : float, hcld : float, gams : float, gamb : float, gamt : float, tam : float, ram : float, hrm : float, ttrop : float, O3 : Array[float], gams_q : float = -INF, gamb_q : float = 0.0, gamt_q : float = 0.0, tam_q : float = 0.0, ttrop_q : float = 0.0, htrop_q : float = 0.0):
	var OutCol : Dictionary = {}
	#Cloud parameters
	var z_cld_bot : float = zs + atmosphere_parameters.hpbl
	var z_cld_top : float = min(max(hcld, z_cld_bot + 1000), htrop - 1000)
	
	#Layers thickness
	var dz_l1 : float = (z_cld_bot - zs) / (atm_grid.nlwr_a[0] - 1)
	var dz_l2 : float = (z_cld_top - z_cld_bot) / atm_grid.nlwr_a[1]
	var dz_l3 : float = (htrop - z_cld_top) / atm_grid.nlwr_a[2]
	var dz_l4 : float = (z_atm_lw - htrop) / atm_grid.nlwr_a[3]
	
	#LEVELS:
	#K = 1: Surface
	#K = nlwr_a[0]: Cloud Bottom
	#K = nlwr_a[1]: Cloud Top
	#K = nlwr_a[2]: Tropopause
	#K = nlwr_a[3]: Top of the Atmosphere
	
	OutCol["zlwr"] = []
	OutCol["zlwr"].append(zs)
	
	for k in range(1,atm_grid.nlwr_a[0]):
		OutCol["zlwr"].append(OutCol["zlwr"][k-1] + dz_l1)
	
	for k in range(atm_grid.nlwr_a[0],atm_grid.nlwr_a[1]):
		OutCol["zlwr"].append(OutCol["zlwr"][k-1] + dz_l2)
	
	for k in range(atm_grid.nlwr_a[1],atm_grid.nlwr_a[2]):
		OutCol["zlwr"].append(OutCol["zlwr"][k-1] + dz_l3)
	
	for k in range(atm_grid.nlwr_a[2],atm_grid.nlwr_a[3]):
		OutCol["zlwr"].append(OutCol["zlwr"][k-1] + dz_l4)
	
	##Temperature and Humidity at Levels
	# Surface
	var tamz : float = t_prof(zs, OutCol["zlwr"][0],tam, gams, gamb, gamt, htrop, 0)
	OutCol["tlwr"] = []
	OutCol["qlwr"] = []
	OutCol["tlwr"].append(tamz)
	OutCol["qlwr"].append(Constants.FQSAT_sp(OutCol["tlwr"][0], atmosphere_parameters.p0 * exp(-OutCol["zlwr"][0] / atmosphere_parameters.atmosphere_scale)) * ram)
	
	#Troposphere
	for k in range(1,atm_grid.nlwr_a[2]):
		OutCol["tlwr"].append(t_prof(zs, OutCol["zlwr"][k],tam, gams, gamb, gamt, htrop, 1))
		var rqlwr : float = rh_prof(zs, OutCol["zlwr"][k], ram, hrm, htrop)
		OutCol["qlwr"].append(Constants.FQSAT_sp(OutCol["tlwr"][k], atmosphere_parameters.p0 * exp(-OutCol["zlwr"][k] / atmosphere_parameters.atmosphere_scale)) * rqlwr)
	
	#Stratosphere
	var qtrop : float = Constants.FQSAT_sp(ttrop, atmosphere_parameters.p0 * exp(-htrop / atmosphere_parameters.atmosphere_scale)) * atmosphere_parameters.rh_strat
	for k in range(atm_grid.nlwr_a[2] + 1,atm_grid.nlwr_a[3]):
		OutCol["tlwr"].append(ttrop)
		OutCol["qlwr"].append(qtrop)
	
	#Feedback analysis
	if(gams_q != -INF):
		tamz = t_prof(zsa, OutCol["zlwr"][0], tam_q, gams_q, gamb_q, gamt_q, htrop_q, 0)
		qtrop = Constants.FQSAT_sp(ttrop_q, atmosphere_parameters.p0 * exp(-htrop_q / atmosphere_parameters.atmosphere_scale)) * atmosphere_parameters.rh_strat
		for k in range(1, atm_grid.nlwr_a[3]):
			#NOTICE: Possible issue at tropopause? Be on the lookout
			if(OutCol["zlwr"][k] <= (htrop_q + 10)):
				#Troposphere
				var tlwr_q : float = t_prof(zs, OutCol["zlwr"][k], tamz, gams_q, gamb_q, gamt_q, htrop_q, 1)
				var rqlwr : float = rh_prof(zs, OutCol["zlwr"][k], ram, hrm, htrop_q)
				OutCol["qlwr"][k] = Constants.FQSAT_sp(tlwr_q, atmosphere_parameters.p0 * exp(-OutCol["zlwr"][k] / atmosphere_parameters.atmosphere_scale)) * rqlwr
			else:
				#Stratosphere
				OutCol["qlwr"][k] = qtrop
	
	OutCol["O3lwr"] = []
	if(atmosphere_parameters.l_o3):
		#interpolate Ozone to Longwave Radiation levels
		for k in range(0,atm_grid.nlwr_a[3]):
			if(OutCol["zlwr"][k] < atm_grid.zl[0]):
				var w = (OutCol["zlwr"][k] - atm_grid.zl[0]) / (atm_grid.zl[1] - atm_grid.zl[0])
				OutCol["O3lwr"].append((1 - w) * O3[0] + w * O3[1])
			elif (OutCol["zlwr"][k] >= atm_grid.zl[atm_grid.kmc]):
				var w = (OutCol["zlwr"][k] - atm_grid.zl[0]) / (atm_grid.zl[atm_grid.kmc] - atm_grid.zl[atm_grid.kmc - 1])
				OutCol["O3lwr"].append((1 - w) * O3[atm_grid.kmc - 1] + w * O3[atm_grid.kmc])
			else:
				for kk in range(1, atm_grid.kmc):
					if((OutCol["zlwr"][k] >= atm_grid.zl[kk - 1]) and (OutCol["zlwr"][k] <= atm_grid.zl[kk])):
						var w = (OutCol["zlwr"][k] - atm_grid.zl[0]) / (atm_grid.zl[kk] - atm_grid.zl[kk - 1])
						OutCol["O3lwr"].append((1 - w) * O3[kk - 1] + w * O3[kk])
	else:
		OutCol["O3lwr"].append(0)
	
	return OutCol

#computation of long-wave radiation transfer
func lwr_transfer(ra2 : float, clot : float, zlwr : Array[float], tlwr : Array[float], qlwr : Array[float], o3lwr : Array[float], q_co2 : float):
	var OutCol : Dictionary = {}
	OutCol["BSB"] = []
	OutCol["DCS"] = []
	OutCol["DCL"] = []
	OutCol["DCS"].resize(atm_grid.llwr)
	OutCol["DCL"].resize(atm_grid.llwr)
	var ksize : Array[float] = []
	ksize.resize(atm_grid.llwr)
	OutCol["DCS"].fill(ksize)
	OutCol["DCL"].fill(ksize)
	
	var expc : Array[float] = []
	var am_cld : Array[float] = []
	var am_o3 : Array[float] = []
	var am_wv : Array[float] = []
	var am_co2 : Array[float] = []
	expc.resize(atm_grid.llwr + 5)
	am_cld.resize(atm_grid.llwr + 5)
	am_o3.resize(atm_grid.llwr + 5)
	am_wv.resize(atm_grid.llwr + 5)
	am_co2.resize(atm_grid.llwr + 5)
	
	#Conversion to "CGS" units
	var rhos : float = ra2 * 0.001
	var zsur : float = zlwr[0] * 100
	var kappa_co2 : float = (atmosphere_parameters.ak_co2 + 1) / h0_lw
	
	#Intermediate levels
	for k in range(atm_grid.llwr):
		var zlsk : float = zlwr[k] * 100
		expc[k] = exp(-kappa_co2 * zlsk)
		OutCol["BSB"].append(emis_lw * Constants.StefanBoltzmanConstant * tlwr[k] ** 4)
	
	#Absorption in the layers
	
	for k in range(atm_grid.llwr - 1):
		var Z1 : float = zlwr[k] * 100
		var Z2 : float = zlwr[k + 1] * 100
		var Zm : float = 0.5 * (Z1 + Z2)
		var dZ : float = Z2 - Z1
		
		var hq : float = 0
		#Water Vapor
		var ql1 : float = qlwr[k]
		var ql2 : float = qlwr[k + 1]
		if ((ql1 > ql2) and (ql2 > 0)):
			#Assume exponential
			hq = min(dZ / log(ql1 / ql2), h0_lw)
		else:
			hq = h0_lw
		var kappa_wv : float = (atmosphere_parameters.ak_wv + 1) / h0_lw + 1 / hq
		am_wv[k] = rhos * ql1 * exp(Z1 / hq + zsur / h0_lw) / kappa_wv * (exp(-kappa_wv * Z1) - exp(-kappa_wv * Z2))
		
		#Co2
		am_co2[k] = q_co2 / kappa_co2 * (expc[k] - expc[k + 1])
		
		#Ozone
		if(atmosphere_parameters.l_o3):
			am_o3[k] = atmosphere_parameters.ra * 1e-3 * exp(-Zm * (ak_o3_lw + 1) - h0_lw) * 0.5 * (o3lwr[k] + o3lwr[k + 1]) * dZ
		else:
			am_o3[k] = 0
		
		#Clouds
		if(atmosphere_parameters.i_lw_Cloud == 1):
			#Clouds later
			am_cld[k] = 0
		elif(atmosphere_parameters.i_lw_Cloud == 2):
			#Clouds now :)
			if ((k>=atm_grid.llwr_a[0]) and (k<atm_grid.llwr_a[1])):
				#in the clouds :)
				am_cld[k] = clot / atm_grid.nlwr_a[k]
			else:
				am_cld[k] = 0
	
	#ITFs
	for k in range(atm_grid.llwr_a[0]-1):
		var am_cld_kl : float = 0
		var am_o3_kl : float = 0
		var am_wv_kl : float = 0
		var am_co2_kl : float = 0
		for l in range(k+1, atm_grid.llwr):
			am_cld_kl = am_cld_kl + am_cld[l-1]
			am_o3_kl = am_o3_kl + am_o3[l-1]
			am_wv_kl = am_wv_kl + am_wv[l-1]
			am_co2_kl = am_co2_kl + am_co2[l-1]
			
			#From equation 6.7 in PIK report 81 
			var d_o3 : float = 1 - a_o3_lw * (am_o3_kl ** beta_o3_lw)
			
			#Equation 6.5 of the PIK report 81
			var d_vap : float = 1 / (1 + atmosphere_parameters.a_vap * ((beta0_lw * am_wv_kl) ** atmosphere_parameters.beta_vap) + atmosphere_parameters.a2_vap * ((beta0_lw * am_wv_kl) + atmosphere_parameters.a3_vap * ((beta0_lw * am_wv_kl) ** 3)))
			
			#Modification of Equation 6.6 (Valid for up to 20x CO2 of present day). Additional factor includes CO2 radiative forcing at increasing CO2 levels
			var d_co2 : float = (1 - 0.1 * (am_co2_kl/1000) ** 2) * (1 + a0_co2_lw * a1_co2_lw * ((beta0_lw * am_co2_kl) ** atmosphere_parameters.beta_co2)) / (1 + a0_co2_lw * ((beta0_lw * am_co2_kl) ** atmosphere_parameters.beta_co2))
			
			#Clouds
			var d_cld : float = exp(-atmosphere_parameters.c_lw_CloudOpticalThickness * am_cld_kl)
			
			OutCol["DCS"][l][k] = d_vap * d_co2 * d_o3
			OutCol["DCL"][l][k] = d_vap * d_co2 * d_cld
	
	#Symmetry
	for l in range(atm_grid.llwr - 1):
		for k in range(atm_grid.llwr):
			OutCol["DCS"][l][k] = OutCol["DCS"][k][l]
			OutCol["DCL"][l][k] = OutCol["DCL"][k][l]
	
	#Diagonal
	for k in range(atm_grid.llwr):
		OutCol["DCS"][k][k] = 1
		OutCol["DCL"][k][k] = 1
	
	return OutCol

#computation of long-wave radiation fluxes for clear sky conditions
func lwr_clear_sky(flwr_up_sur : float, BSB : Array[float], DCS : Array[Array]):
	var OutCol : Dictionary = {}
	OutCol["fcs_up"] = []
	OutCol["fcs_dw"] = []
	OutCol["fcs_up"].resize(atm_grid.llwr)
	OutCol["fcs_dw"].resize(atm_grid.llwr)
	
	#Upward Flux
	OutCol["fcs_up"][0] = flwr_up_sur
	for k in range(1,atm_grid.llwr):
		OutCol["fcs_up"][k] = BSB[k] + (OutCol["fcs_up"][0] - BSB[k] * DCS[k][1])
		for l in range(k - 1):
			OutCol["fcs_up"][k] = OutCol["fcs_up"][k] - (BSB[l + 1] - BSB[l]) * 0.5 * (DCS[k][l + 1] + DCS[k][l])
	#Downward Flux
	OutCol["fcs_dw"][0] = 0
	for k in range(atm_grid.llwr - 1, 0, -1):
		OutCol["fcs_dw"][k] = BSB[k] - BSB[atm_grid.llwr] * DCS[k][atm_grid.llwr]
		for l in range(k - 1):
			OutCol["fcs_dw"][k] = OutCol["fcs_dw"][k] + (BSB[l + 1] - BSB[l]) * 0.5 * (DCS[k][l] + DCS[k][l + 1])
	return OutCol

#computation of long-rave radiation fluxes for cloudy conditions
func lwr_clouds(flwr_up_sur : float, BSB : Array[float], DCL : Array[Array]):
	var OutCol : Dictionary = {}
	OutCol["fcl_up"] = []
	OutCol["fcl_dw"] = []
	OutCol["fcl_up"].resize(atm_grid.llwr)
	OutCol["fcl_dw"].resize(atm_grid.llwr)
	
	if(atmosphere_parameters.i_lw_Cloud == 1):
		##Blackbody Clouds
		#Upward Flux
		OutCol["fcl_up"][0] = flwr_up_sur
		for k in range(1,atm_grid.llwr_a[0]):
			OutCol["fcl_up"][k] = BSB[k] + (OutCol["fcl_up"][1]-BSB[1]) * DCL[k][1]
			for l in range(k - 1):
				OutCol["fcl_up"][k] = OutCol["fcl_up"][k] - (BSB[l + 1] - BSB[l]) * 0.5 * (DCL[k][l + 1] + DCL[k][l])
		for k in range(atm_grid.llwr_a[0] + 1,atm_grid.llwr_a[1]):
			OutCol["fcl_up"][k] = BSB[k]
		for k in range(atm_grid.llwr_a[1] + 1,atm_grid.llwr):
			OutCol["fcl_up"][k] = BSB[k]
			for l in range(k - 1):
				OutCol["fcl_up"][k] = OutCol["fcl_up"][k] - (BSB[l + 1] - BSB[l]) * 0.5 * (DCL[k][l + 1] + DCL[k][l])
		
		#Downward Flux
		OutCol["fcl_up"][atm_grid.llwr] = 0
		for k in range(atm_grid.llwr - 1, atm_grid.llwr_a[1] - 1, -1):
			OutCol["fcl_up"][k] = BSB[k] - BSB[atm_grid.llwr] * DCL[k][atm_grid.llwr]
			for l in range(k - 1):
				OutCol["fcl_up"][k] = OutCol["fcl_up"][k] + (BSB[l + 1] - BSB[l]) * 0.5 * (DCL[k][l] + DCL[k][l + 1])
		for k in range(atm_grid.llwr_a[1] - 1, atm_grid.llwr_a[0] - 1, -1):
			OutCol["fcl_up"][k] = BSB[k]
		for k in range(atm_grid.llwr_a[0] - 1, 1, -1):
			OutCol["fcl_up"][k] = BSB[k]
			for l in range(k - 1):
				OutCol["fcl_up"][k] = OutCol["fcl_up"][k] + (BSB[l + 1] - BSB[l]) * 0.5 * (DCL[k][l] + DCL[k][l + 1])
	
	
	elif (atmosphere_parameters.i_lw_Cloud == 2):
		##Optical Thickness Clouds
		#Upward Flux
		OutCol["fcl_up"][0] = flwr_up_sur
		for k in range(1,atm_grid.llwr):
			OutCol["fcl_up"][k] = BSB[k] + (OutCol["fcl_up"][1]-BSB[1]) * DCL[k][1]
			for l in range(k - 1):
				OutCol["fcl_up"][k] = OutCol["fcl_up"][k] - (BSB[l + 1] - BSB[l]) * 0.5 * (DCL[k][l + 1] + DCL[k][l])
		
		#Downward Flux
		OutCol["fcl_up"][atm_grid.llwr] = 0
		for k in range(atm_grid.llwr - 1, 0, -1):
			OutCol["fcl_up"][k] = BSB[k] - BSB[atm_grid.llwr] * DCL[k][atm_grid.llwr]
			for l in range(k - 1):
				OutCol["fcl_up"][k] = OutCol["fcl_up"][k] + (BSB[l + 1] - BSB[l]) * 0.5 * (DCL[k][l] + DCL[k][l + 1])
	
	return OutCol

## Feedbacks
#Initializes feedback anaylsis
func feedback_init():
	var emptyArray : Array[float] = []
	emptyArray.resize(model_timer.DaysPerYear)
	
	FB_tam = []
	FB_tam.resize(atm_grid.OutputArray.size())
	FB_tam.fill(emptyArray)
	
	FB_cld = []
	FB_cld.resize(atm_grid.OutputArray.size())
	FB_cld.fill(emptyArray)
	
	FB_hcld = []
	FB_hcld.resize(atm_grid.OutputArray.size())
	FB_hcld.fill(emptyArray)
	
	FB_clot = []
	FB_clot.resize(atm_grid.OutputArray.size())
	FB_clot.fill(emptyArray)
	
	FB_gams = []
	FB_gams.resize(atm_grid.OutputArray.size())
	FB_gams.fill(emptyArray)
	
	FB_gamb = []
	FB_gamb.resize(atm_grid.OutputArray.size())
	FB_gamb.fill(emptyArray)
	
	FB_gamt = []
	FB_gamt.resize(atm_grid.OutputArray.size())
	FB_gamt.fill(emptyArray)
	
	FB_htrop = []
	FB_htrop.resize(atm_grid.OutputArray.size())
	FB_htrop.fill(emptyArray)
	
	FB_ttrop = []
	FB_ttrop.resize(atm_grid.OutputArray.size())
	FB_ttrop.fill(emptyArray)
	
	FB_ram = []
	FB_ram.resize(atm_grid.OutputArray.size())
	FB_ram.fill(emptyArray)
	
	FB_hrm = []
	FB_hrm.resize(atm_grid.OutputArray.size())
	FB_hrm.fill(emptyArray)
	
	FB_hqeff = []
	FB_hqeff.resize(atm_grid.OutputArray.size())
	FB_hqeff.fill(emptyArray)
	
	FB_aerosol_ot = [] 
	FB_aerosol_ot.resize(atm_grid.OutputArray.size())
	FB_aerosol_ot.fill(emptyArray)
	
	FB_aerosol_im = []
	FB_aerosol_im.resize(atm_grid.OutputArray.size())
	FB_aerosol_im.fill(emptyArray)
	
	FB_so4 = []
	FB_so4.resize(atm_grid.OutputArray.size())
	FB_so4.fill(emptyArray)
	
	FB_frst = []
	FB_frst.resize(atm_grid.OutputArray.size())
	FB_frst.fill(emptyArray)
	
	FB_tskin = []
	FB_tskin.resize(atm_grid.OutputArray.size())
	FB_tskin.fill(emptyArray)
	
	FB_t2 = []
	FB_t2.resize(atm_grid.OutputArray.size())
	FB_t2.fill(emptyArray)
	
	FB_q2 = []
	FB_q2.resize(atm_grid.OutputArray.size())
	FB_q2.fill(emptyArray)
	
	var heights : Array[Array] = []
	heights.resize(atm_grid.numSurfaceTypes)
	heights.fill(emptyArray)
	
	FB_alb_vu_s = []
	FB_alb_vu_s.resize(atm_grid.OutputArray.size())
	FB_alb_vu_s.fill(heights)
	
	FB_alb_vu_c = []
	FB_alb_vu_c.resize(atm_grid.OutputArray.size())
	FB_alb_vu_c.fill(heights)
	
	FB_alb_ir_s = []
	FB_alb_ir_s.resize(atm_grid.OutputArray.size())
	FB_alb_ir_s.fill(heights)
	
	FB_alb_ir_c = []
	FB_alb_ir_c.resize(atm_grid.OutputArray.size())
	FB_alb_ir_c.fill(heights)
	
	FB_flwr_up_sur = []
	FB_flwr_up_sur.resize(atm_grid.OutputArray.size())
	FB_flwr_up_sur.fill(heights)
	
	
	FB_tg = [0,0]
	FB_delta_t = 0
	FB_rf_top_avg = 0
	FB_rf_trop_avg = 0
	
	FB_rf_top = []
	FB_rf_top.resize(atm_grid.OutputArray.size())
	FB_rf_top.fill(0)
	
	FB_rf_trop = []
	FB_rf_trop.resize(atm_grid.OutputArray.size())
	FB_rf_trop.fill(0)
	
	FB_dhtrop_rf = []
	FB_dhtrop_rf.resize(atm_grid.OutputArray.size())
	FB_dhtrop_rf.fill(0)
	
	var NFB_Array : Array[float] = []
	NFB_Array.resize(nfb + 1)
	
	FB_flwr_top = []
	FB_flwr_top.resize(atm_grid.OutputArray.size())
	FB_flwr_top.fill(NFB_Array)
	
	FB_fswr_top = []
	FB_flwr_top.resize(atm_grid.OutputArray.size())
	FB_flwr_top.fill(NFB_Array)
	
	NFB_Array.resize(nfb)
	
	FB_d_flwr_top = []
	FB_d_flwr_top.resize(atm_grid.OutputArray.size())
	FB_d_flwr_top.fill(NFB_Array)
	
	FB_d_fswr_top = []
	FB_d_fswr_top.resize(atm_grid.OutputArray.size())
	FB_d_fswr_top.fill(NFB_Array)
	
	FB_d_f_top = []
	FB_d_f_top.resize(atm_grid.OutputArray.size())
	FB_d_f_top.fill(NFB_Array)

##### CHECK HERE FOR TERM DEFINITIONS! #####
#Saves variables for feedback analysis
func feedback_save():
	var t2 : Array[Array] = []
	var frst : Array[Array] = []
	for i in atm_grid.OutputArray.size():
		FB_tam[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Temp
		FB_cld[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Fraction
		FB_hcld[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Height
		FB_clot[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Cloud_Optical_Thickness
		FB_gams[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).LapseRate_BoundaryLayer
		FB_gamb[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Lower_Tropo
		FB_gamt[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).LapseRate_Upper_Tropo
		FB_htrop[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Height
		FB_ttrop[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Tropopause_Temperature
		FB_ram[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Extrapolated_Surface_Relative_Humidity
		FB_hrm[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Vertical_Humidity_Scale
		FB_hqeff[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Vertical_Effective_Humidity_Scale
		FB_aerosol_ot[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Aerosol_Optical_Thickness
		FB_aerosol_im[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Aersol_Imaginary_Refractive_Index
		FB_so4[i][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).SO4_Load
		frst.append([])
		t2.append([])
		for n in range(atm_grid.numSurfaceTypes):
			FB_frst[i][n][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).frst[n]
			frst[i].append((atm_grid.OutputArray[i] as ATM_CELL).frst[n])
			FB_tskin[i][n][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Skin_Temp[n]
			FB_t2[i][n][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Air_Temp_2m[n]
			frst[i].append((atm_grid.OutputArray[i] as ATM_CELL).Air_Temp_2m[n])
			FB_q2[i][n][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Relative_Humidity_2m[n]
			FB_alb_vu_s[i][n][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Albedo_Clear_VisUV[n]
			FB_alb_vu_c[i][n][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Albedo_Cloudy_VisUV[n]
			FB_alb_ir_s[i][n][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Albedo_Clear_IR[n]
			FB_alb_ir_c[i][n][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).Albedo_Cloudy_IR[n]
			FB_flwr_up_sur[i][n][model_timer.DayOfYear] = (atm_grid.OutputArray[i] as ATM_CELL).flwr_up_sur[n]
	
	#Circle back to this calculation. Need replacement for sqr term to allow math to work
	FB_tg[0] = FB_tg[0] + sum(t2,frst,2,(atm_grid.surfaceTypes.SIC as int)) / model_timer.DaysPerYear
	
	#This next part fills me with pain. Not gonna do it for now

func feedback_analysis():
	pass

func feedback_write():
	pass
