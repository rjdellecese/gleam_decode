import gleam_decode.{decode_dynamic}
import gleam/dynamic
import gleam/expect
import gleam/int

pub fn decode_dynamic_test() {
  // decode an int
  1
  |> dynamic.from
  |> decode_dynamic(_, gleam_decode.int())
  |> expect.equal(_, Ok(1))

  // decode an int with map
  let int_to_string_decoder = gleam_decode.int() |> gleam_decode.map(_, int.to_string)
  1
  |> dynamic.from
  |> decode_dynamic(_, int_to_string_decoder)
  |> expect.equal(_, Ok("1"))
}
