# Douglas - Peucker algorithm 
# Author. John D. Coryat 01/2007 USNaviguide.com
# Adapted from: http://mapserver.gis.umn.edu/community/scripts/thin.pl
##
# Douglas-Peucker polyline simplification algorithm. First draws single line
# from start to end. Then finds largest deviation from this straight line, and if
# greater than tolerance, includes that point, splitting the original line into
# two new lines. Repeats recursively for each new line created.
##
package USNaviguide_Douglas_Peucker ;
require 5.003 ;
use strict ;

BEGIN {
 use Exporter ;
 use vars qw ( $VERSION @ISA @EXPORT) ;
 $VERSION	= 1.0 ;
 @ISA		= qw ( Exporter ) ;
 @EXPORT	= qw ( 
 Douglas_Peucker
 perp_distance
 haversine_distance_meters
 angle3points
 ) ;
}

# Call as: @Opoints = &Douglas_Peucker( <reference to input array of points>, <tolerance>) ;
# Returns: Array of points
# Points Array Format:
# ([lat1,lng1],[lat2,lng2],...[latn,lngn])
#

sub Douglas_Peucker
{
my $href	= shift ;
my $tolerance	= shift ;
my @Ipoints	= @$href ;
my @Opoints	= ( ) ;
my @stack	= ( ) ;
my $fIndex	= 0 ;
my $fPoint	= '' ;
my $aIndex	= 0 ;
my $anchor	= '' ;
my $max		= 0 ;
my $maxIndex	= 0 ;
my $point	= '' ;
my $dist	= 0 ;
my $polygon	= 0 ;					# Line Type

$anchor = $Ipoints[0] ; 				# save first point

push( @Opoints, $anchor ) ;

$aIndex = 0 ;						# Anchor Index

# Check for a polygon: At least 4 points and the first point == last point...

if ( $#Ipoints >= 4 and $Ipoints[0] == $Ipoints[$#Ipoints] )
{
 $fIndex = $#Ipoints - 1 ;				# Start from the next to last point
 $polygon = 1 ;						# It's a polygon

} else
{
 $fIndex = $#Ipoints ;					# It's a path (open polygon)
}

push( @stack, $fIndex ) ;

# Douglas - Peucker algorithm...

while(@stack)
{
 $fIndex = $stack[$#stack] ;
 $fPoint = $Ipoints[$fIndex] ;
 $max = $tolerance ;		 			# comparison values
 $maxIndex = 0 ;

 # Process middle points...

 for (($aIndex+1) .. ($fIndex-1))
 {
  $point = $Ipoints[$_] ;
  $dist = &perp_distance($anchor, $fPoint, $point);

  if( $dist >= $max )
  {
   $max = $dist ;
   $maxIndex = $_;
  }
 }

 if( $maxIndex > 0 )
 {
  push( @stack, $maxIndex ) ;
 } else
 {
  push( @Opoints, $fPoint ) ;
  $anchor = $Ipoints[(pop @stack)] ;
  $aIndex = $fIndex ;
 }
}

if ( $polygon )						# Check for Polygon
{
 push( @Opoints, $Ipoints[$#Ipoints] ) ;		# Add the last point

 # Check for collapsed polygons, use original data in that case...

 if( $#Opoints < 4 )
 {
  @Opoints = @Ipoints ;
 }
}

return ( @Opoints ) ;

}

# Calculate Perpendicular Distance in meters between a line (two points) and a point...
# my $dist = &perp_distance( <line point 1>, <line point 2>, <point> ) ;

sub perp_distance					# Perpendicular distance in meters
{
 my $lp1	= shift ;
 my $lp2	= shift ;
 my $p		= shift ;
 my $dist	= &haversine_distance_meters( $lp1, $p ) ;
 my $angle	= &angle3points( $lp1, $lp2, $p ) ; 

 return ( sprintf("%0.6f", abs($dist * sin($angle)) ) ) ;
}

# Calculate Distance in meters between two points...

sub haversine_distance_meters
{
 my $p1	= shift ;
 my $p2	= shift ;

 my $O = 3.141592654/180 ;
 my $b = $$p1[0] * $O ;
 my $c = $$p2[0] * $O ;
 my $d = $b - $c ;
 my $e = ($$p1[1] * $O) - ($$p2[1] * $O) ;
 my $f = 2 * &asin( sqrt( (sin($d/2) ** 2) + cos($b) * cos($c) * (sin($e/2) ** 2)));

 return sprintf("%0.4f",$f * 6378137) ; 		# Return meters

 sub asin
 {
  atan2($_[0], sqrt(1 - $_[0] * $_[0])) ;
 }
}

# Calculate Angle in Radians between three points...

sub angle3points					# Angle between three points in radians
{
 my $p1	= shift ;
 my $p2	= shift ;
 my $p3 = shift ;
 my $m1 = &slope( $p2, $p1 ) ;
 my $m2 = &slope( $p3, $p1 ) ;
 
 return ($m2 - $m1) ;

 sub slope						# Slope in radians
 {
  my $p1	= shift ;
  my $p2	= shift ;
  return( sprintf("%0.6f",atan2( (@$p2[1] - @$p1[1]),( @$p2[0] - @$p1[0] ))) ) ;
 }
}

1;

__END__

=head1 SYNOPSIS

# Test Program:

# Douglas - Peucker Test Program
# Author. John D. Coryat 01/2007 USNaviguide.com

use strict;

my $infile	= $ARGV[0] ;
my $outfile	= $ARGV[1] ;
my $tolerance	= $ARGV[2] ;
my @Ipoints	= ( ) ;
my @Opoints	= ( ) ;
my $data	= '' ;

if(!$infile or !$outfile or !$tolerance)
{
  print "Usage: douglas-peucker.pl <input file name> <output file name> <tolerance in meters>\n";
  print "Data format: (lat,lng)\n" ;
  exit ;
}

if ( $tolerance <= 0 )
{
 print "Tolerance (meters) must be greater than zero.\n" ;
 exit
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

@Opoints = &Douglas_Peucker( \@Ipoints, $tolerance ) ;

open OUT, ">$outfile" ;

foreach $data (@Opoints)
{ 
 print OUT "($$data[0],$$data[1])\n" ;
}

close OUT ;

print "Input: " . $#Ipoints . " Output: " . $#Opoints . " Tolerance: $tolerance\n" ;

=cut
