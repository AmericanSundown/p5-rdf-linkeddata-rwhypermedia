#!/usr/bin/env perl

use FindBin qw($Bin);
use Plack::Request;

use strict;
use Test::More;
use Test::RDF;
use Log::Any::Adapter;
use Module::Load::Conditional qw[can_load];

Log::Any::Adapter->set($ENV{LOG_ADAPTER} || 'Stderr') if $ENV{TEST_VERBOSE};

my $file = $Bin . '/data/basic.ttl';

BEGIN {
    use_ok('RDF::LinkedData');
    use_ok('RDF::LinkedData::RWHypermedia');
    use_ok('RDF::Trine::Parser');
    use_ok('RDF::Trine::Model');
 }

my $parser     = RDF::Trine::Parser->new( 'turtle' );
my $model = RDF::Trine::Model->temporary_model;
my $base_uri = 'http://localhost';
$parser->parse_file_into_model( $base_uri, $file, $model );

ok($model, "We have a model");

my $ld = RDF::LinkedData::RWHypermedia->new(model => $model, 
														  base_uri=>$base_uri, 
														  write_enabled => 1);

isa_ok($ld, 'RDF::LinkedData');
isa_ok($ld, 'RDF::LinkedData::RWHypermedia');
cmp_ok($ld->count, '>', 0, "There are triples in the model");

{
    note "Get /foo";
    $ld->request(Plack::Request->new({}));
    my $response = $ld->response($base_uri . '/foo');
    isa_ok($response, 'Plack::Response');
    is($response->status, 303, "Returns 303");
    like($response->header('Location'), qr|/foo/data$|, "Location is OK");
}


done_testing;
