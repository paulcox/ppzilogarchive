# Google Polygon Encoding algorithm 
# Author. John D. Coryat 10/2007 USNaviguide.com and Marcelo Montagna maps.forum.nu
# Adapted from: http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/
##
# If you want to display complicated path data on a Google Map, 
# the most efficient way to do so is with an encoded polyline or polygon.
##

package USNaviguide_Google_Encode ;
require 5.003 ;
use USNaviguide_Douglas_Peucker ;
use POSIX ;
use strict ;

BEGIN {
 use Exporter ;
 use vars qw ( $VERSION @ISA @EXPORT) ;
 $VERSION	= 1.0 ;
 @ISA		= qw ( Exporter ) ;
 @EXPORT	= qw ( 
 Google_Encode
 ) ;
}

# Call as: (<Encoded Levels String>, <Encoded Points String>) = &Google_Encode(<Reference to array of points>, <tolerance in meters>);
# Points Array Format:
# ([lat1,lng1],[lat2,lng2],...[latn,lngn])
#

sub Google_Encode
{
 my $pointsRef	= shift;
 my $tolerance	= shift ;
 my @points	= @{$pointsRef};
 my $encodedPoints = '' ;
 my $encodedLevels = '' ;

 # Check for tolerance size...

 if ( !defined($tolerance) or !$tolerance )
 {
  $tolerance	= 1 ;				# Default Value: 1 meter
 }

 # Run D-P on the points, eliminate redundancies...
 printf "Doug #pts (in): %d\n", $#points;
 @points = &Douglas_Peucker( \@points, $tolerance ) ;
 printf "Doug #pts (out): %d\n", $#points;
 # Encode Points...

 $encodedPoints = &createEncodings(\@points);

 # Encode Levels...

 $encodedLevels = &encodeLevels(\@points, $tolerance);

 # Escape backslashes

 $encodedPoints =~ s!\\!\\\\!g;

 return ($encodedLevels, $encodedPoints);
}

sub encodeLevels
{
 my $pointsRef	= shift ;
 my $tolerance	= shift ;
 my @points	= @{$pointsRef};
 my @point	= ( ) ;
 my %pnthash	= ( ) ;
 my @pntlev	= ( ) ;
 my $numLevels	= 18 ;
 my $zoomFactor	= 2 ;
 my $en_levels	= '' ;
 my $lat	= 0 ;
 my $lng	= 0 ;
 my $i		= 0 ;
 my $j		= 0 ;
 my $k		= 0 ;
 my $x		= '' ;
 my $encodelev	= &encodeNumber(1) ;

 # Build up a point hash to be used to reference original points to their location...
 # Mark all points at lowest possible level to start...

 for($i=0; $i < scalar(@points); $i++)
 {
  $pointsRef = $points[$i];
  @point = @{$pointsRef};
  $lat = $point[0];
  $lng = $point[1];
  $pnthash{"$lat,$lng"} = $i ;
  $pntlev[$i] = $encodelev ;
 }

 # Iterate through the levels and calculate with an increasing tolerance...
 # Each time through, mark all points left with current level...

 for($i = 1; $i < $numLevels; $i++)
 {
  @points = &Douglas_Peucker( \@points, $tolerance * ($zoomFactor ** $i) ) ;

  $encodelev	= &encodeNumber($i) ;

  # Mark Points Still present...

  for($j=0; $j < scalar(@points); $j++)
  {
   $pointsRef = $points[$j];
   @point = @{$pointsRef};
   $lat = $point[0];
   $lng = $point[1];
   $k = $pnthash{"$lat,$lng"} ;
   $pntlev[$k] = $encodelev ;
  }

  # Stop when all points are calculated and only 3 are left (line)...

  if ( scalar(@points) < 4 )
  {
   last ;
  }
 }

 # Force first and last point to be highest level...

 $encodelev = &encodeNumber($numLevels - 1) ;

 $pntlev[0] = $encodelev ;
 $pntlev[$#pntlev] = $encodelev ;

 # Build up encoded Level string...

 foreach $x ( @pntlev )
 {
  $en_levels .= $x ;
 }

 return $en_levels;
}

# ############## Numeric subroutines below #############################
# Documentation from Google http://www.google.com/apis/maps/documentation/polylinealgorithm.html
#   
#   1. Take the initial signed value:
#	  -179.9832104
#   2. Take the decimal value and multiply it by 1e5, flooring the result:
#	  -17998321

sub createEncodings
{
 my $pointsRef	= shift ;
 my @points 	= @{$pointsRef};
 my $encoded_points = '' ;
 my $pointRef	= '' ;
 my @point	= ( ) ;
 my $plat	= 0 ;
 my $plng	= 0 ;
 my $lat	= 0 ;
 my $lng	= 0 ;
 my $late5	= 0 ;
 my $lnge5	= 0 ;
 my $dlat	= 0 ;
 my $dlng	= 0 ;
 my $i		= 0 ;

 for($i=0; $i < scalar(@points); $i++)
 {

  $pointRef = $points[$i];
  @point = @{$pointRef};
  $lat = $point[0];
  $lng = $point[1];
  $late5 = floor($lat * 1e5);
  $lnge5 = floor($lng * 1e5);
  $dlat = $late5 - $plat;
  $dlng = $lnge5 - $plng;
  $plat = $late5;
  $plng = $lnge5;
  $encoded_points .= &encodeSignedNumber($dlat) . &encodeSignedNumber($dlng);
 }
 return $encoded_points;
}

#   3. Convert the decimal value to binary. Note that a negative value must be inverted 
#      and provide padded values toward the byte boundary:
#	  00000001 00010010 10100001 11110001
#	  11111110 11101101 10100001 00001110
#	  11111110 11101101 01011110 00001111
#   4. Shift the binary value:
#	  11111110 11101101 01011110 00001111 0
#   5. If the original decimal value is negative, invert this encoding:
#	  00000001 00010010 10100001 11110000 1
#   6. Break the binary value out into 5-bit chunks (starting from the right hand side):
#	  00001 00010 01010 10000 11111 00001
#   7. Place the 5-bit chunks into reverse order:
#	  00001 11111 10000 01010 00010 00001
#   8. OR each value with 0x20 if another bit chunk follows:
#	  100001 111111 110000 101010 100010 000001
#   9. Convert each value to decimal:
#	  33 63 48 42 34 1
#  10. Add 63 to each value:
#	  96 126 111 105 97 64
#  11. Convert each value to its ASCII equivalent:
#	  `~oia@

sub encodeSignedNumber
{
 use integer;
 my $num 	= shift;
 my $sgn_num 	= $num << 1;

 if ($num < 0)
 {
  $sgn_num = ~($sgn_num);
 }
 return &encodeNumber($sgn_num);
}

sub encodeNumber
{
 use integer;
 my $encodeString = '' ;
 my $num	= shift;
 my $nextValue	= 0 ;
 my $finalValue	= 0 ;

 while($num >= 0x20)
 {
  $nextValue = (0x20 | ($num & 0x1f)) + 63;
  $encodeString .= chr($nextValue);
  $num >>= 5;
 }
 $finalValue = $num + 63;
 $encodeString .= chr($finalValue);
 return $encodeString;
}

1;

__END__

=head1 SYNOPSIS

# Test Program:

# Google Polygon Encoding Test Program
# Author. John D. Coryat 01/2007 USNaviguide.com

use strict;

my $infile	= $ARGV[0] ;
my $outfile	= $ARGV[1] ;
my $tolerance	= $ARGV[2] ;
my @Ipoints	= ( ) ;
my $output	= '' ;
my $encodedPoints = '' ;
my $encodedLevels = '' ;

if(!$infile or !$outfile)
{
 print "Usage: Google_Encode.pl <input file name> <output file name> <tolerance in meters>\n";
 print "Data format: (lat,lng)\n" ;
 exit ;
}

if ( !(-s $infile) )
{
 print "Input File ($infile) not found.\n" ;
 exit
}

if (-s $outfile)
{
 print "Output File ($outfile) exists.\n" ;
 exit
}

open IN, $infile ;

while ( $data =  )
{
 if ( $data	=~ /\((.*),(.*)\)/ )
 {
  push( @Ipoints, [$1,$2] ) ;
 }
}
close IN ;

print "Input: " . $#Ipoints . " Tolerance in Meters: $tolerance\n" ;

# The output is a JSON string containing an array of polylines.

($encodedLevels, $encodedPoints) = &Google_Encode(\@Ipoints, $tolerance);

$output = '' ;
$output .= 'new GPolygon.fromEncoded({';
$output .= '  polylines: [';
$output .= '	{points: "'.$encodedPoints.'",';
$output .= '	 levels: "'.$encodedLevels.'",';
$output .= '	 color: "#0000ff",';
$output .= '	 opacity: 0.7,';
$output .= '	 weight: 3,';
$output .= '	 numLevels: 18,';
$output .= '	 zoomFactor: 2},';
$output .= '],';
$output .= '  fill: true,';
$output .= '  color: "#0000ff",';
$output .= '  opacity: 0.4,';
$output .= '  outline: true';
$output .= '});';

open OUT, ">$outfile" ;

print OUT $output;

close OUT ;

=cut
