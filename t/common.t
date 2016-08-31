#!/usr/bin/perl

use HTTP::Request::Params;
use Test::LWP::UserAgent;
use Test::More;
use warnings;

use Cwd qw(abs_path);
use FindBin;
use lib abs_path("$FindBin::Bin/../lib");

require SBSS::Client;

# Mock
my (
	$username, 
	$user_authd, 
	$password, 
	$challenge, 
	$authkey,
	$agent
) = (
	'anyuser', 
	'i am athorized', 
	'anypassword', 
	12573042,
	'4b9dcd49a21d2c6a3cef3780bab3cce2e8a6aca2',
	'Sbss-Api-Agent'
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
			if($params->{inc} eq "apikey" && $params->{cmd} eq "get") {
				$user_h = $request->header('x-sbss-auth');
				$cookie_h = $request->header('cookie');

				if($user_h && $cookie_h && $cookie_h =~ /=$user_h:\d:[0-9a-f]+/) {
					$str = '{"success":true}';
				} else { 
					$str = '{"success":false,"error":"Missing headers: X-Sbss-Auth or Cookie}';
				}
			} else {
				$str = '{"success":false,"error":"Could not load component"}';
			}
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
		agent => $agent,
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
		$ua->agent(),
		$agent,
		'UserAgent name is valid through constructor'
	);

	is(
		$ua->ua->agent(),
		$agent,
		'UserAgent name was passed to the lwp'
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

subtest 'Light API access' => sub {
	my ($keyname, $keyvalue) = ('f01ef1201692b5bd', 'anyuser:0:fa3dd48acd151d1a6ff8f2876307ddc3b5e03eb9');

	my $ua = SBSS::Client->new(
		ua => $useragent,
		agent => $agent,
		apikey => {
			name => $keyname,
			value => $keyvalue
		}
	);

	is(
		$ua->apikey()->{name},
		$keyname,
		'Key name is valid through constructor'
	);

	is(
		$ua->apikey()->{value},
		$keyvalue,
		'Key value is valid through constructor'
	);

	my $content = $ua->get('http://example.local/?inc=apikey&cmd=get');
	is(
		$ua->json_decode($content->content)->{success},
		1,
		'Content'
	);
};
done_testing();
