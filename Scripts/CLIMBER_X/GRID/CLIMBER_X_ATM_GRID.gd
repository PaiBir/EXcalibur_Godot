class_name ATM_GRID
extends Node

@export var ModelIntialized : bool = false
@export var atmosphere_parameters : ATM_PARAM
#var nml : NML
@export var climber_grid : GRID
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
var dy : float #Dunno what these are
var esqr : float
var dxt : Array[float]

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
var dplp : Array[Array] = [[],[]] #float
var dplpo : Array[Array] = [[],[]] #float
var kplpo : Array[int] = []
var exp_zc : Array[float] = []

func atm_grid_init(fromFile : bool = false) -> int:
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
			dpl.append(0)
			zc.append(0)
			dplp[1].append(0)
			dplpo[1].append(0)
			exp_zc.append(0)
		for i in range(0,climber_grid.OutputArray[0].size()):
			dplp[0].append(0)
			dplpo[0].append(0)
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
		esqr = (Constants.basePointDistEarth * atmosphere_parameters.Planet.PlanetRadius) * (1.96838 * pow(0.508771,climber_grid.subdivLevel))
		dy = PI * (atmosphere_parameters.Planet.PlanetRadius * (Constants.EarthDiameter/2.0))
		
		#Leaving out the establishment of fit, fiu, thetat, cost, ect. because it appears to be grid-specific
		
		#Coriolis stuff
		for i in range(0,climber_grid.OutputArray[0].size()):
			dxt.append(dy*cos(PI * (-climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.LATLONGPOSITION][i].y) / 180.0))
			#I don't actually understand what fit and fiu are calculating. This requires additional research because Climber-X is lacking in comments
			var coriolispos = sin(PI * (-climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.LATLONGPOSITION][i].y) / 180.0)
			var direction = 1
			if(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.LATLONGPOSITION][i].y<0):
				direction = -1
			if(atmosphere_parameters.Planet.DaysSpeed < 0):
				direction = direction * -1
			var cforce = 2*(Constants.EarthAngularVelocity*atmosphere_parameters.Planet.DaysSpeed)*coriolispos
			#These might be entirely wrong. I don't know right now. The way it handles the coriolis effect makes little to no sense
			climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.CORIOLISEFFECT][i] = direction * max(abs(cforce),atmosphere_parameters.fcormin)
			climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.CORIOLISEFFECTFAST][i] = direction * max(abs(cforce),atmosphere_parameters.fcorumin)
			
			climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.PLANETARYBOUNDARYLAYER][i] = atmosphere_parameters.pblp - (atmosphere_parameters.pblp - atmosphere_parameters.pble)*pow(cos(PI * (-climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.LATLONGPOSITION][i].y) / 180.0),2)
		
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
		
		for i in range(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.KINDEXEFFECTIVE].size()):
			climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.KINDEXEFFECTIVE][i] = 4
		
		
	ModelIntialized = true
	return 0

func atm_grid_update(first:Array[Array]):
	for i in range(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.ZS].size()):
		climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.ZS][i] = zsa_scale * climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.ZS][i]
	for i in range(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.ZS].size()):
		climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE][i] = zsa_scale * climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE][i]
		climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE][i] = climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE][i] * zsa_scale_dyn
	var zsa_smooth = smooth_atm_mod.smooth2(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE],climber_grid.MeshTris,nsmooth_zsa)
	
	#topography
	for i in range(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE].size()):
		var ValidInts : Array[int] = []
		for tri in climber_grid.MeshTris:
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
			slope += (min(3000, climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE][i]) - min(3000, climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE][j]))/dxt[i]
		climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SLOPE][i] = slope
	var smoothslope = smooth_atm_mod.smooth2(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SLOPE],climber_grid.MeshTris,1)
	climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SLOPE] = smoothslope
	
	for i in range(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.PRESSUREATSURFACE]):
		climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.PRESSUREATSURFACE][i] = exp(-climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE][i]/atmosphere_parameters.atmosphere_scale)
	
	for i in range(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.PRESSUREATSURFACE_SMOOTH]):
		climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.PRESSUREATSURFACE_SMOOTH][i] = exp(-climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE_SMOOTH][i]/atmosphere_parameters.atmosphere_scale)
	
	if (!atmosphere_parameters.l_p0_var):
		var deltapressure = 0
		for i in range(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE].size()):
			deltapressure += exp(-climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE][i] /  atmosphere_parameters.atmosphere_scale) * ((dxt[i]*dy)/esqr)
		atmosphere_parameters.p0 = atmosphere_parameters.ps0 / deltapressure #Average sea level pressure
	
	atmosphere_parameters.amas = atmosphere_parameters.p0 / atmosphere_parameters.Planet.Gravity #Average mass of atmospheric column
	
	atmosphere_parameters.ra = atmosphere_parameters.p0 / (Constants.specificGasConstant_dryair * Constants.ZeroCelsius)
	 

	for i in range(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.KINDEXTERRAIN].size()):
		for j in range(km):
			#K-index of first layer above topography
			if(zc[j] >= climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE][i]):
				climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.KINDEXTERRAIN][i] = j
			#K index for vertical velocity for clouds
			if(zc[j] > max(climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.SURFACE][i], atmosphere_parameters.hcld_base)):
				climber_grid.OutputArray[OUTPUTTER.OUTPUTARRAY.KINDEXCLOUDS][i] = j
		
	
	return {"zsa_smooth" : zsa_smooth}
