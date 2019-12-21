import gleam_decode.{
  atom,
  atom_field,
  bool,
  decode_dynamic,
  element,
  field,
  float,
  int,
  map,
  map2,
  required,
  string,
  succeed
}
import gleam/atom as atom_mod
import gleam/dynamic.{Dynamic}
import gleam/expect
import gleam/int as int_mod
import gleam/map as map_mod

pub fn bool_test() {
  True
  |> dynamic.from
  |> decode_dynamic(_, bool())
  |> expect.equal(_, Ok(True))
}
pub fn atom_test() {
  let my_atom = atom_mod.create_from_string("my_atom")

  my_atom
  |> dynamic.from
  |> decode_dynamic(_, atom())
  |> expect.equal(_, Ok(my_atom))
}

pub fn int_test() {
  1
  |> dynamic.from
  |> decode_dynamic(_, int())
  |> expect.equal(_, Ok(1))
}

pub fn float_test() {
  1.23
  |> dynamic.from
  |> decode_dynamic(_, float())
  |> expect.equal(_, Ok(1.23))
}

pub fn string_test() {
  "string"
  |> dynamic.from
  |> decode_dynamic(_, string())
  |> expect.equal(_, Ok("string"))
}

pub fn element_test() {
  struct(1, 2.3, "string")
  |> dynamic.from
  |> decode_dynamic(_, element(float(), 1))
  |> expect.equal(_, Ok(2.3))
}

pub fn field_test() {
  let string_field_atom = atom_mod.create_from_string("string_field")
  let string_field_decoder =
    field(
      string(),
      string_field_atom
    )

  map_mod.new()
  |> map_mod.insert(_, string_field_atom, "string")
  |> dynamic.from
  |> decode_dynamic(_, string_field_decoder)
  |> expect.equal(_, Ok("string"))
}

pub fn atom_field_test() {
  let string_field_atom = atom_mod.create_from_string("string_field")

  map_mod.new()
  |> map_mod.insert(_, string_field_atom, "string")
  |> dynamic.from
  |> decode_dynamic(_, atom_field(string(), "string_field"))
  |> expect.equal(_, Ok("string"))
}

pub fn map_test() {
  let int_to_string_decoder =
    int() |> map(_, int_mod.to_string)

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
    |> map2(
      element(int(), 0),
      element(string(), 1),
      _
    )

  struct(1, "string")
  |> dynamic.from
  |> decode_dynamic(_, pair_decoder)
  |> expect.equal(_, Ok(Pair(1, "string")))
}

pub fn required_test() {
  let pair_decoder =
    succeed(Pair)
    |> required(_, string(), "string")
    |> required(_, int(), "int")

  let string_atom = atom_mod.create_from_string("string")
  let int_atom = atom_mod.create_from_string("int")
  let pair_map =
    map_mod.new
    |> map_mod.insert(_, string_atom, "string")
    |> map_mod.insert(_, int_atom, 1)

  pair_map
  |> decode_dynamic(_, pair_decoder)
  |> expect.equal(_, Ok(Pair(1, "string")))
}
