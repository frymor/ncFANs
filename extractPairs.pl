#!/usr/bin/perl

=head1 NAME

extractPairs.pl - extract both coexpression and colocation gene pairs.

=head1 SYNOPSIS

Use:

    perl extractPairs.pl   -n <netwrok.txt> -l <co-location.txt> 

Examples:

    perl extractPairs.pl --help

    perl extractPairs.pl -n network.txt -l co-location.txt


=head1 DESCRIPTION

This script is part of the ncFANs pipeline. It takes colocation gene
pairs (generated by find_neighbor.py) and network files (generated by 
cnc.pl) as inputs and prints both coexpression and colocation gene pairs 
to output file.

=head1 ARGUMENTS

extractPairs.pl takes the following arguments:

=over 4

=item network

  -n <network.txt>
 
(Required.) The path of network file. More than one path separated by 
commas can be provied . Network files should be generated by cnc.pl.

=item colocation gene pairs
  
  -l <colocation.txt>

(Required.) The path of colocation gene pairs file.

=item output file
   
  -o <output.txt>

(Required.) The path of output file.

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

my ($netpath, $locpath, $output, $help);

GetOptions(
    'n=s' => \$netpath,
    'l=s' => \$locpath,
    'o=s' => \$output,
    'help'   => \$help);

#   Check for requests for help or for man (full documentation):

pod2usage(-verbose => 1) if ($help);

#   Check for required variables.

unless (defined($netpath) && defined($locpath) &&defined($output))
{
    pod2usage(-exitstatus => 2);
}

my %network;
my @tmp;
my @path = split /,/, $netpath;
print "Reading network files ...\n";
foreach $netpath (@path) {
    open FH, $netpath or die;
    while (<FH>) {
        chomp;
        if (grep("_[kn]n\t?", $_)) {
            @tmp = split /\t/, $_;
            map {s/_(c|[kn]n)$//} @tmp[0..1];
            $network{join("\t", @tmp[0..1])} = 1;
        } else {
            next;
        }
    }
    close FH;
}

open FH, $locpath or die;
open OUT, ">$output" or die;
print "Finding gene pairs ...\n";
while (<FH>) {
    chomp;
    @tmp = split /\t/, $_;
    map {s/_(c|[kn]n)$//} @tmp[0..1];
    if (exists($network{join("\t", @tmp[0..1])})) {
        print OUT $tmp[0], "\t", $tmp[1], "\n";
    } elsif (exists($network{"$tmp[1]\t$tmp[0]"})) {
        print OUT $tmp[1], "\t", $tmp[0], "\n";
    }
}
print "Done!\n";
close FH;
