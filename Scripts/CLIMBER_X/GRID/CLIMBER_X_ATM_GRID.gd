class_name ATM_GRID
extends GRID

@export var ModelIntialized : bool = false
@export var atmosphere_parameters : ATM_PARAM
#var nml : NML
@export var smooth_atm_mod : SMOOTHER
@export var OutputController : OUTPUTTER

var km : int
var kmc : int
var numSurfaceTypes : int = 5
enum surfaceTypes {
	OCEAN,
	SIC, #Dunno what sic is yet
	LAND,
	ICE,
	LAKE
}
var zsa_scale : float
var zsa_scale_dyn : float
var nsmooth_zsa : int
var llwr : int
var nlwr_a : Array[int] = [0,0,0,0]
var llwr_a : Array[int] = [0,0,0,0]

##A lot of variables relating to the grid are being left out because they do not apply to a geodesic grid

var surfaceArea : float = 4.0 * PI * pow(atmosphere_parameters.Planet.PlanetRadius * (Constants.EarthDiameter/2.0),2.0)
var dy : float
var esqr : float
var dxt : Array[float]

var plp : Array[float] = []
##To make it fit every planet better, pressure levels can be configured
var k_pressures = [
	{"index" : -1, "pressure" : 1, "pointapproach":100},
	{"index" : -1, "pressure" : .85, "pointapproach":100},
	{"index" : -1, "pressure" : .7, "pointapproach":100},
	{"index" : -1, "pressure" : .5, "pointapproach":100},
	{"index" : -1, "pressure" : .3, "pointapproach":100},
]

var pl : Array[float] = []
var dpl : Array[float] = []
var zl : Array[float] = []
var zc : Array[float] = []
var dplp : Array[Array] = [] #float
var dplpo : Array[Array] = [] #float
var kplpo : Array[int] = []
var exp_zc : Array[float] = []

func atm_grid_init(fromFile : bool = false) -> int:
	climber_grid_init(GRID.GridType.ATMOSPHERIC)
	#This won't alway be loaded from a file. See the atmosphere parameters for an idea of how this will generally be operated
	if(fromFile):
		var AtmParams = FileAccess.open(atmosphere_parameters.Output.OutputDirectory + "/CLIMBER_Model/Atmosphere/atm_param.json",FileAccess.READ)
		var JSONlines = AtmParams.get_line()
		AtmParams.close()
		var JSONER = JSON.new()
		JSONER.parse(JSONlines)
		llwr = JSONER.data["llwr"]
		km = JSONER.data["km"]
		zsa_scale = JSONER.data["zsa_scale"]
		zsa_scale_dyn = JSONER.data["zsa_scale_dyn"]
		nsmooth_zsa = JSONER.data["nsmooth_zsa"]
		
		for i in range(0,kmc):
			zl.append(0)
		for i in range(0,km):
			zc.append(0)
			exp_zc.append(0)
		for i in range(0,OutputArray.size()):
			dplp.append([])
			dplpo.append([])
			plp.append([])
			for j in range(0,km):
				dplp.append(0)
				dplpo.append(0)
				plp.append(0)
			kplpo.append(0)
		
		pl = JSONER.data["pl"]
		
		if((llwr%5) != 0):
			printerr("atm_grid_init(): Initialization failure, llwr is not a multiple of 5 (%d)" % llwr)
			return 1
		nlwr_a[0] = int(llwr/5.0*2.0)
		nlwr_a[1] = int(llwr/5.0)
		nlwr_a[2] = int(llwr/5.0)
		nlwr_a[3] = int(llwr/5.0)
		llwr_a[0] = nlwr_a[0]
		llwr_a[1] = llwr_a[0]+nlwr_a[1]
		llwr_a[2] = llwr_a[1]+nlwr_a[2]
		llwr_a[3] = llwr_a[3]+nlwr_a[4]
		if (llwr_a[3] != llwr):
			printerr("atm_grid_init(): Initialiation failure, llwr_a[3] is not equal to llwr (%d != %d)" % [llwr_a[3], llwr])
			return 1
		
		#Geodesic Grid, this part has to be made custom for EXcalibur, because ClimberX is built for a rectangular grid
		esqr = (Constants.basePointDistEarth * atmosphere_parameters.Planet.PlanetRadius) * (1.96838 * pow(0.508771,subdivLevel))
		dy = PI * (atmosphere_parameters.Planet.PlanetRadius * (Constants.EarthDiameter/2.0))
		
		#Leaving out the establishment of fit, fiu, thetat, cost, ect. because it appears to be grid-specific
		
		#Coriolis stuff
		for i in range(0,OutputArray.size()):
			dxt.append(dy*cos(PI * (-OutputArray[i].LatLong.y) / 180.0))
			OutputArray[i].sqr = dxt[i]*dy
			#I don't actually understand what fit and fiu are calculating. This requires additional research because Climber-X is lacking in comments
			var coriolispos = sin(PI * (-OutputArray[i].LatLong.y) / 180.0)
			var direction = 1
			if(OutputArray[i].LatLong.y<0):
				direction = -1
			if(atmosphere_parameters.Planet.DaysSpeed < 0):
				direction = direction * -1
			var cforce = 2*(Constants.EarthAngularVelocity*atmosphere_parameters.Planet.DaysSpeed)*coriolispos
			#These might be entirely wrong. I don't know right now. The way it handles the coriolis effect makes little to no sense
			OutputArray[i].Coriolis_Effect = direction * max(abs(cforce),atmosphere_parameters.fcormin)
			OutputArray[i].Coriolis_Effect_Fast = direction * max(abs(cforce),atmosphere_parameters.fcorumin)
			
			OutputArray[i].Planetary_Boundary_Layer = atmosphere_parameters.pblp - (atmosphere_parameters.pblp - atmosphere_parameters.pble)*pow(cos(PI * (-OutputArray[i].LatLong.y) / 180.0),2)
		
		#Pressure stuff
		atmosphere_parameters.ra = atmosphere_parameters.p0 / (Constants.specificGasConstant_dryair * Constants.ZeroCelsius)
		atmosphere_parameters.ps0 = atmosphere_parameters.atmosphere_mass/(esqr * atmosphere_parameters.Planet.Gravity)
		for i in range(km):
			dpl.append(pl[i] + pl[i+1])
			zl.append(-atmosphere_parameters.atmosphere_scale*log(pl[i]))
		
		#Layer centers
		for i in range(km):
			zc.append(0.5*(zl[i+1]+zl[i]))
			exp_zc.append(exp(-zc[i] / atmosphere_parameters.atmosphere_scale))
		
		
		for i in range(pl):
			for entry in k_pressures:
				if(pl[i]-entry["pressure"]<entry["pointapproach"]):
					entry["index"] = i
		
		for i in range(OutputArray.size()):
			OutputArray[i].K_Index_Effective = 4
		
		
	ModelIntialized = true
	return 0

func atm_grid_update(frst:Array[Array]):
	var SmoothingArray = []
	for i in range(OutputArray.size()):
		for j in (OutputArray[i].ZS.size()):
			OutputArray[i].ZS[j] = zsa_scale * OutputArray[i].ZS[j]
		OutputArray[i].Surface = zsa_scale * OutputArray[i].Surface
		SmoothingArray.append(OutputArray[i].Surface * zsa_scale_dyn)
	var zsa_smooth = smooth_atm_mod.smooth2(SmoothingArray,MeshTris,nsmooth_zsa)
	for i in range(SmoothingArray.size()):
		OutputArray[i].Surface_Smooth = zsa_smooth[i]
	
	#topography
	var slopes = []
	for i in range(OutputArray.size()):
		var ValidInts : Array[int] = []
		for tri in MeshTris:
			if (tri.find(i) != -1):
				if(ValidInts.find(tri[0]) == -1):
					ValidInts.append(tri[0])
				if(ValidInts.find(tri[1]) == -1):
					ValidInts.append(tri[1])
				if(ValidInts.find(tri[2]) == -1):
					ValidInts.append(tri[2])
		if(ValidInts.find(i) != -1):
			ValidInts.remove_at(ValidInts.find(i))
		var slope = 0
		for j in ValidInts:
			slope += (min(3000, OutputArray[i].Surface) - min(3000, OutputArray[j].slope))/dxt[i]
		slopes.append(slope)
	var smoothslope = smooth_atm_mod.smooth2(slopes,MeshTris,1)
	for i in range(smoothslope.size()):
		OutputArray[i].Slope = smoothslope[i]
	
	for i in range(OutputArray.size()):
		OutputArray[i].Pressure_At_Surface = exp(-OutputArray[i].Surface/atmosphere_parameters.atmosphere_scale)
		OutputArray[i].Pressure_At_Surface_Smooth = exp(-OutputArray[i].Surface_Smooth/atmosphere_parameters.atmosphere_scale)
	
	if (!atmosphere_parameters.l_p0_var):
		var deltapressure = 0
		for i in range(OutputArray.size()):
			deltapressure += exp(-OutputArray[i].Surface /  atmosphere_parameters.atmosphere_scale) * ((dxt[i]*dy)/esqr)
		atmosphere_parameters.p0 = atmosphere_parameters.ps0 / deltapressure #Average sea level pressure
	
	atmosphere_parameters.amas = atmosphere_parameters.p0 / atmosphere_parameters.Planet.Gravity #Average mass of atmospheric column
	
	atmosphere_parameters.ra = atmosphere_parameters.p0 / (Constants.specificGasConstant_dryair * Constants.ZeroCelsius)
	 

	for i in range(OutputArray.size()):
		for j in range(km):
			#K-index of first layer above topography
			if(zc[j] >= OutputArray[i].Surface):
				OutputArray[i].K_Index_Terrain = j
			#K index for vertical velocity for clouds
			if(zc[j] > max(OutputArray[i].Surface, atmosphere_parameters.CloudHeight_Base)):
				OutputArray[i].K_Index_Effective = j
		#Surface air stuff based on elevation
		OutputArray[i].Surface_Air_Density = OutputArray[i].Pressure_At_Surface*exp(-OutputArray[i].Surface / atmosphere_parameters.atmosphere_scale)
		OutputArray[i].ra2a = 0
		for l in range(numSurfaceTypes):
			OutputArray[i].ra2[l] = atmosphere_parameters.ra * exp(-OutputArray[i].ZS[l] / atmosphere_parameters.atmosphere_scale)
			OutputArray[i].ra2a = OutputArray[i].ra2a + frst[i][l] * OutputArray[i].ra2[l]
			OutputArray[i].ps = atmosphere_parameters.p0 * exp(-OutputArray[i].ZS[l] / atmosphere_parameters.atmosphere_scale)
		#Some other stuff
		var ValidInts : Array[int] = []
		for tri in MeshTris:
			if (tri.find(i) != -1):
				if(ValidInts.find(tri[0]) == -1):
					ValidInts.append(tri[0])
				if(ValidInts.find(tri[1]) == -1):
					ValidInts.append(tri[1])
				if(ValidInts.find(tri[2]) == -1):
					ValidInts.append(tri[2])
		if(ValidInts.find(i) != -1):
			ValidInts.remove_at(ValidInts.find(i))
		for j in ValidInts:
			for k in range(km):
				var p = OutputArray[i].Pressure_At_Surface_Smooth
				if p <= pl[k+1]:
					dplp[i][k] = 0
				elif p < pl[k]:
					dplp[i][k] = p-pl[k+1]*atmosphere_parameters.atmosphere_mass
				else:
					dplp[i][k] = pl[k] - pl[k+1]*atmosphere_parameters.atmosphere_mass
				plp[i] = plp[i] + dplp[i][k]
				dplpo[i] = max(0,min(pl[k],max(OutputArray[j].Pressure_At_Surface_Smooth,OutputArray[i].Pressure_At_Surface_Smooth))-pl[k+1])*atmosphere_parameters.atmosphere_mass
				
				if(dplp[i][k] > 0):
					kplpo[i] = k
		
