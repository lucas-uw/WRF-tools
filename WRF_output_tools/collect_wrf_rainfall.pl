#!/usr/bin/env perl

$start_time = shift; # e.g.  1970-2-16-0
$end_time = shift; # e.g. 1970-2-18-0
$wrfoutdir = shift;
$wrfoutinterval = shift;
$outfile = shift;

if($start_time eq "") {
  print "  collect_wrf_rainfall.pl   Collect total precipitation from WRF output\n";
  print "  Ver:     1.0.0\n";
  print "  Author:  Xiaodong Chen  <xiaodc.work\@gmail.com>\n";
  print "  Use:  collect_rainfall_adv.pl <start_time> <end_time> <wrfoutdir> <wrfoutinterval> <outfile>\n";
  print "                <start_time>      First timestamp in wrfout. e.g.  1970-2-16-0\n";
  print "                <end_time>        Last timestamp in wrfout. e.g.  1970-2-16-0\n";
  print "                <wrfoutdir>       Directory containing the wrfout_d* files\n";
  print "                <wrfoutinterval>  Time interval in WRF output. Unit is in hour\n";
  print "                <outfile>         Output file name\n";

  exit;
}

($year, $month, $day, $hour) = split/-/, $start_time;
($syear, $smonth, $sday, $shour) = split/-/, $start_time;
($eyear, $emonth, $eday, $ehour) = split/-/, $end_time;

@days = (31,28,31,30,31,30,31,31,30,31,30,31);

`mkdir -p tmp`;
`rm tmp/*`;

# 1.  collect necessary data
@files = ();
$count = 1;
while ($year<$eyear || ($year==$eyear && $month<$emonth) || ($year==$eyear && $month==$emonth && $day<$eday) || ($year==$eyear && $month==$emonth && $day==$eday && $hour<=$ehour)) {
    $timestamp = sprintf "%04d-%02d-%02d_%02d",$year,$month,$day,$hour;
    $cmd = sprintf "ncks -v XLAT,XLONG,RAINC,RAINNC $wrfoutdir/wrfout_d01\_$timestamp:00:00 tmp/int.%03d.nc", $count;
    (system($cmd)==0) or die "$0: ERROR: $cmd failed\n";
    $files[$count-1] = sprintf "tmp/int.%03d.nc", $count;
    $count++;
    $hour+=$wrfoutinterval;
    if($hour==24) {
        $hour=0;
        $day++;
        $days_in_month = $days[$month-1];
        if (($year % 400 == 0 || ($year%4==0 && $year%100!=0)) && $month == 2) {
            $days_in_month++;
        }
        if($day==$days_in_month+1) {
            $day=1;
            $month++;
            if($month==13) {
                $month=1;
                $year++;
            }
        }
    }
}
$count = $count-1;

# 2. concatenate files
$cmd = "ncrcat @files tmp/wrfout.tmp1.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "rm tmp/int.*.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

# 3. clean file, set the calendar
$cmd = "ncap -O -s RAIN=RAINC+RAINNC tmp/wrfout.tmp1.nc tmp/wrfout.tmp2.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "ncks -v RAIN,XLAT,XLONG tmp/wrfout.tmp2.nc tmp/wrfout.tmp3.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = sprintf "cdo setreftime,1900-01-01,0,1s -settaxis,%04d-%02d-%02d,%02d:00:00,${wrfoutinterval}hour -setcalendar,standard tmp/wrfout.tmp3.nc tmp/wrfout.tmp4.nc", $syear, $smonth, $sday, $shour;
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "rm tmp/wrfout.tmp1.nc tmp/wrfout.tmp2.nc tmp/wrfout.tmp3.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

# 4. calcuate the interval precipitation
$tmpvar1 = $count-2;
$tmpvar2 = $count-1;
$cmd = "ncks -d time,0,$tmpvar1 tmp/wrfout.tmp4.nc tmp/data1.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "ncks -d time,1,$tmpvar2 tmp/wrfout.tmp4.nc tmp/data2.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "rm tmp/wrfout.tmp4.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = sprintf "cdo  setreftime,1900-01-01,0,1s  -settaxis,%04d-%02d-%02d,%02d:00:00,${wrfoutinterval}hour  -setcalendar,standard  tmp/data2.nc tmp/data2.set_calendar.nc",$syear, $smonth, $sday, $shour;
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "ncdiff tmp/data2.set_calendar.nc tmp/data1.nc tmp/tmp1.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

# 5. adjust lat/lon info, making it to work with ncview

$cmd = "ncks -v RAIN tmp/tmp1.nc $outfile";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "ncks -v XLAT,XLONG tmp/data1.nc tmp/tmp3.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "ncwa -a time tmp/tmp3.nc tmp/tmp4.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "ncks -v XLAT,XLONG tmp/tmp4.nc tmp/tmp5.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "ncks -A tmp/tmp5.nc $outfile";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";


$cmd = "ncrename -v XLAT,lat -v XLONG,lon $outfile";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "ncatted -O -a stand_name,lat,a,c,'latitude' -a stand_name,lon,a,c,'longitude' -a long_name,lat,a,c,'latitude' -a long_name,lon,a,c,'longitude' $outfile";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "ncatted -O -a long_name,RAIN,a,c,'Total precipitation for the next $wrfoutinterval hour(s)' -a units,RAIN,a,c,'mm/${wrfoutinterval}hr' -a coordinates,RAIN,a,c,'lat lon' $outfile";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";

$cmd = "rm tmp/tmp1.nc tmp/tmp3.nc tmp/tmp4.nc tmp/tmp5.nc tmp/data1.nc tmp/data2.nc tmp/data2.set_calendar.nc";
(system($cmd)==0) or die "$0: ERROR: $cmd failed\n";
