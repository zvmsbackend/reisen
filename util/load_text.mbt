///|
#cfg(target="js")
extern "js" fn load_text_result_promise(
  url : String,
) -> @js_async.Promise[@js.Value] =
  #| (url) => fetch(url).then(r => {
  #|   if (!r.ok) {
  #|     throw new Error(`HTTP ${r.status}`);
  #|   }
  #|   return r.text();
  #| })
  #|   .then(value => ({ ok: true, value }))
  #|   .catch(error => ({ ok: false, error: String(error?.message ?? error ?? '') }))

///|
pub suberror LoadTextError {
  TextLoadFailed(message~ : String)
}

///|
pub fn LoadTextError::message(self : LoadTextError) -> String {
  let TextLoadFailed(message~) = self
  message
}

///|
#cfg(target="js")
pub async fn load_text(url : String) -> String raise LoadTextError {
  let result = (url |> load_text_result_promise |> @js_async.Promise::wait) catch {
    err =>
      raise TextLoadFailed(
        message=promise_error_message(err, "Failed to load text: \{url}"),
      )
  }
  if !load_result_ok(result) {
    raise TextLoadFailed(
      message=load_result_error(result, "Failed to load text: \{url}"),
    )
  }
  load_result_value(result).cast()
}

///|
#cfg(target="native")
pub async fn load_text(path : String) -> String raise LoadTextError {
  @fs.read_file(path).text() catch {
    error => raise TextLoadFailed(message=error.to_string())
  }
}
