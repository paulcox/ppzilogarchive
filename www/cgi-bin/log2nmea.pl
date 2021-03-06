#!/usr/bin/perl
#Author: Paul Cox
#This script reads a paparazzi log file and extracts the GPS messages
#It outputs Time/Lat/Long/Alt
#TODO: waypoints and interpolation when delta is > 2 sec
#Notes:
#mode 
#utm_east ALT_UNIT="m" UNIT="cm"
#utm_north ALT_UNIT="m" UNIT="cm"
#course ALT_UNIT="deg" UNIT="decideg"
#alt ALT_UNIT="m" UNIT="cm"
#speed ALT_UNIT="m/s" UNIT="cm/s"
#climb ALT_UNIT="m/s" UNIT="cm/s"
#week weeks
#itow ms
#utm_zone
#gps_nb_err
#0       1  2   3 4        5         6    7    8 9   10   11        12 13
#time    ID MSG M EAST     NORTH     C    ALT  S C   W    ITOW      ZO ERR
#144.225 20 GPS 3 19779772 497668512 1819 3625 9 -20 1601 303393500 31 0

#use strict; fast and loose is nice...  
use CGI;  
use CGI::Carp qw ( fatalsToBrowser );  
use Geo::Coordinates::UTM;
use USNaviguide_Google_Encode;
require "distance.pl";

use constant GOOGURL => "http://maps.google.com/maps/api/staticmap";

my $query = new CGI;  

my $utw=0;
my $cnt=0;
my $toffset=0;
my $solstart=0;
my $totime=0;
my $tdtime=0;
my $hialt=0;
my $maxdist=0;
my $latitude=0;
my $longitude=0;
my $gndalt=0;
my $delta=0;

sub getnmeatime {
    my $utw_h = 0;
    my $utw_d = 0;
    my $foo = $utw/60000/60;
    #calculate days and hours
    while ($foo > 1) {
      if ($utw_h == 23) {$utw_h = 0;$utw_d++;} else {$utw_h = $utw_h + 1;}
      $foo = $foo - 1;
    }
    #ensure proper leading zero for single digits
    $utw_h = sprintf("%02d",$utw_h);
    #foo+1 is the fractional hours
    my $utw_m = int($foo*60);
    #ensure proper leading zero for single digits
    $utw_m = sprintf("%02d",$utw_m);
    #calculate remaining seconds
    my $utw_s = sprintf("%06.3f",$utw/1000-$utw_m*60-$utw_h*60*60-$utw_d*60*60*24-$_[0]);
    my $time = $utw_h . $utw_m . $utw_s; #Time UTC HHMMSS.mmm  303318000/60000=5055.3/60=84.255/24=3.510625
    return $time;
} 

my $upload_dir = "/var/www/upload";
#my $filename = '10_09_15__14_13_55';
#my $username = 'paul@laas.fr';
my $filename = $query->param("logfile");
my $username = $query->param("user");


print $query->header();  

#print "Parsing log and creating summary...Please wait...\n";

open(SUMOUT,">$upload_dir/$username/$filename.sum");

my @filepts = split(/\_/,$filename);
my $date = $filepts[2] . $filepts[1] . $filepts[0];

printf SUMOUT "NMEA Date: $date\n";

#printf "$upload_dir/$username/$filename.data";
#my $foo = `ls -l $upload_dir/$username/$filename.data`;
#printf $foo;

printf "<$upload_dir/$username/$filename.data";
open DATAFILE, "<$upload_dir/$username/$filename.data" or die $!;
#TODO: open .log file and create nmea waypoints from flightplan waypoints
#open OUTFILE, ">GPS_data_$date.txt" or die $!;
open NMEAFILE, ">$upload_dir/$username/NMEA_$date.log" or die $!;

my $sacc = 0;
my $pacc = 0;
my $pdop = 0;
my $numSV = 0;
my $acid = 0;
my @Ipoints	= ( ) ;

while (my $line = <DATAFILE>) {
  chomp($line); 
  my @fields = split(/ /,$line);
  
  if ($acid == 0) {
		open LOGFILE, "<$upload_dir/$username/$filename.log" or die $!;
		$acid = $fields[1];
		printf SUMOUT "AC_ID: $acid\n";
		while (my $lin = <LOGFILE>) {
			if ($lin =~ m/ac_id="$acid"/)  {
			#radio="radios/T6EXAP.xml" telemetry="telemetry/default.xml" 
			#flight_plan="flight_plans/daurat2.xml" settings=" settings/tuning_basic_ins.xml"
				$lin =~ /aircraft\sname="(\S+)"/;
				if ($1) {
					my $acname = $1;
					printf SUMOUT "AC_NAME: $acname\n";
				}
				$lin =~ /radio="radios\/(\S+).xml".*telemetry="telemetry\/(\S+).xml".*flight_plan="flight_plans\/(\S+).xml"/;
				if ($1) {
					printf SUMOUT "radio: $1\n telemetry: $2\n flight plan: $3\n";
				}
				last;
			}
		}
		close LOGFILE;
  } 
  
  #Determine when GPS fix is acquired by looking for PDOP <1000 and numSV>3
  if ($fields[2] eq "GPS_SOL" and $fields[5] < 1000 and $fields[6] > 3) {
    if ($solstart == 0 ) {
      $solstart = $fields[0];
      printf SUMOUT "GPS SOL start time: $solstart\n";
    }
    $pacc = $fields[3];
    $sacc = $fields[4];
    $pdop = $fields[5];
    $numSV = $fields[6];
  }
  
  #We are going to look for GPS messages, in mode 3 (3D fix)
  # Skip messages that have the previous utw (duplicates)
  # Skip any messages with negative altitude (GPS not initialized yet)
  if ($fields[2] eq "GPS" and $fields[3] == "3" and $fields[11] != $utw and $fields[7] > 0 and $solstart != 0) {
        #store begin flight time
    if ($toffset == 0) { 
      $toffset = $fields[0];
      printf SUMOUT "GPS Start Time: $toffset\n";
    }
    #Calculate delta and store for averaging at the end
    if ($prevtime == 0) {
      $prevtime = $fields[0];
    } else {
      $delta= $fields[0]-$prevtime;
      if ($delta > 2) {printf SUMOUT "warning: delta %.1f at $fields[0] s.\n",$delta;}
      $prevtime = $fields[0];
      $sum += $delta;
      $cnt++;
    }
    #takeoff is considered to be > 4 m/s on hor and vert
    if ($fields[8] > 400 and $fields[9] > 400 and $totime == 0) {
      $totime = $fields[0];
      $gndalt = $fields[7];
      $olat=$latitude; $olon=$longitude;
      #create waypoint
      printf SUMOUT "Takeoff detected at time : $totime s\n";
	  printf SUMOUT "TO lat: $olat\n";
	  printf SUMOUT "TO lon: $olon\n";
    }
    
    if ($fields[7] > $hialt and $totime != 0 ) {
      $hialt = $fields[7];
      $hialtt = $fields[0];
      #store lat/lon for waypoint creation at end of program
    }
  
    #touchdown is considered when < 1 m/s on hor and vert
    if ($fields[8] < 100 and $fields[9] < 100 and $totime != 0 and $tdtime == 0) {
      $tdtime = $fields[0];
      printf SUMOUT "Max Altitude (above home): %.2f meters ($hialtt sec)\n",($hialt-$gndalt)/100;
      printf SUMOUT "Max Dist (from home): %.3f km ($maxdistt sec)\n",$maxdist;
      printf SUMOUT "Touchdown detected at: $tdtime s \n total flight time: %.2f min\n",($tdtime-$totime)/60;
    }
   
    $utw=$fields[11];
    #divide by 100 as gps provides utm in centimeters
    ($latitude,$longitude)=utm_to_latlon('wgs84',($fields[12] . "V"),$fields[4]/100,$fields[5]/100);
    push( @Ipoints, [$latitude,$longitude] );
    #printf SUMOUT OUTFILE "Time: %.2f Alt: %.2f Lat: %.6f Lon: %.6f\n",
    #                 $fields[0] - $toffset,($fields[7]/100),$latitude,$longitude;
    
    if ($totime == 0) { next;}
    if ($tdtime != 0) { last;}
    
    my $dist = distance($latitude, $longitude, $olat, $olon, "K");
    if ( $dist > $maxdist ) { 
      $maxdist = $dist; 
      $maxdistt = $fields[0];
      #create waypoint
      #$GPWPL,4917.16,N,12310.64,W,003*65
    }
    
    #Begin NMEA output
    #RMC,GGA/GSA/VTG/GSV

    $degrees = abs(int($latitude));
    $minutes = (abs($latitude) - $degrees) * 60;
    $nmealat = sprintf("%02d%.4f",$degrees,$minutes). "," ."N";                               

    $degrees = abs(int($longitude));
    $minutes = (abs($longitude) - $degrees) * 60;
    $nmealon = sprintf("%03d%.4f",$degrees,$minutes);  
    if ($longitude > 0) {
      $nmealon .= ",E" ; #LON
    } else {
      $nmealon .= ",W" ; #LON
    }

    $gprmc = sprintf '%.2f,',$fields[8]*.019438444; #gnd spd in knts from cm/s 
    $gprmc .= sprintf '%.2f,',$fields[6]/10; #trk angle in deg from decideg

    # ($year,$month,$day) = Monday_of_Week($week,"2010"); TODO:use week and day to calculate date?
    $gprmc .= sprintf "$date,,\n"; #date and mag var 

    #$GPRMC,121518.000,A,4452.767,N,00049.573,W,0.45,0.00,150910,,*1F
       #$GPGGA,121518.000,4452.767,N,00049.573,W,1,00,0.0,0.000,M,0.0,M,,*7D
    #$GPGGA,121828.500,4452.7696,N,00049.5712,W,1,8,184,52.65,M,52.65,M,,*55
    #$GPVTG,0.000,T,0,M,0.450,N,0.833,K*59
    for (my $i = int($delta-0.25); $i >= 0 ; $i-- ) {
      $time= getnmeatime($i);
      #if ($i>0) {printf NMEAFILE "-----\n";}
      printf NMEAFILE "\$GPRMC,$time,A,$nmealat,$nmealon,". $gprmc;
      printf NMEAFILE "\$GPGGA,$time,$nmealat,$nmealon,1,$numSV,$pdop,%.2f,M,%.2f,M,,\n",$fields[7]/100,$fields[7]/100;
      printf NMEAFILE "\$GPVTG,0.000,T,0,M,%.2f,N,%.2f,K\n",$fields[8]*.019438444,$fields[8]*.03598272;  
    } 
  }
  
}
if ($cnt == 0) {
printf "nothing counted";
die;
}

my $tolerance = 5;
my ($lstr,$pstr) = Google_Encode(\@Ipoints,$tolerance);
#hack because I'm finding double backslashes
$pstr =~ s/\\\\/\\/g;

printf SUMOUT "Number of GPS points: $cnt (Avg. delta ";
printf SUMOUT "%.2f)",$sum/$cnt;
printf SUMOUT "\nLog Length: ";
printf SUMOUT '%.2f',$cnt/4/60;
printf SUMOUT " minutes\n";
printf SUMOUT "pstr:%s\n",$pstr;

close DATAFILE;
#close OUTFILE;
close NMEAFILE;

open NMEAFILE, "<$upload_dir/$username/NMEA_$date.log" or die $!;
$time = substr($time,0,6);
#open OUTFILE, ">$upload_dir/$username/gps_$date\_$time.nmea" or die $!;
open OUTFILE, ">$upload_dir/$username/$filename.nmea" or die $!;

while (my $line = <NMEAFILE>) { 
  chomp($line);
  #hack off CR
  $len = length($line);
  $cksum = 0;
  printf OUTFILE $line . "*";
  #hack off $
  $line = substr($line,1,$len);  
  for ( split(//, $line) ) { $cksum ^= ord($_); };
  
  printf OUTFILE '%02x',$cksum ;
  printf OUTFILE "\n";
}

close NMEAFILE;
`rm $upload_dir/$username/NMEA_$date.log`;
close OUTFILE;

close SUMOUT;


$summary_contents = `cat $upload_dir/$username/$filename.sum`;

print <<END_HTML;   
<html>  
 <head>  
   <title>Log Files Uploaded</title>  
 </head>  
 <body>  
<img src="../archive_banner.png">  
   <br><br>
   Log File : <A href="$upload_dir/$username/$filename.log">$filename.log</A>
   <br>
   Data File : <A href="$upload_dir/$username/$filename.data">$filename.data</A>
   <br>
   NMEA Outpout : <A href="$upload_dir/$username/$filename.nmea">$filename.nmea</A>
   <br>
   <textarea name="comments" cols="50" rows="15">$summary_contents</textarea>
   <img src="http://maps.google.com/maps/api/staticmap?center=$lat,$lon&zoom=9&size=256x256&maptype=roadmap
&markers=color:blue|label:HOME|$olat,$olon&sensor=false">
   <br>
   <img src="http://maps.google.com/maps/api/staticmap?size=256x256&maptype=satellite&sensor=false&path=weight:3|color:orange|enc:$pstr">
   <br>
   Enter something into your log book regarding this flight :
   <form method="post" action="comments" name="update">
	<textarea name="comments" cols="70" rows="3">type something here</textarea>
	<br>
	<input type="submit" name="func" value="comment" />
   </form>
   <p><A href="ppzilogmenu.pl?username=$username&func=view">...Back to View Page</A></p>
 </body>  
</html>  
END_HTML
