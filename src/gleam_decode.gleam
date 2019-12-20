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

pub fn map(decoder: Decoder(a), fun: fn(a) -> b) -> Decoder(b) {
  let Decoder(decode_fun) = decoder

  let mapped_fun =
    fn(dynamic) {
      decode_fun(dynamic)
      |> result.map(_, fun)
    }

  Decoder(mapped_fun)
}

pub fn decode_dynamic(dynamic: Dynamic, decoder: Decoder(a)) -> Result(a, String) {
  let Decoder(decode_fun) = decoder

  decode_fun(dynamic)
}
