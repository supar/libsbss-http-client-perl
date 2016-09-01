#!/usr/bin/perl
package SBSS::Client;

use Moose;
use MooseX::Types::Moose qw(Str);
use MooseX::Types::Structured qw(Dict);
use LWP::UserAgent;
use HTTP::Cookies;
use Scalar::Util 'reftype';
use JSON::PP;
use Digest::MD5 qw(md5 md5_hex);
use Digest::SHA qw(sha1 sha1_hex);
use strict;

has ua => (
	is => 'ro', 'isa' => 'LWP::UserAgent',
	lazy => 1,
	default => sub { return LWP::UserAgent->new }
);

has [ 'username', 'password' ] => ( is => 'rw' );
has authorized => ( is => 'rw', default => 0 );
has agent => ( is => 'ro', lazy => 1, default => 'Sbss-Perl-Client');
has apikey => ( is => 'ro', isa => Dict[ name => Str, value => Str] );

sub BUILD {
	my $self = shift;

	$self->ua->ssl_opts( verify_hostnames => 0 );
	$self->ua->default_header('X-Requested-With' => 'XMLHttpRequest');
	$self->ua->agent($self->agent());

	if($self->apikey()) {
		$self->set_api_key();

	}
};


sub login {
	my $self = shift;
	my ($response, $content);

	$response = $self->ua->post($_[0], [
		'login' => $self->username(),
		'async' => 1
	]);

	# It seams that already authenticated
	if($response->code eq '200' && !$response->content) {
		$self->authorized(1);
		return $response;
	}

	$content = $self->json_decode($response->content);

	if(exists $content->{success} && !$content->{success}) {
		$response = $self->ua->post($_[0], [
			'login' => $self->{username},
			'remember' => 0,
			'authorize' => $self->auth_key($content->{challenge}),	
			'async' => 1
		]);
		$content = $self->json_decode($response->content);
	}

	$self->authorized($content->{success} ? 1 : 0);

	return $response;
}

sub auth_key {
	my ($self, $challenge) = @_;
	return sha1_hex($self->{username} . md5_hex($self->{password}) . $challenge)
}

sub json_decode {
	my ($self, $content) = @_;

	# remove garbage
	$content =~ s/^\(//;
	$content =~ s/\)$//;

	return JSON::PP->new->utf8->allow_singlequote->allow_barekey->decode($content);
}

sub set_api_key {
	my $self = shift;

	my ($user) = split /:/, $self->apikey()->{value};
	my $cookie = HTTP::Cookies->new();

	if(!$user) {
		$self->apikey(undef);
		return;
	}

	$self->ua->default_header('X-Sbss-Auth' => $user);
	$self->ua->cookie_jar($cookie);

	$self->ua->add_handler( request_prepare => sub {
		$self->add_cookie(@_);
	}, m_header__x_sbss_auth => $user );
}

sub add_cookie {
	my($self, $request, $ua, $h) = @_;

	$ua->cookie_jar()->set_cookie(
		0,
		$self->apikey()->{name},
		$self->apikey()->{value},
		$request->uri->path, $request->uri->host
	);

	$ua->cookie_jar()->add_cookie_header($request);

	return($request);
}

sub get {
	my $self = shift;

	if(!$self->apikey()) {
		if(!$self->authorized()) {
			$self->login(@_);
		}
	} else {
		warn 'SBSS does not support GET requests with API key';
	}

	return $self->ua->get(@_);
}

sub post {
	my $self = shift;

	if(!$self->apikey()) {
		if(!$self->authorized()) {
			$self->login(@_);
		}
	}

	return $self->ua->post(@_);
}

__PACKAGE__->meta->make_immutable;

=encoding utf-8

=head1 NAME

SBSS::Client

=head1 DESCRIPTION

Simple module to communicate with SBSS API

=head1 AUTHOR

Paul Rezunenko, C<< <paulrez at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Paul Rezunenko.

This program is free software; you can redistribute it and/or modify it
under the terms of the BSD license.

=cut
