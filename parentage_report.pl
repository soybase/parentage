#!/usr/bin/env perl

# Program: parentage_report.pl
# Program description: see usage message.
# Steven Cannon 2024

use feature say; 
use warnings; 
use strict; 
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin";

my ($parents, $synonyms, $comments, $query, $verbose, $help);
my $format = "string";
my $line_ct = 0;
my $max_ped_size = 999;

my $usage = <<EOS;
  Usage:  parentage_report.pl -parents FILE -synonyms FILE -comments FILE -query ID [-options]
  Example: 
    parentage_report.pl -par parentage.tsv \\
                        -syn parentage-synonyms.tsv \\
                        -com parentage-comments.tsv \\
                        -query "Fiskeby III"

  Given the requried input data, generate a report about an individual, including the pedigree, 
  any aliases/synonyms for the line, the lines which have the individual in their pedigree, 
  and any available comments about the individual.

  Some other lines to try, to check various characteristics of the data:
    Hardin, Hayes, Hamlin, Gnome, Franklin, Flyer, Flambeau, Williams, "Williams 82", Lee

  Required:
    -parents    File with three columns: individuals and parents individuals and the parents;
    -synonyms   File with two columns: individual and synonym (if multiple synonyms, one line for each);
    -comments   File with two columns: individual and comments
    -query      ID of an individual for which to generate a report

  Options:
    -max_ped_size  The maximum number of individuals in the pedigree to report.
    -verbose  Report some intermediate information.
    -help     This message.
EOS

GetOptions(
  'parents=s'      => \$parents,  # required
  'synonyms=s'     => \$synonyms,  # required
  'comments=s'     => \$comments,  # required
  'query=s'        => \$query, # required
  'max_ped_size:i' => \$max_ped_size,
  'v|verbose'      => \$verbose,
  'h|help'         => \$help,
);

die $usage if ($help || !defined($parents) || !defined($synonyms) || !defined($comments) || !defined($query) );

open (my $PAR_FH, "<", $parents) or die "Can't open in parents: $parents $!\n";
open (my $SYN_FH, "<", $synonyms) or die "Can't open in synonyms: $synonyms $!\n";
open (my $COM_FH, "<", $comments) or die "Can't open in comments: $comments$!\n";

my %PAR_HSH;
while (<$PAR_FH>){
  chomp;
  my $line = $_;
  next if (/^#/ || /^Strain/);
  my @parts = split(/\t+/, $_);
  my ($ind, $p1, $p2) = ($parts[0], $parts[1], $parts[2]);
  $PAR_HSH{ $ind }++;
}

# Use parentage.pl to calculate lists of strains in the pedigree of each individual 
# The serialized structure is a hash of arrays, with the hash key being the individual and the strains being the array values:
# { indivd [strain1 strain2 strain3] }
#https://stackoverflow.com/questions/62283469/return-array-value-from-one-perl-script-to-another-perl-script
my %PED_HSH;
my @matches;
my @args1 = ( "-parents", "$parents", "-format", "list" );
#say "perl $Bin/parentage.pl @args1";
my $serialized_result1 = `perl "$Bin/parentage.pl" @args1`;
my @ped_ary = split(/\n/, $serialized_result1);
for my $ped_line (@ped_ary){
  my ($ind, @ped_list) = split(/\t/, $ped_line);
  $PED_HSH{ $ind } = [ @ped_list ];
  if ( grep { $query eq $_ } @ped_list ){
    push @matches, $ind;
  }
}

my @alt_names;
while (<$SYN_FH>){
  chomp;
  my $line = $_;
  my ($ind, $alt) = split(/\t+/, $_);
  if ($query eq $ind){ push @alt_names, $alt } 
}

my @q_comments;
while (<$COM_FH>){
  chomp;
  my $line = $_;
  my ($ind, $comment) = split(/\t+/, $_);
  if ($query eq $ind){ push @q_comments, $comment } 
}

# Print report for the provided $query

# Generate parentage result for the given query
my @args2 = ( "-parents", "$parents", "-query", "$query", "-max", "$max_ped_size" );
# say "perl $Bin/parentage.pl @args2";
my $serialized_result2 = `perl "$Bin/parentage.pl" @args2`;
say "Pedigree of $query (showing first the immediate parents, then progressively earlier crosses):";
say $serialized_result2;

if (@matches){
  say "$query is in the pedigree of these lines: ", join(", ", @matches), "\n";
}
if ( @alt_names ){
  say "Alternate names for $query: ", join(", ", @alt_names), "\n";
}
if ( @q_comments ){
  say "Comments for $query: ", join(", ", @q_comments), "\n";
}


__END__

Versions
2024-11-01 Initial version
2024-11-03 Calculate pedigrees from parentage table using parentage.pl, rather than take in as a precalculated file



