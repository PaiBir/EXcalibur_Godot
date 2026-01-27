class_name ATM_PARAM
extends Node

@export var ModelIntialized : bool = false

@export var Planet : PlanetManager
@export var Output : OUTPUTTER
@export var ModelTimer : MODELTIMER
@export var Controller : CLIMBER_X_CONTROL

var timeStep : float
var nstep_fast : int

var fcormin : float
var fcoramin : float
var fcorumin : float

var l_sct_0 : bool
var l_alb_0 : bool
var f_ice_pow : float
var r_scat : float
var a1_w : float
var a2_w : float
var b1_w : float
var b2_w : float
var c_itf_c : float
var c_itf_cc : float

var l_so4_de : bool
var l_so4_ie : bool
var beta_so4 : float
var sigma_so4 : float
var r_so4 : float
var N_so4_nat : float

var i_mmc : int
var c_mmc_had : float
var c_mmc_fer : float
var c_mmc_pol : float
var c_mmc_z : float
var c_mmc : Array[float] = [0,0,0,0]
var pblp : float
var pble : float

var c_uter_pol : float
var c_uter_eq : float
var l_mass_com_topo : bool

var c_slp : Array[float] = [0,0,0,0,0]
var l_aslp_topo : bool
var c_aslp_topo : Array[float] = [0,0,0,0]

var zmax : float
var dpc : float
var pcmin : float
var pcmax : float
var ptopdyn : float

var hcld_base : float
var i_lw_cld : int
var c_lw_clot : float
var ak_co2 : float
var beta_co2 : float
var ak_wv : float
var a_vap : float
var beta_vap : float
var a2_vap : float
var beta2_vap : float
var a3_vap : float
var l_o3 : float
var ecs_scale : float
var ecs_scale_dT : float

var c_gam: Array[float] = [0,0,0,0,0,0]
var gams_max_lnd : float
var gams_min_ocn : float
var gams_max_ocn : float
var hgams : float
var hgamt : float
var nsmooth_gam : int
var c_gam_rel : float
var i_tsl : int
var i_tslz : int
var c_tsl_gam : float
var c_tsl_gam_ice : float
var tsl_gams_min_lnd : float
var tsl_gams_min_ice : float

var c_wrt : Array[float] = [0,0,0,0]

var c_hrs : Array[float] = [0,0,0,0,0,0]

var c_clot : Array[float] = [0,0,0,0]

var c_syn : Array[float] = [0,0,0,0,0,0,0,0]
var windmin : float
var synsurmin : float
var c_wind_ele : float
var c_diffx_energy : float
var c_diff_energy : float
var c_diffx_water : float
var c_diff_water : float
var i_diff_water : int
var i_diff_dust : float


var i_kata_wind : int
var h_kata : float

var cd0_ocn : float
var cd0_sic : float
var i_zoro : int
var i_acbar : int
var acbar_max : float
var acbar_scale : float

var c_cld : Array[float] = [0,0,0,0,0,0,0,0,0] #1, 2, 3, 4, 5, 55, 6, 7, 8, -> 0,1,2,3,4,5,6,7,8
var l_cld_low_ice : bool
var cld_max : float
var nsmooth_cld : int

var c_hcld : Array[float] = [0,0,0,0]

var c_weff : float
var c_woro : float

var i_rbstr : int
var c_trop : Array[float] = [0,0,0]

var i_pbl : int

var hpbl : float

var rh_max : float
var rskin_ocn_min : float
var rh_strat : float

var l_dust : bool
var l_dust_rad : bool
var c_dhs_1 : float
var c_dhs_2 : float
var c_dust_dry : float
var c_dust_wet : float
var c_dust_mec : float

var l_co2d : bool

var ars_ot : float
var ars_im : float

var nsmooth_cda : int
var nsmooth_weff : int
var nsmooth_aslp : int
var nsmooth_aslp_eq : int
var nj_eq : int
var nsmooth_aslp_topo : int
var nsmooth_acbar : int

var l_write_timer : bool
var l_daily_output : bool
var l_output_flx3d : bool
var l_output_extended : bool
var tam_init : float = 30 #initial equatorial temperature for CLIMBER_X
var cle = Constants.latentHeatEvap #J/kg
var cls = Constants.latentHeatSubl #J/kg
var epsilon : float = 0.001 #just needs to be small
var gad : float = 0 #K/m, "adiabatic lapse rate"
var atmosphere_scale : float = 1 #atmospheric height scale
var l_p0_var : bool #Does sea level pressure vary
var p0 : float #average sea level pressure (Pa)
var ps0 : float #average surface pressure (Pa)
var amas : float #kg/m^2, average mass of atmospheric column
var ra : float #kg/m^3, air density at p0
#THESE PROBABLY NEED TO BE REMOVED
var cp : float = 1000 #J/kg/K, specific heat of air at constant pressure
var cv : float = 715 #J/kg/K, specific heat of air at constant volume
var atmosphere_mass : float = 5.12e18 #kg, total mass of atmosphere. This WILL be replaced, mark my words

func atm_params_init(fromFile : bool):
	gad =  Planet.Gravity/ cp
	atmosphere_scale = (Constants.specificGasConstant_dryair * (Planet.Boss.starLuminosity/pow(2.52,Planet.Boss.BolometricCorrectionStrength)))/Planet.Gravity
	## If a file is being loaded, it makes sense to just pull the values here, and then maybe trigger a thing that updates the UI.
	## Otherwise, the UI should be setting all initial values automatically, 
	if(fromFile):
		var AtmParams = FileAccess.open(Output.OutputDirectory + "/CLIMBER_Model/Atmosphere/atm_param.json",FileAccess.READ)
		var JSONlines = AtmParams.get_line()
		AtmParams.close()
		var JSONER = JSON.new()
		JSONER.parse(JSONlines)
		atm_param_load(JSONER.data)
	
	timeStep = ModelTimer.dt_atm/nstep_fast
	#When UI-integrated, put a thing here to DISABLE ALL UI INPUTS FOR RUNTIME
	#Inform the model that settings are locked for running
	#It is go time
	ModelIntialized = true

func atm_param_load(data):
	nstep_fast = data["nstep_fast"]
	fcormin = data["fcormin"]
	fcoramin = data["fcoramin"]
	fcorumin = data["fcorumin"]
	f_ice_pow = data["f_ice_pow"]
	r_scat = data["r_scat"]
	l_sct_0 = data["l_sct_0"]
	l_alb_0 = data["l_alb_0"]
	a1_w = data["a1_w"]
	a2_w = 1-a1_w
	b1_w = data["b1_w"]
	b2_w = data["b2_w"]
	c_itf_c = data["c_itf_c"]
	c_itf_cc = data["c_itf_cc"]
	i_mmc = data["i_mmc"]
	c_mmc_had = data["c_mmc_had"]
	c_mmc_fer = data["c_mmc_fer"]
	c_mmc_pol = data["c_mmc_pol"]
	c_mmc_z = data["c_mmc_z"]
	c_mmc = data["c_mmc"]
	c_uter_pol = data["c_uter_pol"]
	c_uter_eq = data["c_uter_eq"]
	l_mass_com_topo = data["l_mass_com_topo"]
	l_p0_var = data["l_p0_var"]
	p0 = data["p0"]
	c_slp = data["c_slp"]
	l_aslp_topo = data["l_aslp_topo"]
	c_aslp_topo = data["c_aslp_topo"]
	zmax = data["zmax"]
	dpc = data["dpc"]
	pcmin = data["pcmin"]
	pcmax = data["pcmax"]
	ptopdyn = data["ptopdyn"]
	pblp = data["pblp"]
	pble = data["pble"]
	c_gam = data["c_gam"]
	gams_max_lnd = data["gams_max_lnd"]
	gams_max_ocn = data["gams_max_ocn"]
	gams_min_ocn = data["gams_min_ocn"]
	hgams = data["hgams"]
	hgamt = data["hgamt"]
	c_gam_rel = data["c_gam_rel"]
	nsmooth_gam = data["nsmooth_gam"]
	nsmooth_cld = data["nsmooth_cld"]
	i_tsl = data["i_tsl"]
	i_tslz = data["i_tslz"]
	c_tsl_gam = data["c_tsl_gam"]
	c_tsl_gam_ice = data["c_tsl_gam_ice"]
	tsl_gams_min_lnd = data["tsl_gams_min_lnd"]
	tsl_gams_min_ice = data["tsl_gams_min_ice"]
	c_wrt = data["c_wrt"]
	hcld_base = data["hcld_base"]
	i_lw_cld = data["i_lw_cld"]
	c_lw_clot = data["c_lw_clot"]
	ak_co2 = data["ak_co2"]
	beta_co2 = data["beta_co2"]
	ak_wv = data["ak_wv"]
	a_vap = data["a_vap"]
	beta_vap = data["beta_vap"]
	a2_vap = data["a2_vap"]
	beta2_vap = data["beta2_vap"]
	a3_vap = data["a3_vap"]
	l_o3 = data["l_o3"]
	ecs_scale = data["ecs_scale"]
	ecs_scale_dT = data["ecs_scale_dT"]
	c_hrs = data["c_hrs"]
	c_clot = data["c_clot"]
	c_syn = data["c_syn"]
	windmin = data["windmin"]
	synsurmin = data["synsurmin"]
	c_wind_ele = data["c_wind_ele"]
	c_diffx_energy = data["c_diffx_energy"]
	c_diffx_water = data["c_diffx_water"]
	c_diff_water = data["c_diff_water"]
	c_diff_energy = data["c_diff_energy"]
	i_diff_water = data["i_diff_water"]
	i_diff_dust = data["i_diff_dust"]
	i_kata_wind = data["i_kata_wind"]
	h_kata = data["h_kata"]
	cd0_ocn = data["cd0_ocn"]
	cd0_sic = data["cd0_sic"]
	i_zoro = data["i_zoro"]
	i_acbar = data["i_acbar"]
	acbar_max = data["acbar_max"]
	acbar_scale = data["acbar_scale"]
	c_cld = data["c_cld"]
	l_cld_low_ice = data["l_cld_low_ice"]
	c_hcld = data["c_hcld"]
	cld_max = data["cld_max"]
	c_woro = data["c_woro"]
	c_weff = data["c_weff"]
	i_rbstr = data["i_rbstr"]
	i_pbl = data["i_pbl"]
	hpbl = data["hpbl"]
	rh_max = data["rh_max"]
	rskin_ocn_min = data["rskin_ocn_min"]
	rh_strat = data["rh_strat"]
	c_trop = data["c_trop"]
	l_dust = data["l_dust"]
	l_dust_rad = data["l_dust_rad"]
	if (!Controller.flagDust):
		l_dust = false
		l_dust_rad = false
	l_co2d = data["l_co2d"]
	if (!Controller.flagCO2):
		l_co2d = false
	c_dhs_1 = data["c_dhs_1"]
	c_dhs_2 = data["c_dhs_2"]
	c_dust_dry = data["c_dust_dry"]
	c_dust_wet = data["c_dust_wet"]
	c_dust_mec = data["c_dust_mec"]
	l_so4_de = data["l_so4_de"]
	l_so4_ie = data["l_so4_ie"]
	beta_so4 = data["beta_so4"]
	sigma_so4 = data["sigma_so4"]
	r_so4 = data["r_so4"]
	N_so4_nat = data["N_so4_nat"]
	ars_ot = data["ars_ot"]
	ars_im = data["ars_im"]
	nsmooth_cda = data["nsmooth_cda"]
	nsmooth_weff = data["nsmooth_weff"]
	nsmooth_aslp = data["nsmooth_aslp"]
	nsmooth_aslp_eq = data["nsmooth_aslp_eq"]
	nj_eq = data["nj_eq"]
	nsmooth_aslp_topo = data["nsmooth_aslp_topo"]
	nsmooth_acbar = data["nsmooth_acbar"]
	l_write_timer = data["l_write_timer"]
	l_daily_output = data["l_daily_output"]
	l_output_flx3d = data["l_output_flx3d"]
	l_output_extended = data["l_output_extended"]
	tam_init = data["tam_init"]

func atm_param_save() -> Dictionary:
	var data = {}
	data["nstep_fast"] = nstep_fast
	data["fcormin"] = fcormin
	data["fcoramin"] = fcoramin
	data["fcorumin"] = fcorumin
	data["f_ice_pow"] = f_ice_pow
	data["r_scat"] = r_scat
	data["l_sct_0"] = l_sct_0
	data["l_alb_0"] = l_alb_0
	data["a1_w"] = a1_w
	data["b1_w"] = b1_w
	data["b2_w"] = b2_w
	data["c_itf_c"] = c_itf_c
	data["c_itf_cc"] = c_itf_cc
	data["i_mmc"] = i_mmc
	data["c_mmc_had"] = c_mmc_had
	data["c_mmc_fer"] = c_mmc_fer
	data["c_mmc_pol"] = c_mmc_pol
	data["c_mmc_z"] = c_mmc_z
	data["c_mmc"] = c_mmc
	data["c_uter_pol"] = c_uter_pol
	data["c_uter_eq"] = c_uter_eq
	data["l_mass_com_topo"] = l_mass_com_topo
	data["l_p0_var"] = l_p0_var
	data["p0"] = p0
	data["c_slp"] = c_slp
	data["l_aslp_topo"] = l_aslp_topo
	data["c_aslp_topo"] = c_aslp_topo
	data["zmax"] = zmax
	data["dpc"] = dpc
	data["pcmin"] = pcmin
	data["pcmax"] = pcmax
	data["ptopdyn"] = ptopdyn
	data["pblp"] = pblp
	data["pble"] = pble
	data["c_gam"] = c_gam
	data["gams_max_lnd"] = gams_max_lnd
	data["gams_max_ocn"] = gams_max_ocn
	data["gams_min_ocn"] = gams_min_ocn
	data["hgams"] = hgams
	data["hgamt"] = hgamt
	data["c_gam_rel"] = c_gam_rel
	data["nsmooth_gam"] = nsmooth_gam
	data["nsmooth_cld"] = nsmooth_cld
	data["i_tsl"] = i_tsl
	data["i_tslz"] = i_tslz
	data["c_tsl_gam"] = c_tsl_gam
	data["c_tsl_gam_ice"] = c_tsl_gam_ice
	data["tsl_gams_min_lnd"] = tsl_gams_min_lnd
	data["tsl_gams_min_ice"] = tsl_gams_min_ice
	data["c_wrt"] = c_wrt
	data["hcld_base"] = hcld_base
	data["i_lw_cld"] = i_lw_cld
	data["c_lw_clot"] = c_lw_clot
	data["ak_co2"] = ak_co2
	data["beta_co2"] = beta_co2
	data["ak_wv"] = ak_wv
	data["a_vap"] = a_vap
	data["beta_vap"] = beta_vap
	data["a2_vap"] = a2_vap
	data["beta2_vap"] = beta2_vap
	data["a3_vap"] = a3_vap
	data["l_o3"] = l_o3
	data["ecs_scale"] = ecs_scale
	data["ecs_scale_dT"] = ecs_scale_dT
	data["c_hrs"] = c_hrs
	data["c_clot"] = c_clot
	data["c_syn"] = c_syn
	data["windmin"] = windmin
	data["synsurmin"] = synsurmin
	data["c_wind_ele"] = c_wind_ele
	data["c_diffx_energy"] = c_diffx_energy
	data["c_diffx_water"] = c_diffx_water
	data["c_diff_water"] = c_diff_water
	data["c_diff_energy"] = c_diff_energy
	data["i_diff_water"] = i_diff_water
	data["i_diff_dust"] = i_diff_dust
	data["i_kata_wind"] = i_kata_wind
	data["h_kata"] = h_kata
	data["cd0_ocn"] = cd0_ocn
	data["cd0_sic"] = cd0_sic
	data["i_zoro"] = i_zoro
	data["i_acbar"] = i_acbar
	data["acbar_max"] = acbar_max
	data["acbar_scale"] = acbar_scale
	data["c_cld"] = c_cld
	data["l_cld_low_ice"] = l_cld_low_ice
	data["c_hcld"] = c_hcld
	data["cld_max"] = cld_max
	data["c_woro"] = c_woro
	data["c_weff"] = c_weff
	data["i_rbstr"] = i_rbstr
	data["i_pbl"] = i_pbl
	data["hpbl"] = hpbl
	data["rh_max"] = rh_max
	data["rskin_ocn_min"] = rskin_ocn_min
	data["rh_strat"] = rh_strat
	data["c_trop"] = c_trop
	data["l_dust"] = l_dust
	data["l_dust_rad"] = l_dust_rad
	data["l_co2d"] = l_co2d
	data["c_dhs_1"] = c_dhs_1
	data["c_dhs_2"] = c_dhs_2
	data["c_dust_dry"] = c_dust_dry
	data["c_dust_wet"] = c_dust_wet
	data["c_dust_mec"] = c_dust_mec
	data["l_so4_de"] = l_so4_de
	data["l_so4_ie"] = l_so4_ie
	data["beta_so4"] = beta_so4
	data["sigma_so4"] = sigma_so4
	data["r_so4"] = r_so4
	data["N_so4_nat"] = N_so4_nat
	data["ars_ot"] = ars_ot
	data["ars_im"] = ars_im
	data["nsmooth_cda"] = nsmooth_cda
	data["nsmooth_weff"] = nsmooth_weff
	data["nsmooth_aslp"] = nsmooth_aslp
	data["nsmooth_aslp_eq"] = nsmooth_aslp_eq
	data["nj_eq"] = nj_eq
	data["nsmooth_aslp_topo"] = nsmooth_aslp_topo
	data["nsmooth_acbar"] = nsmooth_acbar
	data["l_write_timer"] = l_write_timer
	data["l_daily_output"] = l_daily_output
	data["l_output_flx3d"] = l_output_flx3d
	data["l_output_extended"] = l_output_extended
	data["tam_init"] = tam_init
	return data
