///|
#cfg(target="js")
pub extern "js" fn console_warn(msg : String) -> Unit =
  #|(msg) => console.warn(msg)

///|
#cfg(target="native")
pub fn console_warn(msg : String) -> Unit {
  println(msg)
}
