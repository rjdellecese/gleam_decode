# decode
![Hex.pm](https://img.shields.io/hexpm/v/gleam_decode)

A Gleam library for transforming Erlang or Elixir data into Gleam data.

`decode` provides you with the tools to build `Decoder`s, which can be used to
transform data from Erlang or Elixir into typed data that can then be operated
on with all the safety of the Gleam programming language!

## Getting started

If you're only concerned with decoding data from one of either Elixir or Erlang,
skip ahead to the relevant section, and then read the Gleam example.

### Elixir

Let's say that you have an Elixir struct that you'd like to work with in your
Gleam code.

```elixir
%User{name: "Jose Valim", age: 25}
```

Remember that under the hood, Elixir structs are just maps with a `__struct__`
field, and module names are just atoms!

```elixir
%{__struct__: Elixir.User, name: "Jose Valim", age: 25}
```

So let's say that you have an Elixir function that returns one of these User
structs, that you'd like to use in your Gleam code.

```elixir
# user.ex

@spec get_user() :: User.t()
```

### Erlang

Let's say that you have an Erlang record that you'd like to work with in your
Gleam code.

```erlang
-record(user, {name :: string(), age :: non_neg_integer()}).
```

Remember that Erlang records are just tagged tuples under the hood!

```erlang
{user, "Joe Armstrong", 35}
```

So let's say that you have an Erlang function that returns one of these user
records.

```erlang
%% user.erl

-spec get_user() -> user()
```

### Gleam

In order to translate this Elixir or Erlang data into a format that Gleam can
work with, we'll need to explain to Gleam how it maps onto Gleam types, and
probably define some custom types in the process.

```rust
// user.gleam

import decode.{Decoder, decode_dynamic, atom_field, element, map2, int, string}

// First, we define the Gleam type that we'd like to transform this data into.
pub type User {
  User(
    name: String,
    age: Int
  )
}

// Second, we define a decoder that will decode an Elixir User struct and
// transform it into our custom Gleam type.
pub fn ex_user_decoder() -> Decoder(User) {
  map2(
    User,
    atom_field("name", string()),
    atom_field("age", int())
  )
}

// Or an Erlang user record into our custom Gleam type.
pub fn erl_user_decoder() -> Decoder(User) {
  map2(
    User,
    element(1, string()),
    element(2, int())
  )
}

// Third, we create an external function that calls the Elixir function
// that returns a User struct.
fn external ex_external_get_user() -> Dynamic
  = "Elixir.User" "get_user"

// Or the Erlang function that returns a user record.
fn external erl_external_get_user() -> Dynamic
  = "user" "get_user"

// And finally, we write the functions that perform the decoding!
pub fn ex_create_user() -> Result(User, String) {
  ex_external_create_user()
  |> decode_dynamic(_, ex_user_decoder())

pub fn erl_create_user() -> Result(User, String) {
  erl_external_create_user()
  |> decode_dynamic(_, erl_user_decoder())
}
```


## Documentation

Although Gleam does not yet have a documentation generation tool, the public API
for this library is documented in the source code! Check out `src/decode.gleam`.

If after reading the source documentation you still need help, or are dealing
with a decoding problem that you don't believe is solvable with the current API,
please open an issue!


## Installation

Add `gleam_decode` to the deps section of your `rebar3.config` file.

```erlang
{deps, [
    {gleam_decode, "1.0.0"}
]}.
```


## Thanks

Most of this library is based on the Elm language's JSON decoding library
([elm/json][1]), with some attention paid also to the community-driven "JSON
extras" library ([elm-community/json-extra][2]). Thanks to them for the great
ideas!

[1]: https://github.com/elm/json/tree/master
[2]: https://github.com/elm-community/json-extra/tree/master
