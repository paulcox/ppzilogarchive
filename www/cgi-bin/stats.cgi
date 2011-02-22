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
my $template = HTML::Template->new(filename => 'stats.tmpl');
  # fill in some parameters
#$template->param(USERNAME => $username);
#$template->param(MYFILES => "upload/$username/");

  # send the obligatory Content-Type and print the template output
print "Content-Type: text/html\n\n", $template->output;