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

var I_Fake_Geo :int = 0
