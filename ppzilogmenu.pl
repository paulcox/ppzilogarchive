#!/usr/bin/perl -w

use strict;  
use CGI;  
use CGI::Carp qw ( fatalsToBrowser );  
use File::Basename;  
use HTML::Template;


#check if the username is available
my $query = new CGI;  
my $username = $query->param("username");   
if (!$username ) {
 $username = 'theman@gmail.com';
}

  # open the html template
my $template = HTML::Template->new(filename => 'ppzilogmenu.tmpl');

#see what we're supposed to do
my $action = $query->param("func");

if ( $action eq 'view') {
 $template->param(SPECIALMSG => "You ($username) want to view!\n");
}

  # fill in some parameters
$template->param(USERNAME => $username);
$template->param(MYFILES => "upload/$username/");

  # send the obligatory Content-Type and print the template output
print "Content-Type: text/html\n\n", $template->output;
