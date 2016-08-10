#!/usr/bin/perl

use HTTP::Request::Params;
use Test::LWP::UserAgent;
use Test::More;
use warnings;

require SBSS::Client;

# Mock
my (
	$username, 
	$user_authd, 
	$password, 
	$challenge, 
	$authkey
) = (
	'anyuser', 
	'i am athorized', 
	'anypassword', 
	12573042,
	'4b9dcd49a21d2c6a3cef3780bab3cce2e8a6aca2'
);

my $useragent = Test::LWP::UserAgent->new;

$useragent->map_response(
	qr{/},
	sub {
		my $request = shift;
		my $str;

		my $params = HTTP::Request::Params->new({
			req => $request,
		})->params;

		if($params->{inc} && $params->{cmd}) {
		
		} 
		elsif(exists $params->{login}) { 
			if($params->{login} eq $user_authd) {
			
			}
			elsif(exists $params->{authorize} && $params->{authorize}eq $authkey) {
				$str = '{"success":true}';
			} else {
				$str = '{"success":false,"authorize":false,"login":null,"challenge":' . $challenge . ',"cname":"f22c35cdf19cca2b"}';
			}
		}

		return HTTP::Response->new(
			'200', 
			'OK', 
			['Content-Type' => 'application/json'], 
			$str ? '(' . $str . ')' : ''
		); 
	}
);


subtest 'Through the object instance' => sub {
	my $ua = SBSS::Client->new(
		ua => $useragent,
		username => $username, 
		password => $password
	);

	is(
		$ua->username(),
		$username,
		'Username is valid through constructor'
	);

	is(
		$ua->password(),
		$password,
		'Password is valid through constructor'
	);

	is(
		$ua->auth_key($challenge),
		$authkey,
		'Authentication key'
	);

	$ua->get('http://example.local/'),
	ok(
		$useragent->last_http_request_sent->header('X-Requested-With') eq 'XMLHttpRequest',
		'X-Requested-With is XMLHttpRequest'
	);

	ok(
		$useragent->last_http_request_sent->header('User-Agent') eq $ua->agent(),
		'Validate default User-Agent header'
	);

	# Reset authorized
	$ua->authorized(0);
	$ua->login('http://example.local/', []),
	is(
		$ua->authorized(),
		1,
		'Authenticate'
	);

	# User already authorized
	$ua->authorized(0);
	$ua->username($user_authd);
	$ua->login('http://example.local/', []),
	is(
		$ua->authorized(),
		1,
		'Already authenticated. Empty response'
	);
};

done_testing();
