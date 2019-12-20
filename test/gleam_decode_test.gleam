import gleam_decode.{decode_dynamic}
import gleam/dynamic
import gleam/expect

pub fn decode_dynamic_test() {
  1
  |> dynamic.from
  |> decode_dynamic(_, gleam_decode.int())
  |> expect.equal(_, Ok(1))
}
