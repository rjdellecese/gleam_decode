import gleam/dynamic.{Dynamic}
import gleam/result

pub enum Decoder(a) {
  Decoder(
    fn(Dynamic) -> Result(a, String)
  )
}

pub fn int() -> Decoder(Int) {
  Decoder(dynamic.int)
}

pub fn string() -> Decoder(String) {
  Decoder(dynamic.string)
}

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

pub fn decode_dynamic(dynamic: Dynamic, decoder: Decoder(a)) -> Result(a, String) {
  let Decoder(decode_fun) = decoder

  decode_fun(dynamic)
}
