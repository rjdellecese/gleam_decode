import decode.{
  atom, atom_field, bool, decode_dynamic, dynamic, element, fail, field, float, from_result,
  int, list, map, map2, ok_error_tuple, one_of, string, succeed, then,
}

import gleam/atom as atom_mod
import gleam/dynamic.{Dynamic} as dynamic_mod
import gleam/should
import gleam/int as int_mod
import gleam/map as map_mod
import gleam/result as result_mod

pub fn bool_test() {
  True
  |> dynamic_mod.from
  |> decode_dynamic(bool())
  |> should.equal(Ok(True))
}

pub fn atom_test() {
  let my_atom = atom_mod.create_from_string("my_atom")

  my_atom
  |> dynamic_mod.from
  |> decode_dynamic(atom())
  |> should.equal(Ok(my_atom))
}

pub fn int_test() {
  1
  |> dynamic_mod.from
  |> decode_dynamic(int())
  |> should.equal(Ok(1))
}

pub fn float_test() {
  1.23
  |> dynamic_mod.from
  |> decode_dynamic(float())
  |> should.equal(Ok(1.23))
}

pub fn string_test() {
  "string"
  |> dynamic_mod.from
  |> decode_dynamic(string())
  |> should.equal(Ok("string"))
}

pub fn element_test() {
  tuple(1, 2.3, "string")
  |> dynamic_mod.from
  |> decode_dynamic(element(1, float()))
  |> should.equal(Ok(2.3))
}

pub fn field_test() {
  map_mod.new()
  |> map_mod.insert("key", "value")
  |> dynamic_mod.from
  |> decode_dynamic(field("key", string()))
  |> should.equal(Ok("value"))
}

pub fn atom_field_test() {
  let key_atom = atom_mod.create_from_string("key")

  map_mod.new()
  |> map_mod.insert(key_atom, "value")
  |> dynamic_mod.from
  |> decode_dynamic(atom_field("key", string()))
  |> should.equal(Ok("value"))
}

pub fn map_test() {
  let int_to_string_decoder = map(int_mod.to_string, int())

  1
  |> dynamic_mod.from
  |> decode_dynamic(int_to_string_decoder)
  |> should.equal(Ok("1"))
}

type Pair {
  Pair(int: Int, string: String)
}

pub fn map2_test() {
  let pair_decoder = map2(Pair, element(0, int()), element(1, string()))

  tuple(1, "string")
  |> dynamic_mod.from
  |> decode_dynamic(pair_decoder)
  |> should.equal(Ok(Pair(1, "string")))
}

type Pet {
  Cat(name: String, poise: Int)
  Dog(name: String, loyalty: Float)
}

pub fn one_of_test() {
  let cat_decoder =
    map2(
      fn(name, poise) { Cat(name, poise) },
      element(0, string()),
      element(1, int()),
    )
  let dog_decoder =
    map2(
      fn(name, loyalty) { Dog(name, loyalty) },
      element(0, string()),
      element(1, float()),
    )
  let pet_decoder = one_of([cat_decoder, dog_decoder])

  let fifi_tuple = tuple("Fifi", 100)
  let fido_tuple = tuple("Fido", 67.3)

  let fifi = Cat(name: "Fifi", poise: 100)
  let fido = Dog(name: "Fido", loyalty: 67.3)

  fifi_tuple
  |> dynamic_mod.from
  |> decode_dynamic(pet_decoder)
  |> should.equal(Ok(fifi))

  fido_tuple
  |> dynamic_mod.from
  |> decode_dynamic(pet_decoder)
  |> should.equal(Ok(fido))
}

pub fn list_test() {
  let list_of_ints_decoder = list(int())

  [1, 2, 3]
  |> dynamic_mod.from
  |> decode_dynamic(list_of_ints_decoder)
  |> should.equal(Ok([1, 2, 3]))
}

pub fn dynamic_test() {
  "some complex data"
  |> dynamic_mod.from
  |> decode_dynamic(dynamic())
  |> result_mod.then(decode_dynamic(_, string()))
  |> should.equal(Ok("some complex data"))
}

pub fn succeed_test() {
  tuple(1, "string")
  |> dynamic_mod.from
  |> decode_dynamic(succeed(2.3))
  |> should.equal(Ok(2.3))
}

pub fn fail_test() {
  tuple(1, "string")
  |> dynamic_mod.from
  |> decode_dynamic(fail("This will always fail"))
  |> should.equal(Error("This will always fail"))
}

// TODO: Use the stdlib version of this if/when it becomes available.
fn compose(first_fun: fn(a) -> b, second_fun: fn(b) -> c) -> fn(a) -> c {
  fn(a) {
    first_fun(a)
    |> second_fun
  }
}

type Direction {
  Left
  Right
}

pub fn then_and_from_result_test() {
  let validate_left_or_right = fn(string) {
    case string {
      "left" -> Ok(Left)
      "right" -> Ok(Right)
      _string -> Error("Neither left nor right!")
    }
  }
  let valid_string_decoder =
    string()
    |> then(compose(validate_left_or_right, from_result))

  "up"
  |> dynamic_mod.from
  |> decode_dynamic(valid_string_decoder)
  |> should.equal(Error("Neither left nor right!"))

  "left"
  |> dynamic_mod.from
  |> decode_dynamic(valid_string_decoder)
  |> should.equal(Ok(Left))
}

type ForeignFunctionResult {
  Success(Int)
  Failure(String)
  Error
}

pub fn ok_error_tuple_test() {
  let ok_decoder = element(1, map(Success, int()))
  let error_decoder = element(1, map(Failure, string()))

  let decode_foreign_function_result = fn(result: Dynamic) {
    decode_dynamic(result, ok_error_tuple(ok_decoder, error_decoder))
    |> result_mod.unwrap(Error)
  }

  let ok_atom = atom_mod.create_from_string("ok")
  let error_atom = atom_mod.create_from_string("error")

  tuple(ok_atom, 1)
  |> dynamic_mod.from
  |> decode_foreign_function_result
  |> should.equal(Success(1))

  tuple(error_atom, "Something went predictably wrong!")
  |> dynamic_mod.from
  |> decode_foreign_function_result
  |> should.equal(Failure("Something went predictably wrong!"))

  // A decoding error becomes an Error record (variant) of the
  // ForeignFunctionResult type
  ["Uh oh.", "Something went unpredictably wrong!"]
  |> dynamic_mod.from
  |> decode_foreign_function_result
  |> should.equal(Error)
}
