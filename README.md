# Bs-batteries
OCaml batteries binding to bucklescript. In development. Now available: `BatArray`, `BatList`, `Option`, `BatEnum`, `BarPervasives`

# Examples (in ReasonML)
## Option
```
let odd x =>
  switch (x mod 2) {
  | 0 => Some x
  | _ => None
  };

let t10 =
  odd 10 |> Option.map ((+) 10) |> Option.map ((/) 100) |>
  Option.map_default string_of_int "No value";

Js.log2 "t10 value: " t10;

let t11 =
  odd 11 |> Option.map ((+) 10) |> Option.map ((/) 2) |>
  Option.map_default string_of_int "No value";

Js.log2 "t11 value: " t11;
```