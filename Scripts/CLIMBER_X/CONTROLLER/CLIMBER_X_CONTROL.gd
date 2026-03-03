class_name CLIMBER_X_CONTROL
extends Node

#Restarts
var RESTART_ATMOSPHERE : bool = false
var RESTART_CO2 : bool = false
var RESTART_CH4 : bool = false
var RESTART_N2O : bool = false
var RESTART_LAND : bool = false
var RESTART_OCEAN : bool = false
var RESTART_SEA_ICE : bool = false
var RESTART_BGC : bool = false
var RESTART_GEO : bool = false
var RESTART_ICE_SHEET : bool = false
var RESTART_SMB : bool = false
var RESTART_BMB : bool = false
#Don't know what to do with "Restart in dir"
#So, as far as I can tell, this stuff is for either saving in case of failure, or it is basic data saving? Unsure
var i_write_restart : int = 0
var n_year_write_restart : int = 0
var years_write_restart : Array[int] = []

#Partial Model Flags
var flagDust : bool = false
var flagCO2 : bool = false
var flagCH4 : bool = false
#Full model Flags
var FLAG_ATMOSPHERE : bool = false
var FLAG_OCEAN : bool = false
var FLAG_LAND : bool = false
var FLAG_SEAICE : bool = false
var FLAG_ICESHEET : bool = false
var FLAG_SMB : bool = false
var FLAG_BMB : bool = false
var FLAG_BGC : bool = false
var FLAG_GEO : bool = false

var RESTORE_SALINITY : bool = false
var RESTORE_TEMP : bool = false
var ATMOSPHERE_FIX_TAU : bool = false

var ice_model_name : String = "" #This likely isn't needed
var ice_domain_name : Array[String] = [] #I don't know if this is needed
var ice_domain_max : int = 10 #maximum number of ice sheets that can exist
var number_ice_domains : int = 0

var aquaplanet : bool = false
var aqua_slab : bool = false
var Spinup_CC : bool = false
var Daily_Input_Save_OCEAN : bool = false
var Daily_Input_Save_BGC : bool = false
var Number_Years_Spinup_BGC : int = 0
var Year_Start_Offline : int = 0
var Year_Average_Offline : int = 0

var FEEDBACKS : bool = false

#Orbit and Star details to be handled by non-climber elements

var ivolc : int = 0
var volc_const : float = 0
var volc_file : String = ""
var volc_scale : float = 0

var isea_level : int = 0
var sea_level_const : float = 0
var sea_level_init : float = 0
var sea_level_file : String = ""

var ico2 : int = 0
var id13c : int = 0
var id14c : int = 0
var co2_const : float = 0
var d13c_atm_const : float = 0
var d14c_atm_const : float = 0
var co2_file : String = ""
var d13c_file : String = ""
var d14c_file : String = ""

var dco2_dt : float = 0
var co2_max : float = 0

var ico2_rad : int = 0
var co2_ref : float = 0
var co2_rad_const : float = 0
var co2_rad_file : String = ""

var iC14_production : int = 0
var C14_production_const : float = 0
var C14_production_file : String = ""

var ico2_degas : int = 0
var co2_degas_const : float = 0
var d13c_degas : float = 0
var co2_degas_file : String = ""

var FLAG_WEATHERING : bool = false

var d13c_weath : float = 0

var ico2_emis : int = 0
var co2_emis_const : float = 0
var co2_emis_file : String = ""
var co2_pulse : float = 0
var k_emis_fb : float = 0
var C_emis_gb : float = 0
var co2_emis_min : float = 0

var id13C_emis : int = 0
var d13C_emis_const : float = 0
var d13C_emis_file : String = ""

var FLAG_C13 : bool = false
var FLAG_C14 : bool = false
var FLAG_OCEAN_CO2 : bool = false
var FLAG_LAND_CO2 : bool = false

var ich4 : int = 0
var ch4_ref : float = 0
var ch4_const : float = 0
var i_ch4_tau : float = 0
var ch4_tau_const : float = 0
var ch4_file : String = ""
var ch4_tau_file : String = ""
var ch4_NOx_VOC_file : String = ""

var ich4_rad : int = 0
var ch4_rad_const : float = 0
var ch4_rad_file : String = ""

var in2o : int = 0
var n2o_ref : float = 0
var n2o_const : float = 0
var i_n2o_tau : int = 0
var n2o_tau_const : float = 0
var n2o_file : String = ""

var in2o_rad : int = 0
var n2o_rad_const : float = 0
var n2o_rad_file : String = ""

var in2o_emis : int = 0
var n2o_emis_const : float = 0
var n2o_emis_file : String = ""

var iso4 : int = 0
var so4_const : float = 0
var so4_file : String = ""

var io3 : int = 0
var o3_const : float = 0
var o3_file_const : String = ""
var o3_file_var : String = ""

var icfc : int = 0
var cfc11_const : float = 0
var cfc_12_const : float = 0
var cfc_file : String = ""

var iluc : int = 0
var luc_file : String = ""

var idist : int = 0
var dist_file : String = ""

var in_dir : String = ""
var out_dir : String = ""

var I_Fake_ATM : int = 0
var PRC_forcing : int = 0
var I_Fake_Dust : int = 0
var I_Fake_OCEAN : int = 0
var I_Fake_SEA_ICE : int = 0
var I_Fake_Ice : int = 0
var I_Fake_GEO : int = 0

var Fake_ATM_CONST_FILE : String = ""
var Fake_ATM_VAR_FILE : String = ""
var Fake_DUST_CONST_FILE : String = ""
var Fake_DUST_VAR_FILE : String = ""
var Fake_OCEAN_CONST_FILE : String = ""
var Fake_OCEAN_VAR_FILE : String = ""
var Fake_SEA_ICE_CONST_FILE : String = ""
var Fake_SEA_ICE_VAR_FILE : String = ""
var Fake_LAND_CONST_FILE : String = ""
var Fake_ICE_VAR_FILE : String = ""
var Fake_ICE_CONST_FILE : String = ""
var Fake_GEO_VAR_FILE : String = ""
var Fake_GEO_CONST_FILE : String = ""
var Fake_GEO_REF_FILE : String = ""
