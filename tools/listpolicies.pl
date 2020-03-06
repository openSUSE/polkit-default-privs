#!/usr/bin/perl -w
# either list policies in a polkit file or list policies in polkit files that
# are not contained in polkit-default-privs files. For the latter mode first
# specify the polkit files on the command line and then separated with double
# dash "--" the polkit-default-privs files.
#
# calling without arguments will check all policy files in
# $RPM_BUILD_ROOT and compare against standard set

use strict;
use XML::Bare;
use Data::Dump;
use Getopt::Long;
Getopt::Long::Configure("no_ignore_case");

my %options;

sub usage($) {
	my $r = shift;
	eval "use Pod::Usage; pod2usage($r);";
	if ($@) {
		die "cannot display help, install perl(Pod::Usage)\n";
	}
}

GetOptions(
	\%options,
	"verbose|v",
	"policy=s@",
	"check-override:s",
	"all",
	"help|h",
) or usage(1);

usage(0) if ($options{'help'});
die "check-override must be active/local/any\n" if ($options{'check-override'} && $options{'check-override'} !~ /active|local|any/);

my %known;
my @policies;

if ($#ARGV == -1) {
	my $buildroot = $ENV{'BUILD_ROOT'} || '';
	my $rpm_buildroot = $ENV{'RPM_BUILD_ROOT'} || '';
	push @ARGV, glob "$rpm_buildroot/usr/share/polkit-1/actions/*.policy";
	unless ($options{'policy'}) {
		$options{'policy'} = [ "$buildroot/usr/share/polkit-default-privs/profiles/standard" ];
	}
}

for my $f (@ARGV) {
	open (F, '<', $f) or die "$f: $!";
	#print STDERR "+++ ", $f,"\n";
	my $xml = XML::Bare->new(text => join('', <F>))->parse();

	die "file is not a policykit config file" unless exists $xml->{'policyconfig'}->{'action'};

	my $a;
	if (ref $xml->{'policyconfig'}->{'action'} eq 'ARRAY') {
		$a = $xml->{'policyconfig'}->{'action'}
	} else {
		$a = [$xml->{'policyconfig'}->{'action'}];
	}
	for (@{$a}) {
		next unless exists $_->{'id'}->{"value"};
		my $p = { name => $_->{'id'}->{'value'} };
		my $v = ();
		for my $n (qw/any inactive active/) {
			my $ref = $_->{'defaults'}->{'allow_'.$n};
			if (ref $ref eq 'ARRAY') {
				warn $p->{'name'}.": duplicate allow_$n\n";
				$ref = $ref->[-1];
			}
			push @$v, $ref->{'value'} || 'no';
		}
		$p->{'value'} = $v;
		push @policies, $p;
	}
}

for my $f (@{$options{'policy'}}) {
	open (F, '<', $f) or die "$f: $!";
	while(<F>) {
		chomp;
		next unless $_;
		next if(/^#/);
		my ($privilege, $perms) = split(/\s+/);
		my @p = map { s/^(auth_(?:admin|self)_keep).+$/$1/; s/_one_shot//; $_ } split(/:/, $perms);
		if (@p != 3) {
			@p = ($p[0], $p[0], $p[0]);
		}
		$known{$privilege} = [ @p ];
	}
	close F;
}

if (!$options{'policy'}) {
	map { print $_->{'name'}, "\n" } @policies;
} elsif ($options{'check-override'}) {
	my $what = 2;
	$what = 1 if $options{'check-override'} eq 'local';
	$what = 0 if $options{'check-override'} eq 'any';
	for my $p (@policies) {
		next unless exists $known{$p->{'name'}};
		next if $known{$p->{'name'}}->[$what] eq $p->{'value'}->[$what];
		print sprintf('%-63s %s -> %s'."\n", $p->{'name'}, $p->{'value'}->[$what], $known{$p->{'name'}}->[$what]);
	}
} else {
	my $have_unknown;
	for (@policies) {
		next unless $options{'all'} or ! exists $known{$_->{'name'}};
		print sprintf('%-63s %s'."\n", $_->{'name'}, join(':', @{$_->{'value'}}));
		$have_unknown = 1;
	}
	if ($options{'verbose'}) {
		my %seen = map { $_->{'name'} => 1} @policies;
		my @obs;
		for (keys %known) {
			push @obs, $_ unless $seen{$_};
		}
		for (sort @obs) {
			print "obsolete entry $_\n";
		}
	}
	exit (1) if($have_unknown);
}
