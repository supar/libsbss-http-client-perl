## Library for WWW access in Perl to the SBSS API

### Dependences

- Moose
- MooseX::Types::Moose
- MooseX::Types::Structured
- LWP::UserAgent
- HTTP::Cookies
- JSON::PP
- Digest::MD5
- Digest::SHA

### Usage

Authentication with login/password

```
use warnings;
use Data::Dumper;
use SBSS::Client;

my $ua = SBSS::Client->new(
	username => 'manager',
	password => 'manager_password'
);

# Try GET
my $get_response = $ua->get('http://sbss.server.localhost/index.php?inc=requests&cmd=get');

# Try POST
my $post_response = $ua->post('http://sbss.server.localhost/', { inc => 'requests', cmd => 'get' });

# Decode string content

print Dumper $ua->json_decode($get_response->content);

```

Authentication with API key. Remember SBSS API with key does not support GET requests.

```
my $ua = SBSS::Client->new(
	apikey => {
		name => "101ea1200692b5b0",
		value => "manager:0:0a3dd18acd151d1a6ff8f2876307ddc3b5e03eb9"
	}
);
```
