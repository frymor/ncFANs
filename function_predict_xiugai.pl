#!/usr/bin/perl

=head1 NAME

function_predict.pl - Enrich function for lincRNA genes in cnc-network

=head1 SYNOPSIS

Use:

    perl function_predict.pl [options] -n <netwrok.txt> -o <out_dir> 
                           -g2go <gene2go> 

Examples:

    perl function_predict.pl --help

    perl function_predict.pl -n network.txt -o tmp -g2go gene2go


=head1 DESCRIPTION

This script is part of the ncFANs pipeline. The script uses coding-noncoding
coexpression network and GO annotation to enrich functions for lincRNA genes.

=head1 ARGUMENTS

function_predict.pl takes the following arguments:

=over 4

=item network

  -n <network.txt>
 
(Required.) The path of network file. Network files should be generated by
cnc.pl

=item out_dir
  
  -o <out_dir>

(Required.) The directory for results.

=item gene2go

  -g2go 

(Required.) The path of gene2go file.

=item GO namespace

  -bp -mf -cc

(Optional.) GO namespace for module-based or hub-based method. At least one 
must be selected, if module-based or hub-based method is used.

=item GO namespace for global method. 

  -go 

(Optional.) GO namespace for global, p stands for biological process, m for
molecular function, c for celleur component. The default is 'p';

=item module genes cutoff

  -m

(Optional.) The minimum number of genes in a module-based subnetwork.
If this optoin was selected, module-based method for function enrichment should
be used. The default is 30.

=item module coding genes cutoff

  -mc 

(Optional.) The minimum number of coding genes in a module-based subnetwork.
If this optoin was selected, module-based method for function enrichment should
be used. The default is 10.

=item percentage of total network edges

  -mp

(Optional.) (# Edges of module / # edges of network) > perecnatege, the module
will be deprecated. The default if 0.1(10%).
=item hub genes cutoff

=item hub coding genes cutoff

  -hc

(Optional.) The minimum number of coding genes in a hub-based subnetwork.
If this optoin was selected, module-based method for function enrichment should
be used. The default is 10.

=item p-value

  -p

(Optional.) P-value of function enrichment significance. Only when option m or hc
was selected, this option would be effective. The default is 0.01.

=item global method

  -g

(Optional.) Global method will be used.

=item alpha

  --alpha

(Optional.) alpha weights the relative importance of the global and local 
constraints. Default is 0.618.

=item delta
  
  --delta

(Optional.) a node degree treshold in the computation of previous function a
nnotation imposed by local constraint. Default is 5. 

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
use File::Copy;
use File::Path;
use POSIX;

#   Check arguments.

my ( $network, $dir, $g2go, $module, $mc, $mp, $hc, $p_value, $global, $help);
my ($bp, $mf, $cc) = (0, 0, 0); 
my ($go, $alpha, $delta);
    

GetOptions(
    'n=s'       => \$network,
    'o=s'       => \$dir,
    'g2go=s'    => \$g2go,
    'bp'        => \$bp,
    'mf'        => \$mf,
    'cc'        => \$cc,
    'go=s'      => \$go,
    'm:i'       => \$module,
    'mc:i'      => \$mc,
    'mp:i'      => \$mp,
    'hc:i'      => \$hc,
    'p=f'       => \$p_value,
    'g'         => \$global,
    'alpha=f'     => \$alpha,
    'delta=i'     => \$delta,
    'help'      => \$help);

#   Check for requests for help or for man (full documentation):

pod2usage(-verbose => 1) if ($help);

#   Check for required variables.

unless (defined($network) && defined($dir) && defined($g2go))
{
    pod2usage(-exitstatus => 2);
}

#   Check for optional variables.

#   Option m
if (defined($module)) {
    if ($module < 0 ) {
        my $message = "Vaule \"$module\" invalid for optiom m. (number > 0 expected)\n";
        pod2usage(-msg     => $message,
                  -exitval => 2);
    } elsif ($module == 0) {
        $module = 30;
    }
} else {
    $module = 0;
}

#   Option mc
if (defined($mc)) {
    if ($mc < 0 ) {
        my $message = "Vaule \"$mc\" invalid for optiom mc. (number > 0 expected)\n";
        pod2usage(-msg     => $message,
                  -exitval => 2);
    } elsif ($mc == 0) {
        $mc = 10;
    }
} else {
    $mc = 10;
}

#   Option mp
if (defined($mp)) {
    if ($mp < 0 || $mp > 1) {
        my $message = "Vaule \"$mp\" invalid for optiom mp. (number in [0, 1] expected)\n";
        pod2usage(-msg     => $message,
                  -exitval => 2);
    }
} else {
    $mp = 0.1;
}

#   Option hc
if (defined($hc)) {
    if ($hc < 0) {
        my $message = "Vaule \"$hc\" invalid for optiom hc. (number > 0 expected)\n";
        pod2usage(-msg     => $message,
                  -exitval => 2);
    } elsif ($hc == 0) {
        $hc = 10;
    }
} else {
    $hc = 0;
} 


if ($module > 0  || $hc > 0) {
    unless ($bp == 1 || $mf == 1 || $cc == 1) {
        pod2usage(-msg    => "If -m or -hc was selected, one of -bp, -mf or -cc
                              must be choosed.",
                  -exitval => 2);
    }
}

#   Option p
if  (defined($p_value)) {
    if ($p_value <= 0 || $p_value > 1) {
        my $message = "Vaule \"$p_value\" invalid for optiom p. (number (0, 1] expected)\n";
        pod2usage(-msg     => $message,
                  -exitval => 2);
    }
} else {
    $p_value = 0.01;
}

$dir =~ s/\/$//;
#print $dir, "\n";

if (defined($global)) {
    if (defined($go)) {
        unless ($go eq "p" || $go eq "m" || $go eq "c") {
            pod2usage(-msg     => "Value for option go must be one of 'p', 'm' or 'c'.",
                      -exitval => 2);
        } 
    } else {
        $go = "p";
    }
    
    if (defined($alpha)) {
        if ($alpha < 0 || $alpha > 1) {
            my $message = "Vaule \"$alpha\" invalid for optiom alpha. (number [0, 1] expected)\n";
            pod2usage(-msg     => $message,
                      -exitval => 2);
        }
    } else {
        $alpha = 0.618;
    }
    if (defined($delta)) {
        if ($delta <= 0) {
            my $message = "Vaule \"$delta\" invalid for optiom delta. (positive integer expected)\n";
            pod2usage(-msg     => $message,
                      -exitval => 2);
        }
    } else {
        $delta= 5;
    }
}

#   module-based method
if ($module > 0) {
    if (-e $network) {
        unless (-d $dir) {
            mkdir $dir or die $!;
        }
        print "Running mcl...\n";
        system("mcl $network --abc -o $dir/module");
        system("perl pls/mcl.pl $network $dir $module $mc $mp");
        print "Finish clustering module.\n";
    } else {
        print STDERR "file $network is not exist!\n";
    }
}

# hub-based method
if ($hc > 0) {
    if (-e $network) {
        unless (-d $dir) {
            mkdir $dir or die $!;
        }
        print "Finding hubs...\n";
        system("perl pls/hub.pl $network $dir $hc");
        print "Finish finding hubs.\n";
    } else {
        print STDERR "file $network is not exist!\n";
    }
}

if ($module > 0 || $hc > 0) {
    if (-e $g2go) {
        mkdir $dir unless (-d $dir);
        mkdir "$dir/GO" unless (-d "$dir/GO");
        print "Parsing gene2go file...\n";
        system("perl pls/formatgo.pl $g2go $dir/GO");
        print "Finish parsing gene2go file.\n";
    } else {
        print STDERR "File $g2go is not existing.\n";
        exit;
    }
    my $args = "$dir $bp $mf $cc $module $mc $hc $p_value";
    print "Starting functions enriching...\n";
    system("perl pls/enrich.pl $args");
    print "Functions enrichment is done.\n";

    unlink "$dir/module" if (-e "$dir/module");
    unlink "$dir/module_CEL" if (-e "$dir/module_CEL");
    unlink "$dir/Module_function" if (-e "$dir/Module_function");
    rmtree("$dir/Module_node", 0, 1) if (-d "$dir/Module_node");
    rmtree("$dir/Hub_node", 0, 1) if (-d "$dir/Hub_node");
    if (-d "$dir/Hub_fun_dir") {
        my %files;
        foreach (glob "$dir/Hub_fun_dir/*.txt") {
            my $name = substr($_, rindex($_, "/") + 1);
#            print $name, "\n";
            $name =~ s/\.txt//;
            $files{$name} = 1;
        }
        foreach (glob "$dir/Hub_edge/*n") {
            my $name = substr($_, rindex($_, "/") + 1);
            my $gene = $name;
            $gene =~ s/_[kn]n//;
            if (! exists($files{$gene})) {
                unlink "$dir/Hub_edge/$name";
            }
        }
    }
}

if (defined($global)) {

    if (-e $g2go) {
        mkdir $dir unless (-d $dir);
        mkdir "$dir/gfpData" unless (-d "$dir/gfpData");
        print "Parsing gene2go file...\n";
        system("perl pls/gfpGo.pl $g2go $dir");
        print "Finish parsing gene2go file.\n";
    } else {
        print STDERR "File $g2go is not existing.\n";
        exit;
    }
    if (-e $network) {
        unless (-d $dir) {
            mkdir $dir or die $!;
        } 
        system("perl pls/cor2gfp.pl $dir $network");
        system("./lncGFP2 -d $dir -go $go -w T -p F -alpha $alpha -delta $delta -r 1000");
        system("perl pls/gfpResult.pl $dir");
        unlink "$dir/NcFuncAnno.result", "$dir/coding.list", "$dir/nc.list";
        unlink "$dir/network";
        rmtree("$dir/gfpData", 0, 1);
        
    } else {
        print STDERR "file $network is not exist!\n";
    }
}
exit(0);
