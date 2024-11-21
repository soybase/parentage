#!/usr/bin/env perl

# Program: parentage.pl
# Program description: see usage message.
# Steven Cannon 2023

use feature say; 
use warnings; 
use strict; 
use Getopt::Long;

my ($parents, $query, $outfile, $last_only, $verbose, $help);
my $format = "string";
my $line_ct = 0;
my $max_count = 999;
my $outdir = ".";

my $usage = <<EOS;
  Usage:  parentage.pl -parents FILE [-options]

  Examples:
  To generate a file of the parents throughout the pedigree for each individual:
    parentage.pl -parents data/parentage.tsv -outfile data/parentage-list.tsv -format list 
  To report the parentage for a given query, built up from the immediate parents through successive genrations:
    parentage.pl -parents data/parentage.tsv -q Hardin
  To report the parentage for a given query, in a tabular format suitable for viewing with https://helium.hutton.ac.uk
    parentage.pl -parents data/parentage.tsv -q Hardin -format table0 -outfile QUERY

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
    -outfile  Print to indicated filename; otherwise to STDOUT. 
              If -outfile "QUERY" is indicated, the query name will be used (with spaces replaced by underscores).
    -outdir   If outfile is specified, write files to this directory. Default "."
    -format   Output format. Options: string, table0, table1, list
                string: pedigree string, in parenthetical tree format. Printed at increasing depth unless -last_only
                table0: query parent1 parent2   With header line but no other information
                table1: query parent1 parent2   With termination information and final pedigree string
                list:   individual and all parents throughout the pedigree, comma-separated (no parentheses)
    -last_only     For string format, print only the last pedigree string; otherwise, print one for each data line.
    -max_count  The maximum number of individuals in the pedigree to report.
                        When this number is reached, the pedigree of that size will be reported,
                        even if other parents may be found in the input data.
    -verbose  Report some intermediate information.
    -help     This message.
EOS

GetOptions(
  'parents=s'   => \$parents,  # required
  'query:s'     => \$query,
  'outfile:s'   => \$outfile,
  'outdir:s'    => \$outdir,
  'format:s'    => \$format,
  'last_only'   => \$last_only,
  'max_count:i' => \$max_count,
  'v|verbose'   => \$verbose,
  'h|help'      => \$help,
);

die $usage if ($help || !defined($parents));

unless ($format =~ /table0|table1|string|list/){
  die "The -format option must be one of [string, table0, table1, list]. Default is string.\n";
}

open (my $PAR_FH, "<", $parents) or die "Can't open in parents: $parents $!\n";

my $OUT_FH;
if ($outfile) { 
  if ($outfile eq "QUERY"){
    $outfile = $query;
    $outfile =~ s/ /_/g;
    $outfile =~ s/^(.+)$/$1.txt/g;
  }
  else {
    # $outfile was specified by user and is different than "QUERY"
  }
  say "OUTFILE: $outdir/$outfile";
  open ($OUT_FH, ">", "$outdir/$outfile") or die "\nUnable to open output file for writing: $!\n\n"; 
}

my $ped_str;
my %HoA;
my $QUERY_IND; # global; there are also local instances: $ind (individual)
while (<$PAR_FH>){
  chomp;
  next if (/^#/ || /^Strain/);
  my $line = $_;
  # Replace separator " x " with " , "
  $line =~ s/ x / , /g;
  # Replace parens with angles, for cases where the parent is compound. To make subsequent regexes easier to read.
  $line =~ s/\(/</g;
  $line =~ s/\)/>/g;
  my ($ind, $p1, $p2) = split(/\t+/, $line);
  if (!defined($p1) || !defined($p2)){
    if ($query && $query eq $ind){
      printstr("!! Skipping parentage report for $query because one or both parents are missing.");
    }
    next;
  }
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
  unless ($query || $format =~ /list/ || $format =~ /table/){ # If query string, no reason to give a count
    printstr("## $count_processed ##");
  }
  # Print header
  if ($format =~ /table1/){ printstr("Query\tGenotype\tFemaleParent\tMaleParent") }
  elsif ($format =~ /table0/){ printstr("Genotype\tFemaleParent\tMaleParent") }
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
      printstr("!! Terminating search because number of individuals is greater than max_count $max_count");
    }
  }
  if ($cycle == 1){
    if ($size_terminate == 0){ # Don't bother reporting cycle if terminating because we've hit $max_count
      unless ($format =~ /table0|list/){
        my $details = "";
        if ($cycle_string1){$details .= "$cycle_string1\n" }
        if ($cycle_string2){$details .= "$cycle_string2\n" }
        printstr("!! Terminating search because of cycle.\n$details");
      }
    }
  }
  # At end of table, also print pedigree string, if -format table1
  if ($format =~ /table1/){ print_ped_string($ped_str) }
  if ($format =~ /string/ && $last_only){ print_ped_string($ped_str) }
  if ($format =~ /list/){print_list($ped_str) }
  # print separator if more than just the query are being processed
  if (!$query && $format !~ /list/){ printstr("\n") }
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

    # Check if individuals is greater than -max_count
    my $pedigree_size = ($ped_str =~ tr/:,//) + 1;
    if ( $pedigree_size > $max_count ){
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
  $ped_str =~ s/</(/g; 
  $ped_str =~ s/>/)/g; 
  #$ped_str =~ s/ , / X /g; 
  $ped_str =~ s/\[([^]]+)\]:\s+//; # Strip query prior to pedigree string
  $ped_str =~ s/^ +//; # Strip leading spaces
  $ped_str =~ s/ +$//; # Strip trailing spaces
  printstr("$ped_str");
}

sub print_list {
  $ped_str = shift;
  $ped_str =~ s/\[([^]]+)\]:/$1/;

  my $parent_A = join("\t", map { s/^ +| +$//g; $_ }
                            grep { /[^[:space:]]/ }
                            split /[<,>]/, $ped_str);
  printstr($parent_A);
}

sub print_table_row {
  my $st_ind = shift; my $key = shift; my $p1 = shift; my $p2 = shift;
  $p1 =~ s/</(/g;
  $p1 =~ s/>/)/g;
  #$p1 =~ s/,/X/g;
  $p2 =~ s/</(/g;
  $p2 =~ s/>/)/g;
  #$p2 =~ s/,/X/g;
  if ($format =~ /table1/){
    printstr(join("\t", "$st_ind ::", $key, $p1, $p2));
  }
  elsif ($format =~ /table0/){
    printstr(join("\t", $key, $p1, $p2));
  }
}

# Print to outfile or to stdout
sub printstr {
  my $str_to_print = join("", @_);
  if ($outfile) {
    print $OUT_FH "$str_to_print\n";
  }
  else {
    print "$str_to_print\n";
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
2024-11-04 Add option to print to specified file, with sub printstr
2024-11-08 Code optimizations (nweeks); faster counting, and removal of sub count_individuals
2024-11-19 Minor code cleanup
