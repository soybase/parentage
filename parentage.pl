#!/usr/bin/env perl

# Program: parentage.pl
# Program description: see usage message.
# Steven Cannon 2023

use feature say; 
use warnings; 
use strict; 
use Getopt::Long;

my $parents;
my $start;
my $format = "string,table";
my $verbose;
my $help;

my $usage = <<EOS;
  Usage:  parentage.pl -parents FILE [-options]

  Given a file of individuals and parents, recursively determine the pedigree
  (the parentage going back as many generations as possible) for an individual.
  Can be calculated for a single indicated individual or for all in the parents file.

  The parents file should be structured like this.
  The individual (progeny) is on the left, and the parent(s) are on the right
    indID  parent1  parent2
    A      B        C
    D      B        C
    E      B        F
    G      H        -    # an individual with only one parent
    I      -        H    # another individual with only one parent

  Required:
    -parents  File listing the individuals and parents

  Options:
    -start    ID of an individual for which to calculate parentage.
              If not provided, report parentage for all individuals.
    -format   Output format. Options: string, table [string,table]
    -verbose  Report some intermediate information.
    -help     This message.
EOS

GetOptions(
  'parents=s'  => \$parents,  # required
  'start:s'    => \$start,
  'format:s'   => \$format,
  'v|verbose'  => \$verbose,
  'h|help'     => \$help,
);

die $usage if ($help || !defined($parents));

open (my $P_FH, "<", $parents) or die "Can't open in parents: $parents $!\n";

my $ped_str;
my %HoA;
my $START_IND; # global; there are also local instances: $ind
while (<$P_FH>){
  chomp;
  next if (/^#/);
  my ($ind, $p1, $p2) = split(/\s+/, $_);
  if ( defined($p1) && !defined($p2) ){
    $HoA{ $ind } = [ $p1 ];
    if ($verbose){say "$ind, $p1, -"};
  }
  elsif ( !defined($p1) && defined($p2) ){
    $HoA{ $ind } = [ $p2 ];
    if ($verbose){say "$ind, -, $p2"};
  }
  else {
    $HoA{ $ind } = [ $p1, $p2 ];
    if ($verbose){say "$ind, $p1, $p2"};
  }
}
say "";

if ($start){ # Starting individual was provided, so calculate parentage for it
  my $ind = $start;
  $START_IND = $ind;
  $ped_str = "[$ind]: < $ind >";
  ped($ind, \%HoA);
  if ($format =~ /string/){ 
    $ped_str =~ s/</(/g; $ped_str =~ s/>/)/g; 
    $ped_str =~ s/\[([^]]+)\]:/$1:/;
    say $ped_str, "\n" 
  }
}
else { # No starting individual was provided, so calculate parentage for all
  while( my ($key, $value) = each(%HoA)) {
    my ($ind, $p1, $p2) = ($key, $value->[0], $value->[1]);
    $START_IND = $ind;
    $ped_str = "[$ind]: < $ind >";
    ped($ind, \%HoA);
    if ($format =~ /string/){ 
      $ped_str =~ s/</(/g; $ped_str =~ s/>/)/g; 
      $ped_str =~ s/\[([^]]+)\]:/$1:/;
      say $ped_str 
    }
    if ($format =~ /table/){ say "" }
  }
}

sub ped{
  my $key = shift;
  my $hshref = shift;
  for my $item ($hshref){
    my ($p1, $p2);
    if ($HoA{$key}){
      $p1 = $item->{$key}->[0];
      $p2 = $item->{$key}->[1];
      if ( defined($p1) && defined($p2) ){
        if ($format =~ /table/){ say join("\t", $START_IND, $key, $p1, $p2) }
        $ped_str =~ s/ $key / $key < $p1 , $p2 > /g;
        ped($p1, $hshref);
        ped($p2, $hshref);
      }
      elsif ( defined($p1) && !defined($p2) ){
        if ($format =~ /table/){ say join("\t", $START_IND, $key, $p1, "-") }
        $ped_str =~ s/ $key / $key < $p1 > /g;
        ped($p1, $hshref);
      }
      elsif ( !defined($p1) && defined($p2) ){
        if ($format =~ /table/){ say join("\t", $START_IND, $key, "-", $p2) }
        $ped_str =~ s/ $key / $key < $p2 > /g;
        ped($p2, $hshref);
      }
    }
    else { # Individual is without a parent, so return
      if ($format =~ /table/){ say join("\t", $START_IND, $key, "-", "-") }
      return 0;
    }
  }
}

__END__

Versions
2023-11-06 Initial version
2023-11-07 Report starting individual in first column of table output
