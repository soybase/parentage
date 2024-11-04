#!/usr/bin/env perl

# Program: parentage.pl
# Program description: see usage message.
# Steven Cannon 2023

use feature say; 
use warnings; 
use strict; 
use Getopt::Long;

my ($parents, $query, $last_only, $verbose, $help);
my $format = "string";
my $line_ct = 0;
my $max_ped_size = 999;

my $usage = <<EOS;
  Usage:  parentage.pl -parents FILE [-options]

  Given a file of individuals and parents, recursively determine the pedigree
  (the parentage going back as many generations as possible) for an individual.
  Can be calculated for a single indicated individual or for all in the parents file.

  The parents file should be structured like this.
  The individual (progeny) is on the left, and the parents are on the right
    indID  parent1  parent2
    A      B        C
    D      B        C
    E      B        F

  Required:
    -parents  File listing the individuals and parents

  Options:
    -query    ID of an individual for which to calculate parentage.
              If not provided, report parentage for all individuals.
    -format   Output format. Options: string, table0, table1, list
                string: pedigree string, in parenthetical tree format. Printed at increasing depth unless -last_only
                table0: query parent1 parent2   With header line but no other information
                table1: query parent1 parent2   With termination information and final pedigree string
                list:   individual and all parents throughout the pedigree, comma-separated (no parentheses)
    -last_only     For string format, print only the last pedigree string; otherwise, print one for each data line.
    -max_ped_size  The maximum number of individuals in the pedigree to report.
                        When this number is reached, the pedigree of that size will be reported,
                        even if other parents may be found in the input data.
    -verbose  Report some intermediate information.
    -help     This message.
EOS

GetOptions(
  'parents=s'      => \$parents,  # required
  'query:s'        => \$query,
  'format:s'       => \$format,
  'last_only'      => \$last_only,
  'max_ped_size:i' => \$max_ped_size,
  'v|verbose'      => \$verbose,
  'h|help'         => \$help,
);

die $usage if ($help || !defined($parents));

unless ($format =~ /table0|table1|string|list/){
  die "The -format option must be one of [string, table0, table1, list]. Default is string.\n";
}

open (my $P_FH, "<", $parents) or die "Can't open in parents: $parents $!\n";

my $ped_str;
my %HoA;
my $QUERY_IND; # global; there are also local instances: $ind (individual)
while (<$P_FH>){
  chomp;
  my $line = $_;
  next if (/^#/ || /^Strain/);
  my @parts = split(/\t+/, $_);
  #if (scalar(@parts) < 3){die "Unexpected line with fewer than three elements: $_\n" }
  my ($ind, $p1, $p2) = ($parts[0], $parts[1], $parts[2]);
  if (!defined($p1) || !defined($p2)){
    if ($query && $query eq $ind){
      say "!! Skipping parentage report for $query because one or both parents are missing.";
    }
    next;
  }
  # Replace separator " x " with " , "
  $p1 =~ s/ x / , /g;
  $p2 =~ s/ x / , /g;
  # Replace parens with angles in $p1 and $p2, for cases where the parent is compound
  $p1 =~ s/\(/</g;
  $p1 =~ s/\)/>/g;
  $p2 =~ s/\(/</g;
  $p2 =~ s/\)/>/g;
  $HoA{ $ind } = [ $p1, $p2 ];
  if ($verbose){say "$ind, $p1, $p2"};
}
if ($verbose){say ""};

my $size_terminate;
my $cycle;
my $count_processed;
my ($cycle_string1, $cycle_string2);
my %SEEN_IND; # global, to store seen individuals (children), to help check for cycles
my $pedigree_size;
foreach my $key (sort keys %HoA) {
  if ($query){ next unless $key eq $query }
  %SEEN_IND = ();
  $count_processed++;
  my $value = $HoA{$key};
  $pedigree_size = 0;
  unless ($query || $format =~ /list/){ # If query string, there's only one report, so no reason to give a count
    say "## $count_processed ##";
  }
  # Print header
  if ($format =~ /table1/){ say "Query\tGenotype\tFemaleParent\tMaleParent" }
  elsif ($format =~ /table0/){ say "Genotype\tFemaleParent\tMaleParent" }
  my ($ind, $p1, $p2) = ($key, $value->[0], $value->[1]);
  $QUERY_IND = $ind;

  # Build the initial pedigree string, consisting of the individual and its two parents# 
  $ped_str = "[$ind]: < $ind > ";      
  if ($HoA{$ind}){
    my $p1 = ${HoA{$key}}->[0];
    my $p2 = ${HoA{$key}}->[1];
    $ped_str =~ s/ < $key > / < $p1 , $p2 > /g;
  }
  $SEEN_IND{$ind}++;
  $size_terminate = 0;
  $cycle = 0;
  ped($ind, \%HoA);
  
  if ($size_terminate == 1){
    unless ($format =~ /table0|list/){
      say "!! Terminating search because number of individuals is greater than max_ped_size $max_ped_size";
    }
  }
  if ($cycle == 1){
    if ($size_terminate == 0){ # Don't bother reporting cycle if terminating because we've hit $max_ped_size
      unless ($format =~ /table0|list/){
        say "!! Terminating search because of cycle.";
        if ($cycle_string1){say $cycle_string1 }
        if ($cycle_string2){say $cycle_string2 }
      }
    }
  }
  # At end of table, also print pedigree string, if -format table1
  if ($format =~ /table1/){ print_ped_string($ped_str) }
  if ($format =~ /string/ && $last_only){ print_ped_string($ped_str) }
  if ($format =~ /list/){print_list($ped_str) }
  if ($query && $format !~ /list/){ say "" } # print separator if more than just the query are being processed
}

sub ped {
  my $key = shift;
  my $hshref = shift;
  if ($HoA{$key}){
    my $p1 = $hshref->{$key}->[0];
    my $p2 = $hshref->{$key}->[1];

    # Check for cycles 
    $SEEN_IND{$key}++;
    if ($SEEN_IND{$p1}){
      $cycle_string1 = "!! In parents ($p1, $p2), $p1 was also seen as a child";
      $cycle = 1;
      return 0;
    }
    if ($SEEN_IND{$p2}){
      $cycle_string2 = "!! In parents ($p1, $p2), $p2 was also seen as a child";
      $cycle = 1;
      return 0;
    }

    # Print table row if -format table
    if ($format =~ /table/){ print_table_row($QUERY_IND, $key, $p1, $p2) }
    $ped_str =~ s/ $key / < $p1 , $p2 > /g;

    # Check if individuals is greater than -max_ped_size
    my $pedigree_size = count_individuals($ped_str);
    if ( $pedigree_size > $max_ped_size ){
      $size_terminate = 1;
      return 0;
    }

    # Print pedigree string if -format string
    if ($format =~ /string/ && not $last_only){ print_ped_string($ped_str) }

    # The recursion
    ped($p1, $hshref);
    ped($p2, $hshref);
  }
  else { # Individual is without a parent, so return
    return 0;
  }
}

sub print_ped_string {
  $ped_str = shift;
  #say "[$ped_str]";
  $ped_str =~ s/</(/g; 
  $ped_str =~ s/>/)/g; 
  #$ped_str =~ s/ , / X /g; 
  $ped_str =~ s/\[([^]]+)\]:\s+/$1 ==\t/;
  say "$ped_str";
}

sub print_list {
  $ped_str = shift;
  $ped_str =~ s/\[([^]]+)\]:/$1/;
  my (@parts, @parent_A);
  $ped_str =~ s/[<,>]/\n/g;
  $ped_str =~ s/^ +| +$//g;
  my $count_indiv = 0;
  @parts = split "\n", $ped_str;
  foreach my $line (@parts){
    $line =~ s/^ +| +$//g;
    $line =~ s/,//;
    if (length($line)) {
      push @parent_A, $line;
    }
  }
  say join("\t", @parent_A);
}

sub count_individuals {
  $ped_str = shift;
  my $count_indiv= 0;
  my $parent_list = $ped_str;
  $parent_list =~ s/< /\n/g;
  $parent_list =~ s/ >/\n/g;
  $parent_list =~ s/ , /\n/g;
  my @parents = split "\n", $parent_list;
  foreach my $line (@parents){
    if (length($line)) {
      $count_indiv++;
    }
  }
  return $count_indiv;
}

sub print_table_row {
  my $st_ind = shift; my $key = shift; my $p1 = shift; my $p2 = shift;
  if ($format =~ /table1/){
    say join("\t", "$st_ind ::", $key, $p1, $p2);
  }
  elsif ($format =~ /table0/){
    say join("\t", $key, $p1, $p2);
  }
}

__END__

Versions
2023-11-06 Initial version
2023-11-07 Report querying individual in first column of table output
2023-11-08 Add flag -noself to remove the querying ID from the parentage string.
2024-05-17 Change -start to -query. 
           Change table output format, removing query from first column.
           Add header for Helium: Genotype  Female Parent  Male Parent
2024-10-21 Report search pedigree_size
2024-10-30 Many changes. Initialize start of recursion differently. Remove noself flag and add last_only.
2024-11-01 Add format options table0 table1 list
