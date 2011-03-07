#!/usr/bin/perl
# Kinomap uploader #################
#
#Author : Paul Cox 2011
#License : none, use at will
#
# NOTES ############################
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
# mine:
# http://api.kinomap.com/upload/getInfo?app_key=L1CEXi2GqqPlxIVD08BQ&login=paulcox&md5_pwd=2a2d595e6ed9a0b24f027f2b63b134d6&
#							gps_format=nmea&upload_type=http&video_format=mp4&timestamp=1298809750&nonce=MNXxpAg3cW&
#							signature=996f3da7778606de83af3807ba917a60cbac92cf&output_format=xml
# response :
#<?xml version="1.0"?>
#<uploadInfo>
#	<token>mjdpd73yq2t36bf4uzvw</token>
#	<url>http://ul2.kinomap.com/api/httpUpload.php</url>
#</uploadInfo>
#
#upload your files either via FTP transfer or HTTP Post.
# The video file: named token.video_format
# The GPS file: named token.gps_format
# The XML/Kino file: named token.kino
# In the case of HTTP Post, you can add this parameter : output_format: xml (default), json
# example :
# http://api.kinomap.com/upload/complete?token=12345654324564321&output_format=xml
#
# Kino file spec:
#Minimum fields required:
#
# title: title of the track
# description: description of the track
# vehicle: id of the vehicle (you can put the id or the name of the vehicle). You'll find the full list as an XML feed here
# videoFormat: mp4, avi, wmv, mov, 3gp (contact us for more informations)
#
#Optional fields:
#
# startAddress: full address of the first point (you can use Google reverse geocoding API). If missing, our servers will fetch it
# endAddress: full address of the last point (you can use Google reverse geocoding API). If missing, our servers will fetch it
# length: the length of the total track in meters. If missing, our servers calculate it from the gps file
# defaultMapType: street or satellite. If missing, default value is "no_pref"
# hardwareModel: an information about the hardware model. For example: Windows 7. If missing, default value is empty
# privacy: the visibility of the track: public, private or sandbox (in this case, the track is private but deleted after two days automaticaly). If missing, default value is public
# thumbnail: the position in seconds of the thumbnail you want (0 < thumbnail < duration of the video)
# videoRotate: the angle in degree to rotate the video (-270, -180, 90, 0, 90, 180, 270). If missing, 0
# videoMute: true to mute the video when transcoding (if your app transcodes it, you still have to put this parameter). If missing, false
#
# example :
# <?xml version="1.0" encoding="UTF-8"?>
# <kinomapTrack version="1.0">
# 	<title>Title</title>
# 	<description>Description</description>
# 	<vehicle>Car</vehicle>
# 	<videoFormat>mp4</videoFormat>
# </kinomapTrack>

use strict;
use warnings;
use HTTP::Request;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Digest::HMAC_SHA1 qw(hmac_sha1_hex);
use LWP::UserAgent;


my $video_infile = "/home/paul/OpenCV-2.2.0/samples/cpp/Qt_sample/cube4.avi";
my $video_outfilep1 = "p1_cube.mp4";
my $video_outfile = "cube.mp4";
#Pass 1:
my $ffmpeg_p1 = "/usr/local/bin/ffmpeg -s 320x240 -y -i $video_infile -pass 1 -threads 0 -r 29.97 -vcodec libx264 -b 512k -flags +loop -cmp +chroma -deblockalpha 0 -deblockbeta 0 -bt 256k -refs 1 -coder 0 -me_range 16 -subq 5 -partitions +parti4x4+parti8x8+partp8x8 -g 25 -keyint_min 25 -level 30 -qmin 10 -qmax 40 -trellis 2 -sc_threshold 40 -i_qfactor 0.71 -acodec libfaac -ar 44100 -ab 96k -ac 2 $video_outfilep1";
#Pass 2:
my $ffmpeg_p2 = "/usr/local/bin/ffmpeg -s 320x240 -y -i $video_outfilep1 -pass 2 -threads 0 -r 29.97 -vcodec libx264 -b 512k -flags +loop -cmp +chroma -deblockalpha 0 -deblockbeta 0 -bt 256k -refs 1 -coder 0 -me_range 16 -subq 5 -partitions +parti4x4+parti8x8+partp8x8 -g 25 -keyint_min 25 -level 30 -qmin 10 -qmax 40 -trellis 2 -sc_threshold 40 -i_qfactor 0.71 -acodec libfaac -ar 44100 -ab 96k -ac 2 $video_outfile";

my $app_key = 'L1CEXi2GqqPlxIVD08BQ';
my $app_secret = `cat app_secret.txt`;
chomp $app_secret;
print $app_secret."\n";
my $login = 'paulcox';
my $md5pass = md5_hex("xxxxxx");
my $timestamp = time();
my @randchars = map {('a'..'z','A'..'Z',0..9)[rand 62]} 1..10 ;
my $nonce = join("",@randchars);
my $sig = hmac_sha1_hex($app_key.$timestamp.$nonce, $app_secret);

my $url = "http://api.kinomap.com/upload/getInfo?app_key=$app_key&login=$login&md5_pwd=$md5pass&";
$url .= "gps_format=nmea&upload_type=http&video_format=mp4&timestamp=$timestamp&nonce=$nonce&";
$url .= "signature=$sig&output_format=xml";
print "$url\n";

# my $request = HTTP::Request->new(GET => $url);
# my $ua = LWP::UserAgent->new;
# my $response = $ua->request($request);
# if ($response->is_success) {
#     print $response->decoded_content."\n";
# } else {
#     print STDERR $response->status_line, "\n";
# }

my $ffmpeg_ret = `$ffmpeg_p1`;
print "$ffmpeg_p1\n";
print $ffmpeg_ret."\n";
$ffmpeg_ret = `$ffmpeg_p2`;
print "$ffmpeg_p2\n";
print $ffmpeg_ret."\n";
`rm $video_outfilep1`;