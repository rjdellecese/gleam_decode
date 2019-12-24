# decode
<!-- TODO: Add some badges! -->

A Gleam library for transforming Erlang or Elixir data into Gleam data.

`decode` provides you with the tools to build `Decoder`s, which can be used to
transform data from Erlang or Elixir into typed data, which can then be operated
on with all the safety of the Gleam programming language!

## Basic usage

Let's say that you have an Elixir or Erlang function that you'd like to call
from your Gleam code, whose returned data you'd like to work with in Gleam.

```elixir
# user.ex

defmodule User do
  defstruct name: "Jose Valim", age: 25
  @type t :: %__MODULE__{name: String.t(), age: non_neg_integer}

  @doc """
  Create a user struct with the default values.
  """
  @spec create_user() :: User.t()
  def create_user(), do: %User{}
end
```

```erlang
%% user.hrl

%%-----------------------------------------------------------
%% Data Type: user
%% where:
%%    name:  A string (default is "John").
%%    age:   An integer (default is 25).
%%------------------------------------------------------------
-record(user, {name = "Joe Armstrong", age = 35}).
```

```erlang
%% user.erl

-module(user).
-include("user.hrl").
-compile(export_all).


%% @doc Creates a user record with the default values.
-spec create_user() -> user()
create_user() ->
   #user{}.
```

And let's say that you want to turn each of these users into a `User` struct in
Gleam.

```gleam
// user.gleam

import decode.{Decoder, decode_dynamic, atom_field, element, map2, int, string}

pub struct User {
  name: String
  age: Int
}

// First, you define your decoders

pub fn ex_user_decoder() -> Decoder(User) {
  map2(
    User,
    atom_field("name", string()),
    atom_field("age", int()),
  )
}

pub fn erl_user_decoder() -> Decoder(User) {
  map2(
    User,
    element(1, string())
    element(2, int())
  )
}

// Second, you pull in your dynamic data

external ex_external_create_user() -> Dynamic =
  "Elixir" "User" "create_user"

external erl_external_create_user() -> Dynamic =
  "user" "create_user"

// And third, you do the decoding

pub fn ex_create_user() -> Result(User, String) {
  ex_external_create_user
  |> decode_dynamic(_, ex_user_decoder)
}

pub fn erl_create_user() -> Result(User, String) {
  erl_external_create_user
  |> decode_dynamic(_, erl_user_decoder)
}
```

That's it! Let's see it in action in a test.

```gleam
// user_test.gleam
import gleam/expect
import user.{ex_create_user, erl_create_user}

pub fn erl_user_test() {
  ex_create_user()
  |> expect.equal(_, Ok(User(name: "Jose Valim", age: 25)))
}

pub fn ex_user_test() {
  ex_create_user()
  |> expect.equal(_, Ok(User(name: "Joe Armstrong", age: 35)))
}
```


## Installation

Add `gleam_decode` to the deps section of your `rebar3.config` file.

```erlang
{deps, [
    {gleam_decode, "1.0.0"}
]}.
```

And then install it with

```shell
rebar3 get-deps
```


## Contributing

```sh
# Build the project
rebar3 compile

# Run the eunit tests
rebar3 eunit

# Run the Erlang REPL
rebar3 shell
```
