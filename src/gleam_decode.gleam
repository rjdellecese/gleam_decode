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

pub fn decode_dynamic(dynamic: Dynamic, decoder: Decoder(a)) -> Result(a, String) {
  let Decoder(decode_function) = decoder

  decode_function(dynamic)
}
