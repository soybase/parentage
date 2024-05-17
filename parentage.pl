#!/usr/bin/env perl

# Program: parentage.pl
# Program description: see usage message.
# Steven Cannon 2023

use feature say; 
use warnings; 
use strict; 
use Getopt::Long;

my ($parents, $query, $noself, $verbose, $help);
my $line_ct = 0;
my $format = "table";

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
    -query    ID of an individual for which to calculate parentage.
              If not provided, report parentage for all individuals.
    -format   Output format. Options: string, table. Either or both (string,table) can be specified. [table]
    -noself   Remove the query ID from the parentage string.
    -verbose  Report some intermediate information.
    -help     This message.
EOS

GetOptions(
  'parents=s'  => \$parents,  # required
  'query:s'    => \$query,
  'format:s'   => \$format,
  'noself'     => \$noself,
  'v|verbose'  => \$verbose,
  'h|help'     => \$help,
);

die $usage if ($help || !defined($parents));

open (my $P_FH, "<", $parents) or die "Can't open in parents: $parents $!\n";

my $ped_str;
my %HoA;
my $QUERY_IND; # global; there are also local instances: $ind
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
#say "";

if ($query){ # Query individual was provided, so calculate parentage for it
  my $ind = $query;
  # Print header line
  unless ($format =~ /string/){
    say "Genotype\tFemale Parent\tMale Parent";
  }

  $QUERY_IND = $ind;
  $ped_str = "[$ind]: < $ind >";
  ped($ind, \%HoA);
  if ($format =~ /string/){ print_ped_string($ped_str) }
}
else { # No query individual was provided, so calculate parentage for all
  while( my ($key, $value) = each(%HoA)) {
    my ($ind, $p1, $p2) = ($key, $value->[0], $value->[1]);
    $QUERY_IND = $ind;
    $ped_str = "[$ind]: < $ind >";
    ped($ind, \%HoA);
    if ($format =~ /string/){ print_ped_string($ped_str) }
    if ($format =~ /table/){ say "" }
  }
}

sub ped {
  my $key = shift;
  my $hshref = shift;
  for my $item ($hshref){
    my ($p1, $p2);
    if ($HoA{$key}){
      $p1 = $item->{$key}->[0];
      $p2 = $item->{$key}->[1];
      if ( defined($p1) && defined($p2) ){
        if ($format =~ /table/){ print_table_row($QUERY_IND, $key, $p1, $p2) }
        $ped_str =~ s/ $key / $key < $p1 , $p2 > /g;
        ped($p1, $hshref);
        ped($p2, $hshref);
      }
      elsif ( defined($p1) && !defined($p2) ){
        if ($format =~ /table/){ print_table_row($QUERY_IND, $key, $p1, "-") }
        $ped_str =~ s/ $key / $key < $p1 > /g;
        ped($p1, $hshref);
      }
      elsif ( !defined($p1) && defined($p2) ){
        if ($format =~ /table/){ print_table_row($QUERY_IND, $key, "-", $p2) }
        $ped_str =~ s/ $key / $key < $p2 > /g;
        ped($p2, $hshref);
      }
    }
    else { # Individual is without a parent, so return
      if ($format =~ /table/){ print_table_row($QUERY_IND, $key, "-", "-") }
      return 0;
    }
  }
}

sub print_ped_string {
  my $ped_str = shift;
  if ($noself){ # If set, remove query ID prior to printing
    $ped_str =~ s/^(\S+:) < \S+ (<.+ >) >$/$1 $2/;
  }
  $ped_str =~ s/</(/g; $ped_str =~ s/>/)/g; 
  $ped_str =~ s/\[([^]]+)\]:/$1:/;
  say "$ped_str";
}

sub print_table_row {
  my $st_ind = shift; my $key = shift; my $p1 = shift; my $p2 = shift;
  unless ($p1 eq "-" && $p2 eq "-"){
    if ($noself){ # Don't print line that contains the individual and its parents
      if ($key eq $QUERY_IND){
        return;
      }
      else {
        say join("\t", $key, $p1, $p2);
      }
    }
    else {
      say join("\t", $key, $p1, $p2);
    }
  }
}

__END__

Versions
2023-11-06 Initial version
2023-11-07 Report starting individual in first column of table output
2023-11-08 Add flag -noself to remove the starting ID from the parentage string.
2024-05-17 Change -start to -query. 
           Change table output format, removing query from first column.
           Add header for Helium: Genotype  Female Parent  Male Parent
