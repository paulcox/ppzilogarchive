#!/usr/bin/perl -w
use HTML::Template;

  # open the html template
my $template = HTML::Template->new(filename => 'test.tmpl');

  # fill in some parameters
$template->param(HOME => $ENV{HOME});
$template->param(PATH => $ENV{PATH});

  # send the obligatory Content-Type and print the template output
print "Content-Type: text/html\n\n", $template->output;
