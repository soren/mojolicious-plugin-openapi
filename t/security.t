use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;
post '/global' => sub {
  my $c = shift->openapi->valid_input or return;
  $c->reply->openapi(200 => {ok => 1});
  },
  'global';

post '/simple' => sub {
  my $c = shift->openapi->valid_input or return;
  $c->reply->openapi(200 => {ok => 1});
  },
  'simple';

post '/fail_or_pass' => sub {
  my $c = shift->openapi->valid_input or return;
  $c->reply->openapi(200 => {ok => 1});
  },
  'fail_or_pass';

post '/fail_and_pass' => sub {
  my $c = shift->openapi->valid_input or return;
  $c->reply->openapi(200 => {ok => 1});
  },
  'fail_and_pass';

post '/cache' => sub {
  my $c = shift->openapi->valid_input or return;
  $c->reply->openapi(200 => {ok => 1});
  },
  'cache';

post '/die' => sub {
  my $c = shift->openapi->valid_input or return;
  $c->reply->openapi(200 => {ok => 1});
  },
  'die';

our %checks;
plugin OpenAPI => {
  url      => 'data://main/sec.json',
  security => {
    pass1 => sub {
      my ($c, $def, $scopes, $cb) = @_;
      $checks{pass1}++;
      $cb->(1);
    },
    pass2 => sub {
      my ($c, $def, $scopes, $cb) = @_;
      $checks{pass2}++;
      $cb->(1);
    },
    fail1 => sub {
      my ($c, $def, $scopes, $cb) = @_;
      $checks{fail1}++;
      $cb->(0);
    },
    fail2 => sub {
      my ($c, $def, $scopes, $cb) = @_;
      $checks{fail2}++;
      $cb->(0);
    },
    die => sub {
      my ($c, $def, $scopes, $cb) = @_;
      $checks{die}++;
      die 'Argh!';
    },
  },
};

my $t = Test::Mojo->new;
subtest 'global' => sub {
  local %checks;
  $t->post_ok('/api/global' => json => {})->status_is(200)
    ->json_is('/ok' => 1);
  is_deeply \%checks, {pass1 => 1}, 'expected checks occurred';
};

subtest 'simple local' => sub {
  local %checks;
  $t->post_ok('/api/simple' => json => {})->status_is(200)
    ->json_is('/ok' => 1);
  is_deeply \%checks, {pass2 => 1}, 'expected checks occurred';
};

subtest 'fail or pass' => sub {
  local %checks;
  $t->post_ok('/api/fail_or_pass' => json => {})->status_is(200)
    ->json_is('/ok' => 1);
  is_deeply \%checks, {fail1 => 1, pass1 => 1}, 'expected checks occurred';
};

subtest 'fail and pass' => sub {
  local %checks;
  $t->post_ok('/api/fail_and_pass' => json => {})->status_is(401);
  is_deeply \%checks, {fail1 => 1, pass1 => 1}, 'expected checks occurred';
};

subtest 'cache' => sub {
  local %checks;
  $t->post_ok('/api/cache' => json => {})->status_is(200)
    ->json_is('/ok' => 1);
  is_deeply \%checks, {fail1 => 1, pass1 => 1, pass2 => 1}, 'expected checks occurred';
};

subtest 'die' => sub {
  local %checks;
  $t->post_ok('/api/die' => json => {})->status_is(500)
    ->json_has('/errors/0/message');
  is_deeply \%checks, {die => 1}, 'expected checks occurred';
};

done_testing;

__DATA__
@@ sec.json
{
  "swagger": "2.0",
  "info": { "version": "0.8", "title": "Pets" },
  "schemes": [ "http" ],
  "basePath": "/api",
  "securityDefinitions": {
    "pass1": {
      "type": "apiKey",
      "name": "Authorization",
      "in": "header",
      "description": "dummy"
    },
    "pass2": {
      "type": "apiKey",
      "name": "Authorization",
      "in": "header",
      "description": "dummy"
    },
    "fail1": {
      "type": "apiKey",
      "name": "Authorization",
      "in": "header",
      "description": "dummy"
    },
    "fail2": {
      "type": "apiKey",
      "name": "Authorization",
      "in": "header",
      "description": "dummy"
    },
    "die": {
      "type": "apiKey",
      "name": "Authorization",
      "in": "header",
      "description": "dummy"
    }
  },
  "security": [{"pass1": []}],
  "paths": {
    "/global": {
      "post": {
        "x-mojo-name": "global",
        "parameters": [
          { "in": "body", "name": "body", "schema": { "type": "object" } }
        ],
        "responses": {
          "200": {"description": "Echo response", "schema": { "type": "object" }},
          "401": {"description": "Sorry mate"}
        }
      }
    },
    "/simple": {
      "post": {
        "x-mojo-name": "simple",
        "security": [{"pass2": []}],
        "parameters": [
          { "in": "body", "name": "body", "schema": { "type": "object" } }
        ],
        "responses": {
          "200": {"description": "Echo response", "schema": { "type": "object" }},
          "401": {"description": "Sorry mate"}
        }
      }
    },
    "/fail_or_pass": {
      "post": {
        "x-mojo-name": "fail_or_pass",
        "security": [
          {"fail1": []},
          {"pass1": []}
        ],
        "parameters": [
          { "in": "body", "name": "body", "schema": { "type": "object" } }
        ],
        "responses": {
          "200": {"description": "Echo response", "schema": { "type": "object" }},
          "401": {"description": "Sorry mate"}
        }
      }
    },
    "/fail_and_pass": {
      "post": {
        "x-mojo-name": "fail_and_pass",
        "security": [
          {
            "fail1": [],
            "pass1": []
          }
        ],
        "parameters": [
          { "in": "body", "name": "body", "schema": { "type": "object" } }
        ],
        "responses": {
          "200": {"description": "Echo response", "schema": { "type": "object" }},
          "401": {"description": "Sorry mate"}
        }
      }
    },
    "/cache": {
      "post": {
        "x-mojo-name": "cache",
        "security": [
          {
            "fail1": [],
            "pass1": []
          },
          {
            "pass1": [],
            "pass2": []
          }
        ],
        "parameters": [
          { "in": "body", "name": "body", "schema": { "type": "object" } }
        ],
        "responses": {
          "200": {"description": "Echo response", "schema": { "type": "object" }},
          "401": {"description": "Sorry mate"}
        }
      }
    },
    "/die": {
      "post": {
        "x-mojo-name": "die",
        "security": [
          {"die": []},
          {"pass1": []}
        ],
        "parameters": [
          { "in": "body", "name": "body", "schema": { "type": "object" } }
        ],
        "responses": {
          "200": {"description": "Echo response", "schema": { "type": "object" }},
          "401": {"description": "Sorry mate"}
        }
      }
    }
  }
}
