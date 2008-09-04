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
use Data::Dumper;

my $permissions;
my %known;
my @policies;

if ($#ARGV == -1) {
	my $buildroot = $ENV{'RPM_BUILD_ROOT'} || '';
	@ARGV = glob "$buildroot/usr/share/PolicyKit/policy/*.policy";
	push @ARGV, '--';
	push @ARGV, '/etc/polkit-default-privs.standard';
}

for my $f (@ARGV) {
	if ("$f" eq '--') {
		$permissions = 1;
		next;
	}
	open (F, '<', $f) or die "$f: $!";
	if(!$permissions) {
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
			my $s = $_->{'defaults'}->{'allow_any'}->{'value'} || 'no';
			$s .= ':'.($_->{'defaults'}->{'allow_inactive'}->{'value'} || 'no');
			$s .= ':'.($_->{'defaults'}->{'allow_active'}->{'value'} || 'no');
			$p->{'value'} = $s;
			push @policies, $p;
		}
	} else {
		while(<F>) {
			chomp;
			next unless $_;
			next if(/^#/);
			my ($privilege, $perms) = split(/\s+/);
			$known{$privilege} = 1;
		}
	}
	close F;
}

if(!$permissions) {
	map { print $_->{'name'}, "\n" } @policies;
} else {
	my $have_unknown;
	for (@policies) {
		next if exists $known{$_->{'name'}};
		print sprintf('%-63s %s'."\n", $_->{'name'}, $_->{'value'});
		$have_unknown = 1;
	}
	exit (1) if($have_unknown);
}
