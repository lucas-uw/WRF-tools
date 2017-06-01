#!/usr/bin/perl

$namelist = shift;

if($namelist eq "-h" || $namelist eq "") {
  print "analyze_namelist.pl:  Interprate your WRF namalist.input\n";
  print "Ver:     1.0.0\n";
  print "Author:  Xiaodong Chen<xiaodc.work\@gmail.com>\n";
  print "Use:  analyze_namelist.pl <path-to-namelist.input>\n";
  print "   This version works for WRFV3.6.x. Please check with the official user guide and modify the hash within the script for other versions.\n";
  exit;
}

print "Reminder: This script works on WRFV3.6.1 namelist.input. For other versions, please double check the bash within the script before using it.\n";

# Building reference data for WRFV3.6.1
%param_schemes = (
  "mp_physics" => {"name"=>"Microphysics",
                      "0"=>"(not used)",
                      "1"=>"Kessler",
                      "2"=>"Lin et al",
                      "3"=>"WSM-3",
                      "4"=>"WSM-5",
                      "5"=>"Ferrier (new Eta)-fine",
                      "6"=>"WSM-6",
                      "7"=>"Goddard GCE",
                      "8"=>"New Thompson",
                      "9"=>"Milbrandt-Yau Double-Moment",
                     "10"=>"Morrison double-moment",
                     "11"=>"CAM 5.1",
                     "13"=>"Stony Brook Univ.(Y. Lin)",
                     "14"=>"WRF double-moment-5",
                     "16"=>"WRF double-moment-6",
                     "17"=>"NNSL 2-moment",
                     "18"=>"NNSL 2-moment + CCN",
                     "19"=>"NNSL single-moment",
#                     "20"=>"NNSL Gilmore et al",
                     "21"=>"NSSL-LFO 1-moment, 6 class",
                     "28"=>"aerosol-aware Thompson",
                     "30"=>"HUJI fast",
                     "32"=>"HUJI full",
                     "95"=>"Ferrier (old Eta)-coarse"},
  "ra_lw_physics" => {"name"=>"Longwave Radiation",
                         "0"=>"(not used)",
                         "1"=>"RRTM",
                         "2"=>"GFDL",
                         "3"=>"CAM",
                         "4"=>"RRTMG",
                         "5"=>"New Goddard",
                         "7"=>"Fu-Liou-Gu",
                         "31"=>"Earch Held-Suarez",
                         "99"=>"GFDL (Eta)"},
  "ra_sw_physics" => {"name"=>"Shortwave Radiation",
                         "1"=>"Dudhia",
                         "2"=>"old Goddard",
                         "3"=>"CAM",
                         "4"=>"RRTMG",
                         "5"=>"New Goddard",
                         "7"=>"Fu-Liou-Gu",
#                        "31"=>"Held-Suarez relx",
                         "99"=>"GFDL"},
  "sf_sfclay_physics" => {"name"=>"Surface Layer",
                             "0"=>"(not used)",
                             "1"=>"Rev. MM5",
                             "2"=>"Monin-Obukhov (Janjic Eta)",
                             "4"=>"QNSE",
                             "5"=>"MYNN",
                             "7"=>"Pleim-Xu",
                             "10"=>"TEMF",
                             "91"=>"old MM5"},
  "sf_surface_physics" => {"name"=>"Land Surface",
                              "0"=>"(not used)",
                              "1"=>"5-layer thermal diffusion",
                              "2"=>"Noah",
                              "3"=>"RUC",
                              "4"=>"Noah-MP",
                              "5"=>"CLM4",
                              "7"=>"Pleim-Xu",
                              "8"=>"SSiB"},
  "sf_urban_physics" => {"name"=>"Urban Surface",
                            "0"=>"(not used)",
                            "1"=>"Single-layer, urban canopy model",
                            "2"=>"BEP",
                            "3"=>"BEM"},
  "sf_lake_physics" => {"name"=>"Lake",
                           "1"=>"CLM4.5"},
  "bl_pbl_physics" => {"name"=>"Planetary Boundary Layer",
                          "0"=>"(not used)",
                          "1"=>"Yonsei Univ.",
                          "2"=>"Mellor-Yamada-Janjic (Eta) TKE",
                          "4"=>"Quasi-Normal Scale Elimination",
                          "5"=>"Mellor-Yamada Nakanishi and Niino Level 2.5",
                          "6"=>"Mdllor-Yamada Nakanishi and Niino Level 3",
                          "7"=>"ACM2 (Pleim)",
                          "8"=>"BouLac",
                          "9"=>"Bretherton-Park (UW)",
                         "10"=>"Total Energy-Mass Flux (TEMF)",
                         "12"=>"GBM TKE-type",
                         "94"=>"Quasi-Normal Scale Elimination",
                         "99"=>"MRF"},
  "cu_physics" => {"name"=>"Cumulus",
                      "1"=>"Kain-Fritsch (new Eta)",
                      "2"=>"Betts-Miller-Janjic",
                      "3"=>"Grell-Freitas",
                      "4"=>"Simpf. Arakawa-Schubert",
                      "5"=>"Grell 3D",
                      "6"=>"Tiedtke",
                      "7"=>"Zhang-McFarlane",
                      "14"=>"New Simpf. Arakawa-Schubert (YSU)",
                      "84"=>"New Simpf. Arakawa-Schubert (HWRF)",
                      "93"=>"Grell-Devenyi",
                      "99"=>"Old Kain-Fritsch"},
  "shcu_physics" => {"name"=>"Shallow Convection",
                        "2"=>"UW"},
#  "" => {"name"=>""},
);
@schemes = ('mp_physics','ra_lw_physics','ra_sw_physics','sf_sfclay_physics','sf_surface_physics','sf_urban_physics','sf_lake_physics','bl_pbl_physics','cu_physics','shcu_physics');



# check the nesting info
open(INFO,"grep max_dom $namelist | ") or die "$0: ERROR: no domain nesting info found. This is not good :)\n";
foreach(<INFO>) {
  chomp;
  s/\s+//;
  s/\=//;
  s/,/\ /;
  @fields = split/\s+/;
  $nest_layers = $fields[1];
}
close(INFO);

#open(IN,"grep mp_physics $namelist |") or die "$0: ERROR: cannot open namelist $namelist for reading\n";
open(IN,$namelist) or die "$0: ERROR: cannot open namelist $namelist for reading\n";
foreach(<IN>) {
  chomp;
  s/\s+//;
  s/\=//;
  @fields = split/\s+|,/;
  $ncols = @fields;
#  print "0=|$fields[0]|  1=|$fields[1]|    2=|$fields[2]|    3=|$fields[3]|  4=|$fields[4]|\n";
#  print "@fields\n";
  if($ncols>1) {
    for($i=0; $i<$nest_layers; $i++) {
      $info{$fields[0]}{$i} = $fields[2*$i+1];
    }
  }
#  print "$ncols\n";
#  print "$fields[0]  $fields[1] $fields[2]\n";
}
close(IN);

print "\n===========================Time information===========================\n";
for($nest=0; $nest<$nest_layers; $nest++) {
  print "Nest $nest:\n";
  $start_string = sprintf "%d-%02d-%02d  %02d:%02d:%02d UTC",$info{'start_year'}{$nest},$info{'start_month'}{$nest},$info{'start_day'}{$nest},$info{'start_hour'}{$nest},$info{'start_minute'}{$nest},$info{'start_second'}{$nest};
  printf "     start from :  %s\n",$start_string;
  $end_string = sprintf "%d-%02d-%02d  %02d:%02d:%02d UTC",$info{'end_year'}{$nest},$info{'end_month'}{$nest},$info{'end_day'}{$nest},$info{'end_hour'}{$nest},$info{'end_minute'}{$nest},$info{'end_second'}{$nest};
  printf "       run till :  %s\n",$end_string;
  $tmp = $info{'time_step'}{0};
  for($i=1; $i<=$nest; $i++) {
    $tmp /= $info{'parent_time_step_ratio'}{$i};
  }
  print  "      time step :  $tmp  s\n";
#  print  "      time step :  ",$info{'time_step'}{0}/$info{'parent_time_step_ratio'}{$nest},"  s\n";
}
print "Output time step:  $info{'history_interval'}{'0'}  minute(s)\n";
print "\n";


print "===========================Space information==========================\n";
print "Horizontal Resolution:\n";
for($nest=0; $nest<$nest_layers; $nest++) {
  print "  Nest $nest:\n";
  printf "        Grid size :  %7s m x %7s m\n",$info{'dx'}{$nest},$info{'dy'}{$nest};
  printf "   Grid dimension :     %4s   x  %4s\n",$info{'e_we'}{$nest},$info{'e_sn'}{$nest};
}
print "\nVertical Resolution:  $info{'e_vert'}{0} layers (same for all domains.)\n\n";

print "=======================Parameterication Schemes=======================\n";
foreach $var(@schemes) {
  printf "%30s", "$param_schemes{$var}{'name'} :";
#  print "test:   $info{$var}{'0'}\n";
  if($info{$var}{'0'} ne "") {
    for($nest=0; $nest<$nest_layers; $nest++) {
      printf "%-30s", "    $param_schemes{$var}{$info{$var}{$nest}}";
    }
  }
  else {
    printf "%-30s", "    (Not turned on)";
  }
  print "\n";
}

print "\n";
