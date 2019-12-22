import gleam_decode.{
  Decoder,
  atom,
  atom_field,
  bool,
  decode_dynamic,
  element,
  fail,
  field,
  float,
  from_result,
  int,
  map,
  map2,
  one_of,
  string,
  succeed,
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
    map2(
      Pair,
      element(0, int()),
      element(1, string())
    )

  struct(1, "string")
  |> dynamic.from
  |> decode_dynamic(_, pair_decoder)
  |> expect.equal(_, Ok(Pair(1, "string")))
}

enum Pet {
  Cat(name: String, poise: Int)
  Dog(name: String, loyalty: Float)
}

pub fn one_of_test() {
  let cat_decoder =
    map2(
      fn(name, poise) { Cat(name, poise) },
      element(0, string()),
      element(1, int())
    )
  let dog_decoder =
    map2(
      fn(name, loyalty) { Dog(name, loyalty) },
      element(0, string()),
      element(1, float())
    )
  let pet_decoder = one_of([cat_decoder, dog_decoder])

  let fifi_tuple = struct("Fifi", 100)
  let fido_tuple = struct("Fido", 67.3)

  let fifi = Cat(name: "Fifi", poise: 100)
  let fido = Dog(name: "Fido", loyalty: 67.3)

  fifi_tuple
  |> dynamic.from
  |> decode_dynamic(_, pet_decoder)
  |> expect.equal(_, Ok(fifi))

  fido_tuple
  |> dynamic.from
  |> decode_dynamic(_, pet_decoder)
  |> expect.equal(_, Ok(fido))
}

pub fn succeed_test() {
  struct(1, "string")
  |> dynamic.from
  |> decode_dynamic(_, succeed(2.3))
  |> expect.equal(_, Ok(2.3))
}

pub fn fail_test() {
  struct(1, "string")
  |> dynamic.from
  |> decode_dynamic(_, fail("This will always fail"))
  |> expect.equal(_, Error("This will always fail"))
}

// TODO: Use the stdlib version of this if/when it becomes available.
fn compose(first_fun: fn(a) -> b, second_fun: fn(b) -> c) -> fn(a) -> c {
  fn(a) {
    first_fun(a)
    |> second_fun
  }
}

pub fn then_and_from_result_test() {
  // TODO: Better example (into enum)
  let validate_string =
    fn(string) {
      case string {
        "" -> Error("String must not be empty!")
        str -> Ok(str)
      }
    }
  let valid_string_decoder =
    string()
    |> then(_, compose(validate_string, from_result))

  ""
  |> dynamic.from
  |> decode_dynamic(_, valid_string_decoder)
  |> expect.equal(_, Error("String must not be empty!"))

  "string"
  |> dynamic.from
  |> decode_dynamic(_, valid_string_decoder)
  |> expect.equal(_, Ok("string"))
}
