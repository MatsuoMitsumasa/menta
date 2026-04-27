package MENTA::Request;
use strict;
use warnings;
use CGI::Simple;

sub new {
    my ($class, $env) = @_;
    bless { env => $env }, $class;
}

sub env { $_[0]->{env} }

sub hostname { $_[0]->{env}->{HTTP_HOST} || $_[0]->{env}->{SERVER_HOST} }
sub protocol { $_[0]->{env}->{SERVER_PROTOCOL} || 'HTTP/1.0' }
sub method   { $_[0]->{env}->{HTTP_METHOD} || 'GET' }

sub param {
    my $self = shift;
    local *STDIN = $self->{env}->{'psgi.input'};
    local %ENV = %{$self->{env}};
    $self->{cs} ||= CGI::Simple->new();
    $self->{cs}->param(@_);
}
sub upload {
    my $self = shift;
    local *STDIN = $self->{env}->{'psgi.input'};
    local %ENV = %{$self->{env}};
    $self->{cs} ||= CGI::Simple->new();
    $self->{cs}->upload(@_);
}
sub raw_body {
    my $self = shift;
    return $self->{raw_body} if exists $self->{raw_body};

    my $input = $self->{env}->{'psgi.input'};
    return $self->{raw_body} = '' unless $input;

    my $length = $self->{env}->{CONTENT_LENGTH};
    my $body = '';
    my $pos = eval { tell($input) };
    my $seekable = defined $pos && eval { seek($input, $pos, 0); 1 };
    seek($input, 0, 0) if $seekable;

    if (defined $length && $length > 0) {
        read($input, $body, $length);
    } else {
        local $/;
        $body = <$input>;
        $body = '' unless defined $body;
    }

    seek($input, $pos, 0) if $seekable;
    $self->{raw_body} = $body;
}
sub param_json {
    my $self = shift;
    return $self->{param_json} if exists $self->{param_json};
    my $body = $self->raw_body;
    return $self->{param_json} = undef unless defined $body && length $body;
    require JSON::PP;
    $self->{param_json} = JSON::PP::decode_json($body);
}
sub header {
    my ($self, $key) = @_;
    $key = uc $key;
    $key =~ s/-/_/;
    $self->{env}->{'HTTP_' . $key} || $self->{env}->{'HTTPS_' . $key};
}
sub cookie {
    my ($self, $key) = @_;
    $self->{cookies} ||= do {
        require CGI::Simple::Cookie;
        CGI::Simple::Cookie->parse($self->{env}->{HTTP_COOKIE} || '');
    };
    return $self->{cookies}->{$key}->value if defined $key && $self->{cookies}->{$key};
    return $self->{cookies};
}
sub headers {
    my ($self) = @_;
    $self->{headers} ||= do {
        require "HTTP/Headers.pm";
        my $headers = HTTP::Headers->new;
        for my $key (grep /^HTTPS?_/, keys %{$self->{env}}) {
            my $k = uc $key;
               $k =~ s/^HTTPS?_//;
               $k =~ s/_/-/;
            $headers->header($k, $self->{env}->{$key});
        }
        $headers;
    };
}

1;
