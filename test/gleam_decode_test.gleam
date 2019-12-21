import gleam_decode.{decode_dynamic}
import gleam/atom
import gleam/dynamic.{Dynamic}
import gleam/expect
import gleam/int
import gleam/map

pub fn bool_test() {
  True
  |> dynamic.from
  |> decode_dynamic(_, gleam_decode.bool())
  |> expect.equal(_, Ok(True))
}
pub fn atom_test() {
  let my_atom = atom.create_from_string("my_atom")

  my_atom
  |> dynamic.from
  |> decode_dynamic(_, gleam_decode.atom())
  |> expect.equal(_, Ok(my_atom))
}

pub fn int_test() {
  1
  |> dynamic.from
  |> decode_dynamic(_, gleam_decode.int())
  |> expect.equal(_, Ok(1))
}

pub fn float_test() {
  1.23
  |> dynamic.from
  |> decode_dynamic(_, gleam_decode.float())
  |> expect.equal(_, Ok(1.23))
}

pub fn string_test() {
  "string"
  |> dynamic.from
  |> decode_dynamic(_, gleam_decode.string())
  |> expect.equal(_, Ok("string"))
}

pub fn element_test() {
  struct(1, 2.3, "string")
  |> dynamic.from
  |> decode_dynamic(_, gleam_decode.element(gleam_decode.float(), 1))
  |> expect.equal(_, Ok(2.3))
}

pub fn field_test() {
  let string_field_atom = atom.create_from_string("string_field")
  let string_field_decoder =
    gleam_decode.field(
      gleam_decode.string(),
      string_field_atom
    )

  map.new()
  |> map.insert(_, string_field_atom, "string")
  |> dynamic.from
  |> decode_dynamic(_, string_field_decoder)
  |> expect.equal(_, Ok("string"))
}

pub fn map_test() {
  let int_to_string_decoder =
    gleam_decode.int() |> gleam_decode.map(_, int.to_string)

  1
  |> dynamic.from
  |> decode_dynamic(_, int_to_string_decoder)
  |> expect.equal(_, Ok("1"))
}

struct Pair {
  int: Int
  string: String
}

pub fn map2_test() {
  let pair_decoder =
    Pair
    |> gleam_decode.map2(
      gleam_decode.element(gleam_decode.int(), 0),
      gleam_decode.element(gleam_decode.string(), 1),
      _
    )

  struct(1, "string")
  |> dynamic.from
  |> decode_dynamic(_, pair_decoder)
  |> expect.equal(_, Ok(Pair(1, "string")))
}
