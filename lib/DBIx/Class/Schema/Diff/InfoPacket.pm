package DBIx::Class::Schema::Diff::InfoPacket;
use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base 0.25 qw(:all);

has 'name', required => 1, is => 'ro', isa => Str;
has 'old_info', required => 1, is => 'ro', isa => Maybe[HashRef];
has 'new_info', required => 1, is => 'ro', isa => Maybe[HashRef];

has 'source_diff', required => 1, is => 'ro', isa => InstanceOf[
  'DBIx::Class::Schema::Diff::Source'
];


has 'ignore', is => 'ro', isa => Maybe[ArrayRef];
has 'limit',  is => 'ro', isa => Maybe[ArrayRef];

has 'added', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  defined $self->new_info && ! defined $self->old_info
}, init_arg => undef, isa => Bool;

has 'deleted', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  defined $self->old_info && ! defined $self->new_info
}, init_arg => undef, isa => Bool;


has 'diff', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  
  return undef if ($self->_is_ignore($self->name));
  
  # There is no reason to diff in the case of added/deleted:
  return { _event => 'added'   } if ($self->added);
  return { _event => 'deleted' } if ($self->deleted);
  
  my ($o,$n) = ($self->old_info,$self->new_info);
  my $diff = $self->_info_diff($o,$n) or return undef;
  
  return { _event => 'changed', diff => $diff };
  
}, init_arg => undef, isa => Maybe[HashRef];


sub _info_diff { (shift)->source_diff->schema_diff->_info_diff(@_) }

has '_ignore_ndx', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return { map {$_=>1} @{$self->ignore || []} };
}, init_arg => undef, isa => HashRef;

has '_limit_ndx', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return { map {$_=>1} @{$self->limit || []} };
}, init_arg => undef, isa => HashRef;

sub _is_ignore {
  my ($self,$name) = @_;
  return (
    $self->_ignore_ndx->{$name} ||
    ($self->limit && ! $self->_limit_ndx->{$name})
  );
}



1;