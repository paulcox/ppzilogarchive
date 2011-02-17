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

#if user requests to view his file list, generate table
if ( $action eq 'view') {
 my $logs = `ls $upload_dir/$username/*.sum`;
 my @sums = split(/\n/,$logs);

 my $lognum = 0;
 my @loopdata = ();
 foreach(@sums) {
  my %rowdata;
#  my %sumdata = map((),);
  
  my $absname = $_;
  my ( $relname, $path, $extension ) = fileparse ( $absname, '\..*' ); 
   
  $rowdata{LOGNAME} = "$relname.log" ;
  $rowdata{LOGLINK} = "upload/$username/$relname.log";
  
  my $summary = `cat $absname`;
  my @sumlines = split(/\n/,$summary);
  my @inloopdata = ();
  foreach (@sumlines) {
    my %sumdata;
    my ($fieldname,$fieldval) = split(/\:/,$_);
	if ($fieldname eq 'warning') { next; }
	$sumdata{SUMFIELD} = $fieldname ;
	$sumdata{DATAFIELD} = $fieldval ;
	push(@inloopdata, \%sumdata);
  }
  $rowdata{SUMDATA} = \@inloopdata;
  push(@loopdata, \%rowdata);
  $lognum++;
 }

 $template->param(SPECIALMSG => "You ($username) want to view!\n");
# $template->param(LOGS => [ {logname => $logs, logsum => 'summary1'},
#							{logname => 'second', logsum => 'summary2'},
#							]);							
 $template->param(LOGS => \@loopdata);
}

  # send the obligatory Content-Type and print the template output
print "Content-Type: text/html\n\n", $template->output;
