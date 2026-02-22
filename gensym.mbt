///|
let names_taken : Set[String] = Set::new()

///|
let counter : Ref[Int] = Ref::new(0)

///|
pub fn gensym(prefix? : String = "gensym") -> String {
  for {
    let name = "\{prefix}_\{counter.val}"
    if !names_taken.contains(name) {
      names_taken.add(name)
      return name
    }
    counter.val += 1
  }
}
