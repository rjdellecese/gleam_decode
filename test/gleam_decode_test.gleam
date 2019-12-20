import gleam_decode.{decode_dynamic}
import gleam/dynamic
import gleam/expect
import gleam/int

struct Pair {
  int: Int
  string: String
}

pub fn decode_dynamic_test() {
  // decode an int
  1
  |> dynamic.from
  |> decode_dynamic(_, gleam_decode.int())
  |> expect.equal(_, Ok(1))

  // decode an int to a string with map
  let int_to_string_decoder =
    gleam_decode.int() |> gleam_decode.map(_, int.to_string)

  1
  |> dynamic.from
  |> decode_dynamic(_, int_to_string_decoder)
  |> expect.equal(_, Ok("1"))

  // decode a tuple to a Pair struct with map2
  let tuple_to_pair_decoder =
    gleam_decode.map2(
      gleam_decode.element(gleam_decode.int(), 0),
      gleam_decode.element(gleam_decode.string(), 1),
      Pair
    )

  struct(1, "string")
  |> dynamic.from
  |> decode_dynamic(_, tuple_to_pair_decoder)
  |> expect.equal(_, Ok(Pair(1, "string")))
}
