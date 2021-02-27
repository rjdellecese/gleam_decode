import gleam/atom.{Atom} as atom_mod
import gleam/dynamic.{Dynamic} as dynamic_mod
import gleam/function
import gleam/list
import gleam/result
import gleam/string as string_mod

// TYPES
pub type Decoder(a) {
  Decoder(fn(Dynamic) -> Result(a, String))
}

// PRIMITIVES
/// Create a decoder that will attempt to transform a `Dynamic` into a `Bool`.
pub fn bool() -> Decoder(Bool) {
  Decoder(dynamic_mod.bool)
}

/// Create a decoder that will attempt to transform a `Dynamic` into an `Atom`.
///
/// Note that in Erlang, values such as `undefined`, `null`, `nil`, and `none`
/// are all atoms! In Elixir, `nil` is an atom as well.
pub fn atom() -> Decoder(Atom) {
  Decoder(dynamic_mod.atom)
}

/// Create a decoder that will attempt to transform a `Dynamic` into an `Int`.
pub fn int() -> Decoder(Int) {
  Decoder(dynamic_mod.int)
}

/// Create a decoder that will attempt to transform a `Dynamic` into a `Float`.
pub fn float() -> Decoder(Float) {
  Decoder(dynamic_mod.float)
}

/// Create a decoder that will attempt to transform a `Dynamic` into a `String`.
pub fn string() -> Decoder(String) {
  Decoder(dynamic_mod.string)
}

/// Create a decoder that will attempt to transform a `Dynamic` into a
/// `BitString`.
pub fn bit_string() -> Decoder(BitString) {
  Decoder(dynamic_mod.bit_string)
}

// NESTED DATA
/// Create a decoder that retrieves an element in a tuple at the given position.
pub fn element(at position: Int, with decoder: Decoder(value)) -> Decoder(value) {
  let Decoder(decode_fun) = decoder

  let fun = fn(dynamic) {
    dynamic
    |> dynamic_mod.element(position)
    |> result.then(decode_fun)
  }

  Decoder(fun)
}

/// Create a decoder that gets the value for a given field in a map. If the
/// field you're trying to access is an atom, consider using the `atom_field`
/// function instead of this one.
pub fn field(named: a, with decoder: Decoder(value)) -> Decoder(value) {
  let Decoder(decode_fun) = decoder

  let fun = fn(dynamic) {
    dynamic
    |> dynamic_mod.field(named)
    |> result.then(decode_fun)
  }

  Decoder(fun)
}

/// Create a decoder that takes a field name as a string and tries to turn it
/// into an atom in order to access it. If the atom doesn't exist, the field
/// doesn't either! And in that case the decoder will fail.
///
/// Atoms are commonly used as map fields in Erlang and Elixir; when accessing
/// map keys that are atoms, this saves you the trouble of having to handle atom
/// creation/error handling yourself.
pub fn atom_field(named: String, with decoder: Decoder(value)) -> Decoder(value) {
  let Decoder(decode_fun) = decoder
  let named_result =
    atom_mod.from_string(named)
    |> result.map_error(fn(_a) {
      string_mod.append("No atom key by name of `", named)
      |> string_mod.append("` found")
    })

  let fun = fn(dynamic) {
    named_result
    |> result.then(dynamic_mod.field(dynamic, _))
    |> result.then(decode_fun)
  }

  Decoder(fun)
}

/// Create a decoder for decoding a list of values.
pub fn list(with decoder: Decoder(value)) -> Decoder(List(value)) {
  let Decoder(decode_fun) = decoder
  let list_fun = dynamic_mod.typed_list(_, decode_fun)

  Decoder(list_fun)
}

// COMPLEX DECODING
/// Create a decoder that always succeeds with the `Dynamic` data provided,
/// untouched.
///
/// This is useful when you are receiving particularly complex `Dynamic` data
/// that you want to deal with later in your program (this might be useful when
/// interfacing with Erlang or Elixir libraries, for example), or when you're
/// going to send it back out to Erlang or Elixir code and aren't concerned
/// about dealing with its structure in Gleam.
pub fn dynamic() -> Decoder(Dynamic) {
  Decoder(fn(dynamic) { Ok(dynamic) })
}

/// Create a decoder that always succeeds with the given value, ignoring the
/// provided `Dynamic` data.
///
/// This is usually used with `then` and `one_of`.
pub fn succeed(a) -> Decoder(a) {
  Decoder(fn(_dynamic) { Ok(a) })
}

/// Create a decoder that always fails with the given value, ignoring the
/// provided `Dynamic` data.
///
/// This is usually used with `then` and `one_of`.
pub fn fail(error: String) -> Decoder(a) {
  Decoder(fn(_dynamic) { Error(error) })
}

fn try_decoders(
  dynamic: Dynamic,
  decoders: List(Decoder(a)),
) -> Result(a, String) {
  case decoders {
    [Decoder(decode_fun), ..remaining_decoders] ->
      case decode_fun(dynamic) {
        Ok(val) -> Ok(val)
        Error(_str) -> try_decoders(dynamic, remaining_decoders)
      }
    [] -> Error("All decoders failed")
  }
}

/// Create a decoder that tries to decode a value with a list of different
/// decoders.
pub fn one_of(decoders: List(Decoder(a))) -> Decoder(a) {
  Decoder(fn(dynamic) { try_decoders(dynamic, decoders) })
}

fn unwrap(decoder: Decoder(a)) -> fn(Dynamic) -> Result(a, String) {
  let Decoder(decode_fun) = decoder
  decode_fun
}

/// Create a decoder that operates on a previous result. Often used with
/// `from_result` to decode a `Dynamic` value into a particular record/type.
pub fn then(
  after decoder: Decoder(a),
  apply fun: fn(a) -> Decoder(b),
) -> Decoder(b) {
  let Decoder(decode_fun) = decoder
  let unwrapped_decoder_fun = function.compose(fun, unwrap)

  Decoder(fn(dynamic) {
    dynamic
    |> decode_fun
    |> result.then(fn(a) { unwrapped_decoder_fun(a)(dynamic) })
  })
}

/// Create a decoder from a `Result`. Useful whenn used with `then` to transform
/// a `Dynamic` value into a record/type.
pub fn from_result(result: Result(a, String)) -> Decoder(a) {
  case result {
    Ok(value) -> succeed(value)
    Error(error) -> fail(error)
  }
}

/// A common pattern in Erlang and Elixir code is to, instead of raising a
/// runtime error upon some function's anticipated failure (resulting from
/// something like bad arguments, or a failed database query or network
/// request), return an `{ok, Success}` or `{error, Failure}` tuple (which would
/// look like `{:ok, success}` or `{:error, Failure}` in Elixir) instead.
///
/// This function creates a decoder that addresses this common scenario by
/// either running the `ok_decoder` if the `Dynamic` is a tuple whose first
/// element is an `ok` atom, or the `error_decoder` if the `Dynamic` is a tuple
/// whose first element is an `error` atom.
pub fn ok_error_tuple(
  ok_decoder: Decoder(value),
  error_decoder: Decoder(value),
) -> Decoder(value) {
  let failure_decoder = fn(atom_as_string) {
    "Expected 'ok' or 'error' atom in first position of tuple, got '"
    |> string_mod.append(atom_as_string)
    |> string_mod.append("' atom instead")
    |> fail
  }

  let success_or_failure_fun = fn(result_atom) {
    case atom_mod.to_string(result_atom) {
      "ok" -> ok_decoder
      "error" -> error_decoder
      atom_as_string -> failure_decoder(atom_as_string)
    }
  }

  element(0, atom())
  |> then(success_or_failure_fun)
}

// MAPPING
/// Create a decoder that, if successful, transforms the original value it was
/// decoding into a different value.
///
/// Use `map` rather than `then` when your transformation function will never
/// fail (that is, when it returns a `val`, rather than a `Result(val, err)`.
/// Use `then` when it might!
pub fn map(fun: fn(a) -> value, with decoder: Decoder(a)) -> Decoder(value) {
  let Decoder(decode_fun) = decoder

  let mapped_fun = fn(dynamic) {
    dynamic
    |> decode_fun
    |> result.map(fun)
  }

  Decoder(mapped_fun)
}

/// Create a decoder from two decoders that, if both are successful, transforms
/// those decoded values into a different value.
///
/// `map2` and its siblings (`map3`, `map4`, etc.) are usually used to transform
/// data such as Erlang records or Elixir maps into Gleam records/types.
pub fn map2(
  fun: fn(a, b) -> value,
  decoder1: Decoder(a),
  decoder2: Decoder(b),
) -> Decoder(value) {
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2

  let mapped_fun = fn(dynamic) {
    case decode_fun1(dynamic), decode_fun2(dynamic) {
      Ok(a), Ok(b) -> Ok(fun(a, b))
      Error(str), _ -> Error(str)
      _, Error(str) -> Error(str)
    }
  }

  Decoder(mapped_fun)
}

pub fn map3(
  fun: fn(a, b, c) -> value,
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
) -> Decoder(value) {
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3

  let mapped_fun = fn(dynamic) {
    case decode_fun1(dynamic), decode_fun2(dynamic), decode_fun3(dynamic) {
      Ok(a), Ok(b), Ok(c) -> Ok(fun(a, b, c))
      Error(str), _, _ -> Error(str)
      _, Error(str), _ -> Error(str)
      _, _, Error(str) -> Error(str)
    }
  }

  Decoder(mapped_fun)
}

pub fn map4(
  fun: fn(a, b, c, d) -> value,
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  decoder4: Decoder(d),
) -> Decoder(value) {
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3
  let Decoder(decode_fun4) = decoder4

  let mapped_fun = fn(dynamic) {
    case decode_fun1(dynamic), decode_fun2(dynamic), decode_fun3(dynamic), decode_fun4(
      dynamic,
    ) {
      Ok(a), Ok(b), Ok(c), Ok(d) -> Ok(fun(a, b, c, d))
      Error(str), _, _, _ -> Error(str)
      _, Error(str), _, _ -> Error(str)
      _, _, Error(str), _ -> Error(str)
      _, _, _, Error(str) -> Error(str)
    }
  }

  Decoder(mapped_fun)
}

pub fn map5(
  fun: fn(a, b, c, d, e) -> value,
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  decoder4: Decoder(d),
  decoder5: Decoder(e),
) -> Decoder(value) {
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3
  let Decoder(decode_fun4) = decoder4
  let Decoder(decode_fun5) = decoder5

  let mapped_fun = fn(dynamic) {
    case decode_fun1(dynamic), decode_fun2(dynamic), decode_fun3(dynamic), decode_fun4(
      dynamic,
    ), decode_fun5(dynamic) {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e) -> Ok(fun(a, b, c, d, e))
      Error(str), _, _, _, _ -> Error(str)
      _, Error(str), _, _, _ -> Error(str)
      _, _, Error(str), _, _ -> Error(str)
      _, _, _, Error(str), _ -> Error(str)
      _, _, _, _, Error(str) -> Error(str)
    }
  }

  Decoder(mapped_fun)
}

pub fn map6(
  fun: fn(a, b, c, d, e, f) -> value,
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  decoder4: Decoder(d),
  decoder5: Decoder(e),
  decoder6: Decoder(f),
) -> Decoder(value) {
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3
  let Decoder(decode_fun4) = decoder4
  let Decoder(decode_fun5) = decoder5
  let Decoder(decode_fun6) = decoder6

  let mapped_fun = fn(dynamic) {
    case decode_fun1(dynamic), decode_fun2(dynamic), decode_fun3(dynamic), decode_fun4(
      dynamic,
    ), decode_fun5(dynamic), decode_fun6(dynamic) {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f) -> Ok(fun(a, b, c, d, e, f))
      Error(str), _, _, _, _, _ -> Error(str)
      _, Error(str), _, _, _, _ -> Error(str)
      _, _, Error(str), _, _, _ -> Error(str)
      _, _, _, Error(str), _, _ -> Error(str)
      _, _, _, _, Error(str), _ -> Error(str)
      _, _, _, _, _, Error(str) -> Error(str)
    }
  }

  Decoder(mapped_fun)
}

pub fn map7(
  fun: fn(a, b, c, d, e, f, g) -> value,
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  decoder4: Decoder(d),
  decoder5: Decoder(e),
  decoder6: Decoder(f),
  decoder7: Decoder(g),
) -> Decoder(value) {
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3
  let Decoder(decode_fun4) = decoder4
  let Decoder(decode_fun5) = decoder5
  let Decoder(decode_fun6) = decoder6
  let Decoder(decode_fun7) = decoder7

  let mapped_fun = fn(dynamic) {
    case decode_fun1(dynamic), decode_fun2(dynamic), decode_fun3(dynamic), decode_fun4(
      dynamic,
    ), decode_fun5(dynamic), decode_fun6(dynamic), decode_fun7(dynamic) {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f), Ok(g) ->
        Ok(fun(a, b, c, d, e, f, g))
      Error(str), _, _, _, _, _, _ -> Error(str)
      _, Error(str), _, _, _, _, _ -> Error(str)
      _, _, Error(str), _, _, _, _ -> Error(str)
      _, _, _, Error(str), _, _, _ -> Error(str)
      _, _, _, _, Error(str), _, _ -> Error(str)
      _, _, _, _, _, Error(str), _ -> Error(str)
      _, _, _, _, _, _, Error(str) -> Error(str)
    }
  }

  Decoder(mapped_fun)
}

pub fn map8(
  fun: fn(a, b, c, d, e, f, g, h) -> value,
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  decoder4: Decoder(d),
  decoder5: Decoder(e),
  decoder6: Decoder(f),
  decoder7: Decoder(g),
  decoder8: Decoder(h),
) -> Decoder(value) {
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3
  let Decoder(decode_fun4) = decoder4
  let Decoder(decode_fun5) = decoder5
  let Decoder(decode_fun6) = decoder6
  let Decoder(decode_fun7) = decoder7
  let Decoder(decode_fun8) = decoder8

  let mapped_fun = fn(dynamic) {
    case decode_fun1(dynamic), decode_fun2(dynamic), decode_fun3(dynamic), decode_fun4(
      dynamic,
    ), decode_fun5(dynamic), decode_fun6(dynamic), decode_fun7(dynamic), decode_fun8(
      dynamic,
    ) {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f), Ok(g), Ok(h) ->
        Ok(fun(a, b, c, d, e, f, g, h))
      Error(str), _, _, _, _, _, _, _ -> Error(str)
      _, Error(str), _, _, _, _, _, _ -> Error(str)
      _, _, Error(str), _, _, _, _, _ -> Error(str)
      _, _, _, Error(str), _, _, _, _ -> Error(str)
      _, _, _, _, Error(str), _, _, _ -> Error(str)
      _, _, _, _, _, Error(str), _, _ -> Error(str)
      _, _, _, _, _, _, Error(str), _ -> Error(str)
      _, _, _, _, _, _, _, Error(str) -> Error(str)
    }
  }

  Decoder(mapped_fun)
}

// DECODING
/// Perform the actual decoding! Attempt turn some `Dynamic` data into the type
/// of Gleam data specified by your decoder.
pub fn decode_dynamic(
  dynamic: Dynamic,
  with decoder: Decoder(a),
) -> Result(a, String) {
  let Decoder(decode_fun) = decoder

  decode_fun(dynamic)
}
