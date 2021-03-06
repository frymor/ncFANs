#!/usr/bin/perl

=head1 NAME

getGeneList.pl - Get coding and lincRNA gene lists.

=head1 SYNOPSIS

Use:

    perl getGeneList.pl   -e edge.txt  -o output/

Examples:

    perl getGeneList.pl --help

    perl getGeneList.pl -e edge.txt -o output/


=head1 DESCRIPTION

This script is part of the ncFANs pipeline. The script gets coding and lincRNA 
gene list for file generated by convert_id.pl

=head1 ARGUMENTS

getGeneList.pl takes the following arguments:

=over 4

=item edge file
  
  -e <edge.txt>

(Required.) The path of edge file genrated by convert_id.pl.

=item output

  -o

(Required.) The path of output directory. <edge_file.c> and <edge_file.nc>
will be generated under the directory.

=item help

  --help

(Optional.) Displays the usage message.

=back

=head1 AUTHOR

Li Ming, E<lt>liming@bioinfo.ac.cnE<gt>.

=head1 COPYRIGHT

This program is distributed under the Artistic License.

=head1 DATE

28-Feb-2014

=cut

use strict;
use warnings;
use Getopt::Long;    #   Resist name-space pollution!
use Pod::Usage;      #   Ditto!

my ($edge, $output, $help);

GetOptions(
    'e=s'    => \$edge,
    'o=s'    => \$output,
    'help' => \$help);
#   Check arguments.


#   Check for requests for help or for man (full documentation):

pod2usage(-verbose => 1) if ($help);

#   Check for required variables.

unless (defined($edge) && defined($output))
{
    pod2usage(-exitstatus => 2);
}

$output =~ s/\/$//;
my $name = substr($edge, rindex($edge, "/") + 1);
my (%code, %noncode);
open FH, $edge or die "Can't open $edge\n";
open C, ">$output/$name.c" or die "Can't open $output/$name.c";
open NC, ">$output/$name.nc" or die "Can't open $output/$name.nc";
while (<FH>) {
    chomp;
    my @tmp = split /\t/, $_;
    if ($tmp[0] =~ m/_[kn]n$/) {
        $tmp[0] =~ s/_[kn]n$//;
        $noncode{$tmp[0]} = 1;
    } else {
        $tmp[0] =~ s/_c$//;
        $code{$tmp[0]} = 1;
    }
    if ($tmp[1] =~ m/_[kn]n$/) {
        $tmp[1] =~ s/_[kn]n$//;
        $noncode{$tmp[1]} = 1;
    } else {
        $tmp[1] =~ s/_c$//;
        $code{$tmp[1]} = 1;
    }
}
foreach (keys %code) {
    print C $_, "\n";
}
foreach (keys %noncode) {
    print NC $_, "\n";
}
close FH;
close C;
close NC;
