class_name ATM_PARAM
extends Node

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



func atm_params_init():
	var AtmParams = FileAccess.open(Output.OutputDirectory + "atm_param.json",FileAccess.READ)
	var JSONlines = AtmParams.get_line()
	AtmParams.close()
	var JSONER = JSON.new()
	JSONER.parse(JSONlines)
	atm_param_load(JSONER.data)
	
	timeStep = ModelTimer.dt_atm/nstep_fast

func atm_param_load(data):
	nstep_fast = data["nstep_fast"]
