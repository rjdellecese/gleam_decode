import gleam/atom.{Atom} as atom_mod
import gleam/dynamic.{Dynamic}
import gleam/result
import gleam/string as string_mod


// Types

// TODO: Have a proper Error type? `gleam_stdlib/dynamic` may need the same.

pub enum Decoder(a) {
  Decoder(
    fn(Dynamic) -> Result(a, String)
  )
}


// Primitives

pub fn bool() -> Decoder(Bool) {
  Decoder(dynamic.bool)
}

pub fn atom() -> Decoder(Atom) {
  Decoder(dynamic.atom)
}

pub fn int() -> Decoder(Int) {
  Decoder(dynamic.int)
}

pub fn float() -> Decoder(Float) {
  Decoder(dynamic.float)
}

pub fn string() -> Decoder(String) {
  Decoder(dynamic.string)
}


// Data structures

pub fn element(decoder: Decoder(value), position: Int) -> Decoder(value) {
  let Decoder(decode_fun) = decoder

  let fun =
    fn(dynamic_) {
      dynamic_
      |> dynamic.element(_, position)
      |> result.then(_, decode_fun)
    }

  Decoder(fun)
}

pub fn field(decoder: Decoder(value), named: a) -> Decoder(value) {
  let Decoder(decode_fun) = decoder

  let fun =
    fn(dynamic_) {
      dynamic_
      |> dynamic.field(_, named)
      |> result.then(_, decode_fun)
    }

  Decoder(fun)
}

// Takes a field name as a string and tries to turn it into an atom in order to
// access it. If the atom doesn't exist, the field doesn't either! And in that
// case the decoder will fail.
//
// TODO: Examples
//
// Saves you the trouble of having to handle atom creation/error handling
// yourself.
pub fn atom_field(decoder: Decoder(value), named: String) -> Decoder(value) {
  let Decoder(decode_fun) = decoder
  let named_result =
    atom_mod.from_string(named)
    |> result.map_error(
      _,
      fn(_a) {
        string_mod.append("No atom field by name of `", named)
        |> string_mod.append(_, "` found")
      }
    )

  let fun =
    fn(dynamic_) {
      named_result
      |> result.then(_, dynamic.field(dynamic_, _))
      |> result.then(_, decode_fun)
    }

  Decoder(fun)
}


// Mapping

pub fn map(decoder: Decoder(a), fun: fn(a) -> value) -> Decoder(value) {
  let Decoder(decode_fun) = decoder

  let mapped_fun =
    fn(dynamic) {
      dynamic
      |> decode_fun
      |> result.map(_, fun)
    }

  Decoder(mapped_fun)
}

pub fn map2(
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  fun: fn(a, b) -> value
) -> Decoder(value)
{
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2

  let mapped_fun =
    fn(dynamic) {
      case
        decode_fun1(dynamic),
        decode_fun2(dynamic)
      {
        Ok(a), Ok(b) -> Ok(fun(a, b))
        Error(str), _ -> Error(str)
        _, Error(str) -> Error(str)
      }
    }

  Decoder(mapped_fun)
}

pub fn map3(
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  fun: fn(a, b, c) -> value
) -> Decoder(value)
{
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3

  let mapped_fun =
    fn(dynamic) {
      case
        decode_fun1(dynamic),
        decode_fun2(dynamic),
        decode_fun3(dynamic)
      {
        Ok(a), Ok(b), Ok(c) -> Ok(fun(a, b, c))
        Error(str), _, _ -> Error(str)
        _, Error(str), _ -> Error(str)
        _, _, Error(str) -> Error(str)
      }
    }

  Decoder(mapped_fun)
}

pub fn map4(
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  decoder4: Decoder(d),
  fun: fn(a, b, c, d) -> value
) -> Decoder(value)
{
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3
  let Decoder(decode_fun4) = decoder4

  let mapped_fun =
    fn(dynamic) {
      case
        decode_fun1(dynamic),
        decode_fun2(dynamic),
        decode_fun3(dynamic),
        decode_fun4(dynamic)
      {
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
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  decoder4: Decoder(d),
  decoder5: Decoder(e),
  fun: fn(a, b, c, d, e) -> value
) -> Decoder(value)
{
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3
  let Decoder(decode_fun4) = decoder4
  let Decoder(decode_fun5) = decoder5

  let mapped_fun =
    fn(dynamic) {
      case
        decode_fun1(dynamic),
        decode_fun2(dynamic),
        decode_fun3(dynamic),
        decode_fun4(dynamic),
        decode_fun5(dynamic)
      {
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
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  decoder4: Decoder(d),
  decoder5: Decoder(e),
  decoder6: Decoder(f),
  fun: fn(a, b, c, d, e, f) -> value
) -> Decoder(value)
{
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3
  let Decoder(decode_fun4) = decoder4
  let Decoder(decode_fun5) = decoder5
  let Decoder(decode_fun6) = decoder6

  let mapped_fun =
    fn(dynamic) {
      case
        decode_fun1(dynamic),
        decode_fun2(dynamic),
        decode_fun3(dynamic),
        decode_fun4(dynamic),
        decode_fun5(dynamic),
        decode_fun6(dynamic)
      {
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
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  decoder4: Decoder(d),
  decoder5: Decoder(e),
  decoder6: Decoder(f),
  decoder7: Decoder(g),
  fun: fn(a, b, c, d, e, f, g) -> value
) -> Decoder(value)
{
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3
  let Decoder(decode_fun4) = decoder4
  let Decoder(decode_fun5) = decoder5
  let Decoder(decode_fun6) = decoder6
  let Decoder(decode_fun7) = decoder7

  let mapped_fun =
    fn(dynamic) {
      case
        decode_fun1(dynamic),
        decode_fun2(dynamic),
        decode_fun3(dynamic),
        decode_fun4(dynamic),
        decode_fun5(dynamic),
        decode_fun6(dynamic),
        decode_fun7(dynamic)
      {
        Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f), Ok(g) -> Ok(fun(a, b, c, d, e, f, g))
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
  decoder1: Decoder(a),
  decoder2: Decoder(b),
  decoder3: Decoder(c),
  decoder4: Decoder(d),
  decoder5: Decoder(e),
  decoder6: Decoder(f),
  decoder7: Decoder(g),
  decoder8: Decoder(h),
  fun: fn(a, b, c, d, e, f, g, h) -> value
) -> Decoder(value)
{
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2
  let Decoder(decode_fun3) = decoder3
  let Decoder(decode_fun4) = decoder4
  let Decoder(decode_fun5) = decoder5
  let Decoder(decode_fun6) = decoder6
  let Decoder(decode_fun7) = decoder7
  let Decoder(decode_fun8) = decoder8

  let mapped_fun =
    fn(dynamic) {
      case
        decode_fun1(dynamic),
        decode_fun2(dynamic),
        decode_fun3(dynamic),
        decode_fun4(dynamic),
        decode_fun5(dynamic),
        decode_fun6(dynamic),
        decode_fun7(dynamic),
        decode_fun8(dynamic)
      {
        Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f), Ok(g), Ok(h) -> Ok(fun(a, b, c, d, e, f, g, h))
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


// Decoding

pub fn decode_dynamic(dynamic: Dynamic, decoder: Decoder(a)) -> Result(a, String) {
  let Decoder(decode_fun) = decoder

  decode_fun(dynamic)
}
