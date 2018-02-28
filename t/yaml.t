use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojolicious;

my $n = 0;
my %modules = ('YAML::XS'=>'0.67');
for my $module (keys %modules) {
  unless (eval "use $module $modules{$module};1") {
    diag "Skipping test when $module $modules{$module} is not installed";
    next;
  }

  no warnings qw(once redefine);
  use JSON::Validator;
  local *JSON::Validator::_load_yaml = eval "\\\&$module\::Load";
  $n++;
  diag join ' ', $module, $module->VERSION || 0;
  my $app = Mojolicious->new;
  eval { $app->plugin(OpenAPI => {url => 'data://main/coercion.yaml'}); 1 };
  ok !$@, "Could not load Swagger2 plugin using $module" or diag $@;
}

ok 1, 'no yaml modules available' unless $n;

done_testing;

__DATA__
@@ coercion.yaml
---
swagger: "2.0"
info:
  version: 1.0.0
  title: Swagger Petstore
  license:
    name: MIT
host: petstore.swagger.wordnik.com
basePath: /v1
schemes:
  - http
consumes:
  - application/json
produces:
  - application/json
paths:
  /pets:
    x-something-something:
      x-nothing-here: No, really!
    get:
      x-mojo-controller: "t::Api"
      summary: List all pets
      operationId: listPets
      tags:
        - pets
      parameters:
        - name: limit
          in: query
          description: How many items to return at one time (max 100)
          type: integer
          format: int32
      responses:
        200:
          description: An paged array of pets
          headers:
            x-next:
              type: string
              description: A link to the next page of responses
          schema:
            $ref: Pets
        default:
          description: unexpected error
          schema:
            $ref: Error
    post:
      x-mojo-controller: "t::Api"
      summary: Create a pet
      operationId: createPets
      tags:
        - pets
      responses:
        201:
          description: Null response
        default:
          description: unexpected error
          schema:
            $ref: Error
  "/pets/{petId}":
    get:
      x-mojo-controller: "t::Api"
      summary: Info for a specific pet
      operationId: showPetById
      tags:
        - pets
      parameters:
        - name: petId
          in: path
          description: The id of the pet to retrieve
          required: true
          type: string
      responses:
        200:
          description: Expected response to a valid request
          schema:
            $ref: Pets
        default:
          description: unexpected error
          schema:
            $ref: Error
definitions:
  Pet:
    required:
      - id
      - name
    properties:
      id:
        type: integer
        format: int64
      name:
        type: string
      tag:
        type: string
  Pets:
    type: array
    items:
      $ref: Pet
  Error:
    required:
      - code
      - message
    properties:
      code:
        type: integer
        format: int32
      message:
        type: string
