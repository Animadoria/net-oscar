=pod

Net::OSCAR::Buddylist -- tied hash class whose keys are Net::OSCAR::Screennames

OSCAR screennames don't compare like normal scalars; they're case and whitespace-insensitive.
This is a tied hash class that has that behavior for its keys.

=cut

package Net::OSCAR::Buddylist;

$VERSION = '0.62';
$REVISION = '$Revision$';

use strict;
use vars qw($VERSION);

use Carp;
use Net::OSCAR::Screenname;
use Net::OSCAR::OldPerl;

sub new {
	my $pkg = shift;
	$pkg->{nonorm} = 0;
	$pkg->{nonorm} = shift if @_;
	$pkg->TIEHASH(@_);
}

sub setorder {
	my $self = shift;

	# Anything not specified gets shoved at the end
	my @end = grep { my $inbud = $_; not grep { $_ eq $inbud } @_ } @{$self->{ORDERFORM}};

	@{$self->{ORDERFORM}} = @_;
	push @{$self->{ORDERFORM}}, @end;
}

sub TIEHASH {
	my $class = shift;
	my $self = { DATA => {}, ORDERFORM => [], CURRKEY => -1};
	return bless $self, $class;
}

sub FETCH {
	my($self, $key) = @_;
	confess "\$self was undefined!" unless defined($self);
	return undef unless $key;
	$self->{DATA}->{$self->{nonorm} ? $key : normalize($key)};
}

sub STORE {
	my($self, $key, $value) = @_;
	if(exists $self->{DATA}->{$self->{nonorm} ? $key : normalize($key)}) {
		my $foo = 0;
		for(my $i = 0; $i < scalar @{$self->{ORDERFORM}}; $i++) {
			next unless $key eq $self->{ORDERFORM}->[$i];
			$foo = 1;
			$self->{ORDERFORM}->[$i] = $self->{nonorm} ? $key : Net::OSCAR::Screenname->new($key);
			last;
		}
	} else {
		push @{$self->{ORDERFORM}}, $self->{nonorm} ? $key : Net::OSCAR::Screenname->new($key);
	}
	$self->{DATA}->{$self->{nonorm} ? $key : normalize($key)} = $value;
}

sub DELETE {
	my($self, $key) = @_;
	my $retval = delete $self->{DATA}->{$self->{nonorm} ? $key : normalize($key)};
	my $foo = 0;
	for(my $i = 0; $i < scalar @{$self->{ORDERFORM}}; $i++) {
		next unless $key eq $self->{ORDERFORM}->[$i];
		$foo = 1;
		splice(@{$self->{ORDERFORM}}, $i, 1);
		last;
	}
	return $retval;
}

sub CLEAR {
	my $self = shift;
	$self->{DATA} = {};
	$self->{ORDERFORM} = [];
	$self->{CURRKEY} = -1;
	return $self;
}

sub EXISTS {
	my($self, $key) = @_;
	return exists $self->{DATA}->{$self->{nonorm} ? $key : normalize($key)};
}

sub FIRSTKEY {
	$_[0]->{CURRKEY} = -1;
	goto &NEXTKEY;
}

sub NEXTKEY {
	my ($self, $currkey) = @_;
	$currkey = ++$self->{CURRKEY};

	if($currkey >= scalar @{$self->{ORDERFORM}}) {
		return wantarray ? () : undef;
	} else {
		my $key = $self->{ORDERFORM}->[$currkey];
		my $normalkey = $self->{nonorm} ? $key : normalize($key);
		return wantarray ? ($key, $self->{DATA}->{$normalkey}) : $key;
	}
}

1;
