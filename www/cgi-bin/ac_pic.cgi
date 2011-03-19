#!/usr/bin/perl -w  
 
use strict;  
use CGI;  
use CGI::Carp qw ( fatalsToBrowser );  
use File::Basename;  
 
$CGI::POST_MAX = 1024 * 500 * 100;  
my $safe_filename_characters = "a-zA-Z0-9_.-";  
my $upload_dir = "/var/www/upload";  
 
my $query = new CGI;  
my $picfile = $query->param("picfile");   
my $email_address = $query->param("email_address");  
my $acname = $query->param("acname");  

print $query->header ( );  
print <<END_HTML;   
<html>  
 <head>  
   <title>Aircraft picture</title>  
 </head>  
 <body>  
<img src="../archive_banner.png"> 
END_HTML

#############check file names##############

if ( !$picfile )  
{  
 if ($query->param("func") eq 'delete') {
  my $filetodel = $query->param("filetodel");
  `rm $picfile.png`;
  printf "<br>$picfile.png deleted<br><A href=/cgi-bin/ppzilogmenu.pl?username=$email_address&func=view>.. Back to upload logs</A>";
  exit;
 } else { 
  if ($acname) {
   print "<p>Current Picture:</p>  <img src=/upload/$email_address/$acname.png>" if (-e "$upload_dir/$email_address/$acname.png");
   print <<END_HTML; 
<form action="/cgi-bin/ac_pic.cgi" method="post" enctype="multipart/form-data"> 
     <p>Picture to Upload: <input type="file" name="picfile" /></p> 
     <p>Your Email Address: <input type="text" name="email_address" value="$email_address"/></p>
	 <p>Aircraft Name: <input type="text" name="acname" value="$acname"/></p>  
     <p><input type="submit" name="Submit" value="Upload" /></p> 
</form> </body> </html>
END_HTML
   exit;
  } else {
   print $query->header ( );  
   print "<p>There was a problem uploading your picture (try a smaller file).</p>";  
   exit; 
  } 
 }
}  

my ( $name, $path, $extension ) = fileparse ( $picfile, '\..*' );  
$picfile = $name . $extension;  
$picfile =~ tr/ /_/;  
$picfile =~ s/[^$safe_filename_characters]//g;  

if ( $picfile =~ /^([$safe_filename_characters]+)$/ ) {  
  $picfile = $1;  
} else {  
  die "Log file filename contains invalid characters";  
}  

if ($extension ne '.png') {
 die "Picture should be .png not $extension\n";
}

###########Put files in upload area############

my $userdir = $email_address;
#system(mkdir, $userdir);
my $mkdir_ret = `mkdir $upload_dir/$userdir`;
`chmod 777 $upload_dir/$userdir`;

my $upload_filehandle = $query->upload("picfile");  
open ( UPLOADFILE, ">$upload_dir/$userdir/$acname.png" ) or die "$!";  
binmode UPLOADFILE;  

while ( <$upload_filehandle> ) {  
 print UPLOADFILE;  
}  
close UPLOADFILE;  

#make files readable to all
#not necessary but makes debugging easier:
`chmod a+r $upload_dir/$userdir/$picfile`;

print <<END_HTML;  
   <p>Thanks for uploading your picture</p>  
   <p>Your email address: $email_address</p>  
   <p>Your Picture:</p>  <img src="/upload/$userdir/$acname.png">
   <p>file : <A href="/upload/$userdir/$acname.png">$acname.png</A></p>  

<form action="/cgi-bin/ac_pic.cgi" method="GET">
   <input type="hidden" name="email_address" value="$email_address">
   <input type="hidden" name="filetodel" value="$upload_dir/$userdir/$acname">
   <p>If you wish to undo the upload click <input type="submit" name="func" value="delete"/></p>
</form>
   <p><A href="ppzilogmenu.pl?username=$email_address&func=view">...Back to View Page</A></p> 
 </body>  
</html>  
END_HTML
