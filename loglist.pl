#!/usr/bin/perl
#Author: Paul Cox

use strict;
use CGI;  
use CGI::Carp qw ( fatalsToBrowser );  
use Geo::Coordinates::UTM;
use XML::Twig;

require "distance.pl";

my $query = new CGI;  

my $upload_dir = "/var/www/upload";
my $filename = '10_09_15__14_13_55';
my $username = 'paul@laas.fr';
#my $filename = $query->param("logfile");
#my $username = $query->param("user");

#open(SUMOUT,">$upload_dir/$username/$filename.sum");

my @filepts = split(/\_/,$filename);
my $date = $filepts[2] . $filepts[1] . $filepts[0];

printf "NMEA Date: $date\n";

#printf "$upload_dir/$username/$filename.data";
#my $foo = `ls -l $upload_dir/$username/$filename.data`;
#printf $foo;

printf "$upload_dir/$username/$filename.data\n";
open DATAFILE, "<$upload_dir/$username/$filename.data" or die $!;

my $xmlfile = "$upload_dir/$username/$filename.log";
#my $xmlfile = '/home/paul/paparazzi/conf/airframes/Paul/minimag2.xml';
printf "xml file: $xmlfile\n";
#my $twig = XML::Twig->new();
my $twig = new XML::Twig(TwigRoots => {class => 1, message=>1, field=>1});

$twig->parsefile($xmlfile);

my $root = $twig->root;
#$twig->print;

foreach my $class ($root->children('class')){

    print ' (' . $class->att('NAME') . ') '."\n";
	if ($class->att('NAME') eq 'telemetry') {
#		print "paul is cool\n";
#		print $class->children('message')->att('NAME');
        foreach my $message ($class->children('message')){
#			print $message->att('NAME')."\n";
			if ($message->att('NAME') eq 'BAT') {
#						print "paul is rad\n";
				foreach my $field ($message->children('field')){
					print "  ".$field->att('NAME')." ";
					print "  ".$field->att('TYPE')."\n";
				}
			}
		}
	}
#print "$class\n";
}
    print "\n";

#TODO: open .log file and create nmea waypoints from flightplan waypoints
#open OUTFILE, ">GPS_data_$date.txt" or die $!;
#open NMEAFILE, ">$upload_dir/$username/NMEA_$date.log" or die $!;

my %knownmsgs = ();
my %HoA = ();

while (my $line = <DATAFILE>) {
  chomp($line); 
  my @fields = split(/ /,$line);
  my $known = 0;
  
  while (my ($key,$value) = each(%knownmsgs)) {
	if ($fields[2] eq $key) {
		$known = 1;
		$knownmsgs{$fields[2]} += 1;
	}
  }
  
  if (!$known) {
	$knownmsgs{$fields[2]} = 1;
  }
  push @{ $HoA{$fields[2]}} , $line;   
}

#foreach my $value (sort keys %knownmsgs) {
#   print "$value $knownmsgs{$value}\n";
#}

for my $msg ( sort keys %HoA ) {
  print "$msg : ",$#{$HoA{$msg}}+1,"\n";
  if ( $msg eq 'BLOCK' ) {
    for my $i ( 0 .. $#{ $HoA{$msg} } ) {
        print " ",($i+1)," = $HoA{$msg}[$i]\n";
	}
  }
}