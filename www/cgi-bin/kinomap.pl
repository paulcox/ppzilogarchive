#!/usr/bin/perl
#Kinomap uploader
#
#Author : Paul Cox 2011
#License : none, use at will
# app_key: Application key
# login: User login
# md5_pwd: User password md5 hash
# upload_type: http or ftp (in this case use member login and md5_pwd)
# video_format: mp4, avi, wmv, mov, 3gp (contact us for more informations)
# gps_format: nmea, gpx
# timestamp: The number of seconds that have elapsed since midnight, January 1, 1970, also known as UNIX time
# nonce: A randomly-generated string
# signature: The cryptographic method used to sign the call 
# (An sha1 hash of the concatenation of app_key, timestamp and nonce, with your app_secret)
# output_format: xml (default), json
# example:
# http://api.kinomap.com/upload/getInfo?app_key=123456789abcdefghij&login=demo&md5_pwd=defekfzlekfzefdadadzdadzadzd&
#							gps_format=nmea&upload_type=http&video_format=mp4&timestamp=1297696525&nonce=abcdefghij&
#							signature=jden54fe8dfde85d1&output_format=xml
#mine:
# http://api.kinomap.com/upload/getInfo?app_key=L1CEXi2GqqPlxIVD08BQ&login=paulcox&md5_pwd=2a2d595e6ed9a0b24f027f2b63b134d6&
#							gps_format=nmea&upload_type=http&video_format=mp4&timestamp=1298624912&nonce=xJgFKzvPuw&
#							signature=aabe06c6ef7ac2a4d0c156ed9dcd0f215164e24e&output_format=xml


use strict;
use warnings;
use HTTP::Request;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use LWP::UserAgent;


my $video_infile = "";
my $video_outfile = "";
#Pass 1:
my $ffmpeg_p1 = "/usr/bin/ffmpeg -s 320x240 -y -i $video_infile -pass 1 -threads 0 -r 29.97 -vcodec libx264 -b 512k -flags +loop -cmp +chroma -deblockalpha 0 -deblockbeta 0 -bt 256k -refs 1 -coder 0 -me_range 16 -subq 5 -partitions +parti4x4+parti8x8+partp8x8 -g 25 -keyint_min 25 -level 30 -qmin 10 -qmax 40 -trellis 2 -sc_threshold 40 -i_qfactor 0.71 -acodec libfaac -ar 44100 -ab 96k -ac 2 $video_outfile";
#Pass 2:
my $ffmpeg_p2 = "/usr/bin/ffmpeg -s 320x240 -y -i $video_infile -pass 2 -threads 0 -r 29.97 -vcodec libx264 -b 512k -flags +loop -cmp +chroma -deblockalpha 0 -deblockbeta 0 -bt 256k -refs 1 -coder 0 -me_range 16 -subq 5 -partitions +parti4x4+parti8x8+partp8x8 -g 25 -keyint_min 25 -level 30 -qmin 10 -qmax 40 -trellis 2 -sc_threshold 40 -i_qfactor 0.71 -acodec libfaac -ar 44100 -ab 96k -ac 2 $video_outfile";

my $app_key = 'L1CEXi2GqqPlxIVD08BQ';
my $app_secret = 'SFooqYZvq1oYf2787TpG';
my $login = 'paulcox';
my $md5pass = md5_hex("xxxxx");
my $timestamp = time();
my @randchars = map {('a'..'z','A'..'Z',0..9)[rand 62]} 1..10 ;
my $nonce = join("",@randchars);
my $sig = sha1_hex($app_key.$timestamp.$nonce.$app_secret);

my $url = "http://api.kinomap.com/upload/getInfo?app_key=$app_key&login=$login&md5_pwd=$md5pass&";
$url .= "gps_format=nmea&upload_type=http&video_format=mp4&timestamp=$timestamp&nonce=$nonce&";
$url .= "signature=$sig&output_format=xml";

print "$url\n";
my $request = HTTP::Request->new(GET => $url);

my $ua = LWP::UserAgent->new;
my $response = $ua->request($request);
if ($response->is_success) {
    print $response->decoded_content;
}
else {
    print STDERR $response->status_line, "\n";
}
print "\n";