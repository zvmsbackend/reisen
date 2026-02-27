///|
let counter : Ref[Int] = Ref::new(0)

///|
pub fn gensym(prefix? : String = "gensym") -> String {
  let name = "\{prefix}_\{counter.val}"
  counter.val += 1
  name
}
