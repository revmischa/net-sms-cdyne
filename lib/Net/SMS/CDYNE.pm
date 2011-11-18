package Net::SMS::CDYNE;

use 5.008_001;
our $VERSION = '0.02';

use Any::Moose;
use Any::Moose 'X::NonMoose';
use XML::Simple;
use Carp qw/croak cluck/;
use Net::SMS::CDYNE::Response;

extends 'REST::Client';

has 'debug' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has 'api_key' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

sub do_cdyne_request {
    my ($self, $method, $uri, $args) = @_;

    croak "URI is required" unless $uri;

    $args ||= {};
    $args->{LicenseKey} ||= $self->api_key;

    # build request
    my $body;
    my $args_encoded = $args && %$args ? $self->buildQuery($args) : '';
    $args_encoded =~ s/^(\?)//;
    if (lc $method eq 'get') {
        $uri .= '?' . $args_encoded;
    } else {
        $body = $args_encoded;
    }

    warn "Request: $uri\n" if $self->debug;

    $self->request($method, $uri, $body);

    my $response_code = $self->responseCode;
    my $content = $self->responseContent;

    if (! $response_code || index($response_code, '2') != 0) {
        warn "CDYNEv2 request ($uri) failed with code $response_code: " . $content;
        
        # return empty response
        return Net::SMS::CDYNE::Response->new(response_code => $response_code);
    }

    warn "\nResponse: $content\n" if $self->debug;

    # attempt to parse response XML
    my $resp_obj = eval { XMLin($content) };
    warn "Failed parsing response: $content ($@)" unless $resp_obj;

    my $ret = {
        response_code => $response_code,
        %$resp_obj,
    };

    return bless $ret, 'Net::SMS::CDYNE::Response';
}

sub simple_sms_send_with_postback {
    my ($self, %args) = @_;

    my $uri = 'https://sms2.cdyne.com/sms.svc/SecureREST/SimpleSMSsendWithPostback';
    return $self->do_cdyne_request('GET', $uri, \%args);
}

sub simple_sms_send {
    my ($self, %args) = @_;

    my $uri = 'https://sms2.cdyne.com/sms.svc/SecureREST/SimpleSMSsend';
    return $self->do_cdyne_request('GET', $uri, \%args);
}

sub advanced_sms_send {
    my ($self, %args) = @_;

    my $uri = 'https://sms2.cdyne.com/sms.svc/SecureREST/AdvancedSMSsend';
    return $self->do_cdyne_request('POST', $uri, \%args);
}

sub get_unread_incoming_messages {
    my ($self, %args) = @_;

    my $uri = 'https://sms2.cdyne.com/sms.svc/SecureREST/GetUnreadIncomingMessages';
    return $self->do_cdyne_request('GET', $uri, \%args);
}

sub get_message_status_by_reference_id {
    my ($self, %args) = @_;

    my $uri = 'https://sms2.cdyne.com/sms.svc/SecureREST/GetMessageStatusByReferenceID';
    return $self->do_cdyne_request('GET', $uri, \%args);
}

sub get_message_status {
    my ($self, %args) = @_;

    my $uri = 'https://sms2.cdyne.com/sms.svc/SecureREST/GetMessageStatus';
    return $self->do_cdyne_request('GET', $uri, \%args);
}

sub cancel_message {
    my ($self, %args) = @_;

    my $uri = 'https://sms2.cdyne.com/sms.svc/SecureREST/CancelMessage';
    return $self->do_cdyne_request('GET', $uri, \%args);
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Net::SMS::CDYNE - Perl REST client for CDYNE's SMSNotify API

=head1 SYNOPSIS

  use Net::SMS::CDYNE;
  my $client = Net::SMS::CDYNE->new(api_key => '123-45-6790');
  my $resp = $client->simple_sms_send_with_postback(
      PhoneNumber       => $to,
      Message           => $msg,
      StatusPostBackURL => $reply_url,
  );
  warn "Sent OK: " . ($resp->success ? 'yes' : 'no');


=head1 DESCRIPTION

Spec: https://secure.cdyne.com/downloads/SPECS_SMS-Notify2.pdf

Uses SecureREST API: https://sms2.cdyne.com/sms.svc/SecureREST/help

=head1 METHODS

=over 4

 simple_sms_send

 simple_sms_send_with_postback

 advanced_sms_send

 get_unread_incoming_messages

 get_message_status_by_reference_id

 get_message_status

 cancel_message

=back

=head1 SEE ALSO

L<Net::SMS::CDYNE::Response>

=head1 AUTHOR

Mischa Spiegelmock E<lt>revmischa@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
