///|
let save_data_dir = "save_data"

///|
let storage_file = "save_data/storage.json"

///|
let cache : Ref[Map[String, String]] = Ref::new(Map::new())

///|
let cache_loaded : Ref[Bool] = Ref::new(false)

///|
fn ensure_save_dir() -> Unit {
  if !@x_fs.path_exists(save_data_dir) {
    ignore((try? @x_fs.create_dir(save_data_dir)).to_option())
  }
}

///|
fn load_cache_from_disk() -> Unit {
  if cache_loaded.val {
    return
  }
  cache_loaded.val = true
  if !@x_fs.path_exists(storage_file) {
    return
  }
  let json_str = (try? @x_fs.read_file_to_string(storage_file)).to_option()
  match json_str {
    Some(s) => {
      let map : Map[String, String] = (try? (s |> @json.parse |> @json.from_json))
        .to_option()
        .unwrap_or(Map::new())
      cache.val = map
    }
    None => ()
  }
}

///|
fn flush_cache_to_disk() -> Unit {
  ensure_save_dir()
  let json = cache.val.to_json().stringify()
  ignore((try? @x_fs.write_string_to_file(storage_file, json)).to_option())
}

///|
fn storage_set_item(key : String, value : String) -> Unit {
  load_cache_from_disk()
  cache.val.set(key, value)
  flush_cache_to_disk()
}

///|
fn storage_get_item(key : String) -> String? {
  load_cache_from_disk()
  cache.val.get(key)
}

///|
fn storage_remove_item(key : String) -> Unit {
  load_cache_from_disk()
  cache.val.remove(key)
  flush_cache_to_disk()
}

///|
fn storage_list_slots(prefix : String) -> Array[String] {
  load_cache_from_disk()
  cache.val
  .keys()
  .filter(k => k.has_prefix(prefix))
  .map(k => k[prefix.length():].to_string())
  .collect()
}
