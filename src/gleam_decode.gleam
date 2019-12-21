import gleam/atom.{Atom}
import gleam/dynamic.{Dynamic}
import gleam/result

// Decoder

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

pub fn map2(decoder1: Decoder(a), decoder2: Decoder(b), fun: fn(a, b) -> value) -> Decoder(value) {
  let Decoder(decode_fun1) = decoder1
  let Decoder(decode_fun2) = decoder2

  let mapped_fun =
    fn(dynamic) {
      case decode_fun1(dynamic), decode_fun2(dynamic) {
        Ok(a), Ok(b) -> Ok(fun(a, b))
        Error(str), _ -> Error(str)
        _, Error(str) -> Error(str)
      }
    }

  Decoder(mapped_fun)
}


// Pipelining

pub fn custom(next_decoder: Decoder(a), current_decoder: Decoder(fn(a) -> b)) -> Decoder(b) {
  let pipe_fun =
    fn(a: a, f: fn(a) -> b) {
      f(a)
    }

  map2(next_decoder, current_decoder, pipe_fun)
}

// Decoding

pub fn decode_dynamic(dynamic: Dynamic, decoder: Decoder(a)) -> Result(a, String) {
  let Decoder(decode_fun) = decoder

  decode_fun(dynamic)
}
