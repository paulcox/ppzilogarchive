#!/usr/bin/perl -w  
 
use strict;  
use CGI;  
use CGI::Carp qw ( fatalsToBrowser );  
use File::Basename;  
 
$CGI::POST_MAX = 1024 * 5000 * 100;  
my $safe_filename_characters = "a-zA-Z0-9_.-";  
my $upload_dir = "/var/www/upload";  
 
my $query = new CGI;  
my $logfile = $query->param("logfile");   
my $datafile = $query->param("datafile");   
my $email_address = $query->param("email_address");  

print $query->header ( );  
print <<END_HTML;   
<html>  
 <head>  
   <title>Log Files Uploaded</title>  
 </head>  
 <body>  
<img src="../archive_banner.png"> 
END_HTML

#############check file names##############

if ( !$logfile )  
{  
 if ($query->param("func") eq 'delete') {
 my $filetodel = $query->param("filetodel");
 `rm $filetodel.log`;
 `rm $filetodel.data`;
  printf "<br>$filetodel.* files deleted<br><A href=/cgi-bin/ppzilogmenu.pl?username=$email_address&func=view>.. Back to upload logs</A>";
  exit;
 } else {
  print $query->header ( );  
  print "<p>There was a problem uploading your .log file (try a smaller file).</p>";  
  exit; 
 } 
}  

my ( $name, $path, $extension ) = fileparse ( $logfile, '\..*' );  
$logfile = $name . $extension;  
$logfile =~ tr/ /_/;  
$logfile =~ s/[^$safe_filename_characters]//g;  

if ( $logfile =~ /^([$safe_filename_characters]+)$/ )  
{  
 $logfile = $1;  
}  
else  
{  
 die "Log file filename contains invalid characters";  
}  

if ($extension ne '.log') {
 die "Log file doesn't end with .log but: $extension\n";
}

if ( !$datafile )  
{  
 print $query->header ( );  
 print "<p>There was a problem uploading your .data file (try a smaller file).\n</p>";  
 exit;  
}  

( $name, $path, $extension ) = fileparse ( $datafile, '\..*' );  
$datafile = $name . $extension;  
$datafile =~ tr/ /_/;  
$datafile =~ s/[^$safe_filename_characters]//g;  

if ( $datafile =~ /^([$safe_filename_characters]+)$/ )  
{  
 $datafile = $1;  
}  
else  
{  
 die "Data File filename contains invalid characters\n";  
}  

if ($extension ne '.data') {
 die "Data file doesn't end with .data but: $extension\n";
}

###########Put files in upload area############

my $userdir = $email_address;
#system(mkdir, $userdir);
my $mkdir_ret = `mkdir $upload_dir/$userdir`;
`chmod 777 $upload_dir/$userdir`;

my $upload_filehandle = $query->upload("logfile");  
open ( UPLOADFILE, ">$upload_dir/$userdir/$logfile" ) or die "$!";  
binmode UPLOADFILE;  

while ( <$upload_filehandle> )  
{  
 print UPLOADFILE;  
}  
close UPLOADFILE;  

$upload_filehandle = $query->upload("datafile");  
open ( UPLOADFILE, ">$upload_dir/$userdir/$datafile" ) or die "$!";  
binmode UPLOADFILE;  

while ( <$upload_filehandle> )  
{  
 print UPLOADFILE;  
}  
close UPLOADFILE;  

#make files readable to all
#not necessary but makes debugging easier:
`chmod a+r $upload_dir/$userdir/$datafile`;
`chmod a+r $upload_dir/$userdir/$logfile`;

print <<END_HTML;  
   <p>Thanks for uploading your logs!</p>  
   <p>Your email address: $email_address</p>  
   <p>Your files:</p>  
   <p>Log file : <A href="/upload/$userdir/$logfile">$logfile</A></p>  
   <p>Data file : <A href="/upload/$userdir/$datafile">$datafile</A></p>

<form action="/cgi-bin/upload_logfile.cgi" method="GET">
   <input type="hidden" name="email_address" value="$email_address">
   <input type="hidden" name="filetodel" value="$upload_dir/$userdir/$name">
   <p>If you wish to undo the upload click <input type="submit" name="func" value="delete"/></p>
</form>

<form action="/cgi-bin/log2nmea.pl" method="GET">
   <input type="hidden" name="user" value="$email_address">
   <input type="hidden" name="logfile" value="$name">
   <p>To generate a log summary click <input type="submit" name="func" value="summary"/></p>
</form>   
   <p><A href="ppzilogmenu.pl?username=$email_address&func=view">...Back to View Page</A></p> 
 </body>  
</html>  
END_HTML
