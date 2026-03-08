///|
pub extern "js" fn load_result_ok(result : @js.Value) -> Bool =
  #| (result) => !!(result && result.ok === true)

///|
pub extern "js" fn load_result_value(result : @js.Value) -> @js.Value =
  #| (result) => result?.value

///|
pub extern "js" fn load_result_error(
  result : @js.Value,
  fallback : String,
) -> String =
  #| (result, fallback) => {
  #|   const message = result && typeof result.error === 'string' ? result.error : '';
  #|   return message || fallback;
  #| }
