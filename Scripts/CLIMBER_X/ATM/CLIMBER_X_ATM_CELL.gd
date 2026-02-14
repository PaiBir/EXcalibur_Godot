class_name ATM_CELL
extends CELL

var Solar : Array[float] = []
var SolarM : float = 0
var CosZ : Array[float] = []
var CosZM : float = 0

var Cam : float = 0
var CO2_Flux : float = 0
var C13_Flux : float = 0
var C14_Flux : float = 0
var Idivide_Pac_Atl : float = 0
var Idivide_Atl_Indpac : float = 0

#Something with the surface?
var ZS : Array[float] = []
#Height of the surface of the planet
var Surface : float = 0
#Smoothed height of the surface of the planet
var Surface_Smooth : float = 0
#The elevation change around the point
var Slope : float = 0
#Atmospheric Pressure at the surface
var Pressure_At_Surface : float = 0
#Atmospheric Pressure at the smoothed surface
var Pressure_At_Surface_Smooth : float = 0
#Surface Air Density
var Surface_Air_Density : float = 0

var FrLand : float = 0
var FrOcean : float = 0
var f_ice_lake : float = 0
var sigoro : float = 0

var sqr : float = 0

var Extrapolated_Surface_Temp : float = 0 #K
var Extrapolated_Surface_Specific_Humidity : float = 0 #kg/kg
var Extrapolated_Surface_Relative_Humidity : float = 0 #/, whatever that means
var LapseRate_BoundaryLayer : float = 0 #K/m
var LapseRate_Lower_Tropo : float = 0 #K/m
var LapseRate_Upper_Tropo : float = 0 #K/m
var Surface_Dust_Ratio : float = 0 #kg/kg
var Vertical_Humidity_Scale : float = 0 #m
var AtmosphericWaterContent : float = 0 #kg/m^2
var Cloud_Fraction_RH : float = 0
var Cloud_Fraction_Low : float = 0
var Cloud_Fraction : float = 0
var Cloud_Fraction_Dat : float = 0
var Cloud_Fraction_Day_Dat : float = 0
var Precipitation_Total : float = 0 #kg/m^2s
var Precipitation_Rain : Array[float] = [] #kg/m^2s
var Precipiation_Snow : Array[float] = [] #kg/m^2s
var Precipitation_Supersaturation : float = 0 #kg/m^-2s
var Precipitation_wcon : float = 0
var Precipitation_over : float = 0
var Cloud_Height : float = 0 #m
var Cloud_Optical_Thickness : float = 0
var Cloude_Albedo : float = 0
var Tropopause_Height : float = 0 #m
var Tropopause_Pressure : float = 0
var Tropopause_Temperature : float = 0 #K
var Wind_Magnitude_Average : float = 0 #m/s
var Wind_Magnitude : Array[float] = [] #m/s
var Aerosol_Optical_Thickness : float = 0
var Aersol_Imaginary_Refractive_Index : float = 0
var SO4_Load : float = 0 #kg/m^2
var Ozone_Concentration : Array[float] = [] #mol/mol

var Dust_Height_scale : float = 0 #m
var Dust_Load : float = 0 #kg/m^2
var Dust_Emission : float = 0 #kg/m^2/s
var Dust_Deposition : float = 0 #kg/m^2/s
var Dust_Dry_Deposition : float = 0 #kg/m^2/s
var Dust_Wet_Deposition : float = 0 #kg/m^2/s
var Dust_Optical_Thickness : float = 0

var frst : Array[float] = [] #I don't know if this is "first", "frost", "Free Roasted Sewer Talapia", or "French Roundrels Seeking Targets:
var Skin_Temp : Array[float] = [] #K
var Air_Temp_2m : Array[float] = [] #K
var ra_2 : Array[float] = []
var Specific_Humidity_2m : Array[float] = [] #kg/kg
var Relative_Humidity_2m : Array[float] = []
var Albedo_Clear_VisUV : Array[float] = []
var Albedo_Cloudy_VisUV : Array[float] = []
var Albedo_Clear_IR : Array[float] = []
var Albedo_Cloudy_IR : Array[float] = []
var Drag_Coefficient : Array[float] = []
var Drag_Coefficient_NoMountains : Array[float] = []
var Surface_Roughness : Array[float] = []
var Mountain_Roughness : float = 0

var ra_2_Average : float = 0
var Drag_Coefficient_Average : float = 0
var Drag_Coefficient_NoMountains_Average : float = 0
var Sha : float = 0
var Lha : float = 0
var Evpa : float = 0
var Tskina : float = 0
var T2a : float = 0
var Q2a : float = 0
var R2a : float = 0
var Rskina : float = 0

var Temperature : Array[float] = [] #K
var Specific_Humidity : Array[float] = [] #kg/kg
var Temperature_Potential : Array[float] = []
var Dust_Mass_Mixing : Array[float] = []

var Acbar : float = 0
var sin_cos_Acbar : float = 0
var cos_Acbar : Array[float] = []
var sin_Acbar : Array[float] = []
var epsa : Array[float] = []
var Atsl : float = 0
var aslp : float = 0
var aslp_Temperature : float = 0
var aslp_Topo : float = 0
var dz500 : float = 0
var slp : float = 0
var slp_dat : float = 0
var tsl_dat : float = 0
var ps : Array[float] = []
var psa : float = 0
var us : Array[float] = []
var vs : Array[float] = []
var usk : float = 0
var vsk : float = 0
var ugb : float = 0
var vgb : float = 0
var ugbf : float = 0
var vgbf : float = 0
var uab : float = 0
var vab : float = 0
var taux : Array[float] = []
var tauy : Array[float] = []
var uz500 : float = 0
var wCloud : float = 0
var woro : float = 0
var Synoptic_Wind : float = 0 #Vertical at 700 hPa (m/s)
var weff : float = 0
var fweff : float = 0

var ua : Array[float] = []
var va : Array[float] = []
var u3 : Array[float] = []
var v3 : Array[float] = []
var uter : Array[float] = []
var vter : Array[float] = []
var uterf : Array[float] = []
var vterf : Array[float] = []
var fa : Array[float] = []
var fao : Array[float] = []
var fac : float = 0
var w3 : Array[float] = []

var conv_energy : Array[float] = [] 
var conv_water : Array[float] = [] 
var conv_dust : Array[float] = [] 
var conv_co2 : Array[float] = [] 
var fa_energy : Array[float] = [] 
var fa_water : Array[float] = [] 
var fa_dust : Array[float] = [] 
var fa_co2 : Array[float] = [] 
var fd_energy : Array[float] = [] 
var fd_water : Array[float] = [] 
var fd_dust : Array[float] = [] 
var fd_co2 : Array[float] = [] 

var fswr_sur : Array[float] = []
var fswr_sur_cs : Array[float] = []
var fswr_sur_Cloud : Array[float] = []
var flwr_dw_sur : Array[float] = []
var flwr_dw_sur_cs : Array[float] = []
var flwr_dw_sur_Cloud : Array[float] = []
var flwr_up_sur : Array[float] = []

var dswd_dalb_Clear_VisUV : float = 0
var dswd_dalb_Clear_IR : float = 0
var dswd_dalb_Cloudy_VisUV : float = 0
var dswd_dalb_Cloudy_IR : float = 0
var dswd_dz_Clear_IR : float = 0
var dswd_dz_Cloudy_IR : float = 0
var swr_dw_sur_Clear_Visible : float = 0
var swr_dw_sur_Clear_NearIR : float = 0
var swr_dw_sur_Cloudy_Visible : float = 0
var swr_dw_sur_Cloudy_NearIR : float = 0

var rb_top : float = 0
var rb_sur : float = 0
var rb_atm : float = 0
var rb_str : float = 0
var swr_dw_top : float = 0
var swr_top : float = 0
var swr_top_Clear : float = 0
var swr_top_Cloudy : float = 0
var swr_sur : float = 0
var lwr_top : float = 0
var lwr_top_Clear : float = 0
var lwr_top_Cloudy : float = 0
var lwr_sur : float = 0
var lwr_tro : float = 0
var lwr_Cloudy : float = 0

var tsl : float = 0
var tsksl : float = 0

var eke : float = 0
var sam : float = 0
var sam2 : float = 0
var synprod : float = 0
var syndiss : float = 0
var synadv : float = 0
var syndif : float = 0
var synsur : float = 0
var cdif : float = 0
var diff_Energy : float = 0
var diff_Water : float = 0
var diff_Dust : float = 0
