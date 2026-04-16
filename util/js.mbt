///|
#cfg(target="js")
pub extern "js" fn promise_error_message(
  err : Error,
  fallback : String,
) -> String =
  #| (err, fallback) => {
  #|   if (typeof err === 'string' && err.length > 0) return err;
  #|   if (err && typeof err.message === 'string' && err.message.length > 0) return err.message;
  #|   try {
  #|     const txt = String(err ?? '').trim();
  #|     return txt.length > 0 ? txt : fallback;
  #|   } catch (_) {
  #|     return fallback;
  #|   }
  #| }

///|
#cfg(target="js")
pub extern "js" fn load_result_ok(result : @js.Value) -> Bool =
  #| (result) => !!(result && result.ok === true)

///|
#cfg(target="js")
pub extern "js" fn load_result_value(result : @js.Value) -> @js.Value =
  #| (result) => result?.value

///|
#cfg(target="js")
pub extern "js" fn load_result_error(
  result : @js.Value,
  fallback : String,
) -> String =
  #| (result, fallback) => {
  #|   const message = result && typeof result.error === 'string' ? result.error : '';
  #|   return message || fallback;
  #| }
