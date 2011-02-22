#!/usr/bin/perl -w

use strict;  
use CGI;  
use CGI::Carp qw ( fatalsToBrowser );  
use File::Basename;  
use HTML::Template;

my $upload_dir = "/var/www/upload";

#check if the username is available
my $query = new CGI;  
my $username = $query->param("username");   
if (!$username ) {
 $username = 'theman@gmail.com';
}

  # open the html template
#my $template = HTML::Template->new(filename => 'ppzilogmenu.tmpl', global_vars => 1);
my $template = HTML::Template->new(filename => 'ppzilogmenu.tmpl');
  # fill in some parameters
$template->param(USERNAME => $username);
$template->param(MYFILES => "upload/$username/");

#see what we're supposed to do
my $action = $query->param("func");

#check if summary exists, if so display, otherwise propose link to generate
#if user requests to view his file list, generate table
if ( $action eq 'view') {
 my $logs = `ls $upload_dir/$username/*.log`;
 my @logs = split(/\n/,$logs);
 my $lognum = 0;
 my @loopdata = ();
 my $lat;
 my $lon;
  
 foreach(@logs) {
  my %rowdata;
  my $absname = $_;
  
  my ( $relname, $path, $extension ) = fileparse ( $absname, '\..*' ); 
   
  $rowdata{LOGNAME} = "$relname.log" ;
  $rowdata{LOGLINK} = "upload/$username/$relname.log";
  if (-r "$upload_dir/$username/$relname.nmea") {
	$rowdata{NMEA} = "upload/$username/$relname.nmea";
  } 
    if (-r "$upload_dir/$username/$relname.kml") {
	$rowdata{KML} = "upload/$username/$relname.kml";
  } 
  my $abssumname = $absname;
  $abssumname =~ s/\.log/\.sum/;
  my $summary = `cat $abssumname`;
  if ($summary) {
   my @sumlines = split(/\n/,$summary);
   my @inloopdata = ();
   foreach (@sumlines) {
     my %sumdata;
     my ($fieldname,$fieldval) = split(/\:/,$_);
	 if ($fieldname eq 'warning') { next; }
	 if ($fieldname eq 'TO lat') {$lat=$fieldval;}
	 if ($fieldname eq 'TO lon') {$lon=$fieldval;}
	 $sumdata{SUMFIELD} = $fieldname ;
	 $sumdata{DATAFIELD} = $fieldval ;
	 push(@inloopdata, \%sumdata);
   }
   $rowdata{SUMDATA} = \@inloopdata;
   push(@loopdata, \%rowdata);
   $lognum++;
   $rowdata{MAP} = "http://maps.google.com/maps/api/staticmap?center=$lat,$lon&zoom=9&size=256x256&maptype=roadmap
&markers=color:blue|label:HOME|$lat,$lon&sensor=false";
   } else {
#	$rowdata{SUMDATA} = "none";
	$rowdata{GENSUM} = "log2nmea.pl?user=$username&logfile=$relname";
	push(@loopdata, \%rowdata);
	$lognum++;
  }
#$rowdata{MAP} = "http://maps.google.com/maps/api/staticmap?center=1307 mcleland ave, port st joe, fl&zoom=14&size=256x256&maptype=roadmap
#&sensor=false";
$rowdata{FL}="Type some text here";
} 
 $template->param(SPECIALMSG => "You ($username) want to view!\n");
# $template->param(LOGS => [ {logname => $logs, logsum => 'summary1'},
#							{logname => 'second', logsum => 'summary2'},
#							]);							
 $template->param(LOGS => \@loopdata);
}

  # send the obligatory Content-Type and print the template output
print "Content-Type: text/html\n\n", $template->output;
