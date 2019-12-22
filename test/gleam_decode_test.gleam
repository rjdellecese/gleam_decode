import gleam_decode.{
  Decoder,
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
  string,
  then
}
import gleam/atom.{Atom} as atom_mod
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
  |> decode_dynamic(_, element(1, float()))
  |> expect.equal(_, Ok(2.3))
}

pub fn field_test() {
  map_mod.new()
  |> map_mod.insert(_, "key", "value")
  |> dynamic.from
  |> decode_dynamic(_, field("key", string()))
  |> expect.equal(_, Ok("value"))
}

pub fn atom_field_test() {
  let key_atom = atom_mod.create_from_string("key")

  map_mod.new()
  |> map_mod.insert(_, key_atom, "value")
  |> dynamic.from
  |> decode_dynamic(_, atom_field("key", string()))
  |> expect.equal(_, Ok("value"))
}

pub fn map_test() {
  let int_to_string_decoder =
    map(int_mod.to_string, int())

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
      _,
      element(0, int()),
      element(1, string())
    )

  struct(1, "string")
  |> dynamic.from
  |> decode_dynamic(_, pair_decoder)
  |> expect.equal(_, Ok(Pair(1, "string")))
}

pub fn then_test() {
  let ok_atom = atom_mod.create_from_string("ok")
  let error_atom = atom_mod.create_from_string("error")
  let everything_broke_atom = atom_mod.create_from_string("everything_broke")
  // Decoder (Result(String, Atom))
  let success_decoder = Decoder(fn(dyn) { )
  let failure_decoder = Decoder(atom())
  let ok_error_helper =
    fn(atom: Atom) {
      case atom {
        ok_atom -> success_decoder
        error_atom -> failure_decoder
      }
    }
  let might_fail_decoder =
    // Decoder(Atom)
    element(0, atom())
    |> then(ok_error_helper, _)

  struct(ok_atom, "It worked!")
  |> dynamic.from
  |> decode_dynamic(_, might_fail_decoder)
  |> result.then(result.flatten)
  |> expect.equal(_, Ok("It worked!"))
}
