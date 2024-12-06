#!/usr/bin/env perl
use IO::Compress::Zip qw(zip);
use Mojolicious::Lite -signatures;

get '/genotypes' => sub ($c) {
  open(my $fh, '<', 'data/parentage.tsv');
  my @genotypes;
  <$fh>; # discard first line
  while (my $line = <$fh>) {
    chomp($line);
    my @fields = map($_ eq '' ? undef : $_, split(/\t/, $line, -1));
    push(@genotypes, \@fields);
  }

  close($fh);
  return $c->render(json => \@genotypes);
};

get '/:query' => sub ($c) {
  my $parentage_report;
  my $query = $c->param('query');
  open(my $pipe, '-|', 'perl', 'parentage_report.pl', '-query', $query);
  $parentage_report = <$pipe>;
  if ($parentage_report eq "")  {
    $c->reply->not_found();
  } else {
    $c->render(text => "$parentage_report", format => 'txt')
  }
};

get '/:query/pedigree.helium.zip' => sub ($c) {
  my $query = $c->param('query');
  my $zipfile;
  open(my $table, '-|', 'perl', 'parentage_report.pl', '-table', '-query', $query);
  zip $table => \$zipfile, Name => 'pedigree.helium';
  $c->res->headers->content_disposition('attachment; filename="pedigree.helium.zip"');
  $c->render(data => "$zipfile", type => 'application/zip') # will be empty if query not found
};

app->start;
