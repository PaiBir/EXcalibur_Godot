class_name ATM_PARAM
extends Node

var Planet : PlanetManager
var Output : OUTPUTTER
var ModelTimer : MODELTIMER

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

var c_slip : Array[float] = [0,0,0,0,0]
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
var nnsmooth_gam : int
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
var c_diffx_water : float
var i_diff_energy : float
var c_diff_energy : float
var i_diff_water : int
var c_diff_water : float

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
var nsmooth_ld : int

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

func atm_params_init():
	gad =  Planet.Gravity/ cp
	atmosphere_scale = (Constants.specificGasConstant_dryair * (Planet.Boss.starLuminosity/pow(2.52,Planet.Boss.BolometricCorrectionStrength)))/Planet.Gravity
	var AtmParams = FileAccess.open(Output.OutputDirectory + "atm_param.json",FileAccess.READ)
	var JSONlines = AtmParams.get_line()
	AtmParams.close()
	var JSONER = JSON.new()
	JSONER.parse(JSONlines)
	atm_param_load(JSONER.data)
	
	timeStep = ModelTimer.dt_atm/nstep_fast

func atm_param_load(data):
	nstep_fast = data["nstep_fast"]
