#!/usr/bin/perl
#Author: Paul Cox

use strict;
use CGI;  
use CGI::Carp qw ( fatalsToBrowser );  
use Geo::Coordinates::UTM;
use XML::Twig;
use HTML::Template;

require "distance.pl";

my $query = new CGI;  

my $template = HTML::Template->new(filename => 'loglist.tmpl');

my $upload_dir = "/var/www/upload";
#my $filename = $query->param("logfile");

my $filename = '10_09_15__14_13_55';
my $username = $query->param("username");   
if (!$username ) {
 $username = 'paul@laas.fr';
}

my @filepts = split(/\_/,$filename);
my $date = $filepts[2] . $filepts[1] . $filepts[0];

#printf "NMEA Date: $date\n";

#printf "$upload_dir/$username/$filename.data";
#my $foo = `ls -l $upload_dir/$username/$filename.data`;
#printf $foo;

#printf "$upload_dir/$username/$filename.data\n";
open DATAFILE, "<$upload_dir/$username/$filename.data" or die $!;

my @expand = $query->param("expand");


my $xmlfile = "$upload_dir/$username/$filename.protocol";
#my $xmlfile = '/home/paul/paparazzi/conf/airframes/Paul/minimag2.xml';
#printf "xml file: $xmlfile\n";
#my $twig = XML::Twig->new();
my $twig = new XML::Twig(TwigRoots => {message=>1, field=>1});

$twig->parsefile($xmlfile);

my $root = $twig->root;
#$twig->print;


if (0){
my @loopdata = ();
foreach my $term (@expand){
	my %rowdata;
	
	$rowdata{EXPAND} = $term;
	#print $term."\n";
	foreach my $message ($root->children('message')){
		if ($message->att('NAME') eq $term) {
			my @inloopdata = ();	
			foreach my $field ($message->children('field')){
				my %fielddata;
				
#					print "  ".$field->att('NAME')."\t";
#					print "  ".$field->att('TYPE')."\t";
#					print "  ".$field->att('UNIT')."\n";
				$fielddata{NAME}=$field->att('NAME');
				$fielddata{TYPE}=$field->att('TYPE');
				$fielddata{UNIT}=$field->att('UNIT');
				push(@inloopdata, \%fielddata);
			}
			$rowdata{FIELDDATA} = \@inloopdata;
		}
	}
	
	push(@loopdata, \%rowdata);
}



foreach my $class ($root->children('class')){

    print ' (' . $class->att('NAME') . ') '."\n";
	if ($class->att('NAME') eq 'telemetry') {
#		print "paul is cool\n";
#		print $class->children('message')->att('NAME');
        foreach my $message ($class->children('message')){
#			print $message->att('NAME')."\n";
			if ($message->att('NAME') eq 'BAT') {
				print "  Battery fields: \n";
				print "  Name\tType\tUnit\n";
				foreach my $field ($message->children('field')){
					print "  ".$field->att('NAME')."\t";
					print "  ".$field->att('TYPE')."\t";
					print "  ".$field->att('UNIT')."\n";
				}
			}
		}
	}
#print "$class\n";
}
    print "\n";
#if0
}

#TODO: open .log file and create nmea waypoints from flightplan waypoints
#open OUTFILE, ">GPS_data_$date.txt" or die $!;
#open NMEAFILE, ">$upload_dir/$username/NMEA_$date.log" or die $!;

#array for populating template variables
my @loopdata = ();

#hashes for extracting data from file
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
  #we don't know this message so we add it to %knownmsgs(holds count) and %HoA(holds line contents)
  if (!$known) {
	$knownmsgs{$fields[2]} = 1;
  }
  push @{ $HoA{$fields[2]}} , $line;   
}

#while (my ($key,$value) = each(%knownmsgs)) {
for my $msg (sort keys %knownmsgs){
	my %msglist;

	$msglist{MSGNAME} = $msg;
	#$msglist{MSGCNT} = $value;
	$msglist{MSGCNT} = $knownmsgs{$msg};

	foreach my $term (@expand){
		if ($term eq $msg ){
			#print $term."\n";
			foreach my $message ($root->children('message')){
				if ($message->att('NAME') eq $term) {
					my @inloopdata = ();	
					foreach my $field ($message->children('field')){
						my %fielddata;
				
		#					print "  ".$field->att('NAME')."\t";
		#					print "  ".$field->att('TYPE')."\t";
		#					print "  ".$field->att('UNIT')."\n";
						$fielddata{NAME}=$field->att('NAME');
						$fielddata{TYPE}=$field->att('TYPE');
						$fielddata{UNIT}=$field->att('UNIT');
						push(@inloopdata, \%fielddata);
					}
					$msglist{FIELDDATA} = \@inloopdata;
				}
			}
			
	
		}
	}
	push @loopdata,\%msglist;  
}


#foreach my $value (sort keys %knownmsgs) {
#   print "$value $knownmsgs{$value}\n";
#}

for my $msg ( sort keys %HoA ) {
#  print "$msg : ",$#{$HoA{$msg}}+1,"\n";
#Here we print the contents of the Block hash array (8 lines of text that will need to be parsed at some point)
  if ( $msg eq 'BLOCK' ) {
    for my $i ( 0 .. $#{ $HoA{$msg} } ) {
#        print " ",($i+1)," = $HoA{$msg}[$i]\n";
	}
  }
}

$template->param(MSGS => \@loopdata);

print "Content-Type: text/html\n\n", $template->output;