///|
/// Asset loading helpers for the browser target.
///
/// This module provides async loaders for images, text, and bytes,
/// plus a simple in-memory asset store.

///|
#external
type Image

///|
pub impl @js.Cast for Image with into(value) {
  Some(value.cast())
}

///|
pub impl @js.Cast for Image with from(value) {
  @js.Value::cast_from(value)
}

///|
extern "js" fn load_image_promise(url : String) -> @js.Promise =
  #| (url) => new Promise((resolve, reject) => {
  #|   const img = new Image();
  #|   img.onload = () => resolve(img);
  #|   img.onerror = (e) => reject(e);
  #|   img.src = url;
  #| })

///|
extern "js" fn fetch_text_promise(url : String) -> @js.Promise =
  #| (url) => fetch(url).then(r => {
  #|   if (!r.ok) { throw new Error(`HTTP ${r.status}`); }
  #|   return r.text();
  #| })

///|
extern "js" fn fetch_arraybuffer_promise(url : String) -> @js.Promise =
  #| (url) => fetch(url).then(r => {
  #|   if (!r.ok) { throw new Error(`HTTP ${r.status}`); }
  #|   return r.arrayBuffer();
  #| })

///|
extern "js" fn arraybuffer_to_u8array(buf : @js.Value) -> @js.Value =
  #| (buf) => new Uint8Array(buf)

///|
extern "js" fn u8array_to_int_array(u8 : @js.Value) -> Array[Int] =
  #| (u8) => Array.from(u8)

///|
fn int_array_to_bytes(xs : Array[Int]) -> Bytes {
  Bytes::from_array(xs.map(x => x.to_byte()))
}

///|
pub async fn load_image(url : String) -> Image {
  let v = @js.Promise::wait(load_image_promise(url))
  v.cast()
}

///|
pub async fn load_text(url : String) -> String {
  let v = @js.Promise::wait(fetch_text_promise(url))
  v.cast()
}

///|
pub async fn load_bytes(url : String) -> Bytes {
  let v = @js.Promise::wait(fetch_arraybuffer_promise(url))
  let u8 = arraybuffer_to_u8array(v)
  let arr = u8array_to_int_array(u8)
  int_array_to_bytes(arr)
}

///|
struct AssetStore {
  images : Map[String, Image]
  texts : Map[String, String]
  bytes : Map[String, Bytes]
}

///|
pub fn AssetStore::new() -> AssetStore {
  { images: Map::new(), texts: Map::new(), bytes: Map::new() }
}

///|
pub fn AssetStore::put_image(
  self : AssetStore,
  id : String,
  img : Image,
) -> Unit {
  self.images.set(id, img)
}

///|
pub fn AssetStore::get_image(self : AssetStore, id : String) -> Image? {
  self.images.get(id)
}

///|
pub fn AssetStore::put_text(
  self : AssetStore,
  id : String,
  text : String,
) -> Unit {
  self.texts.set(id, text)
}

///|
pub fn AssetStore::get_text(self : AssetStore, id : String) -> String? {
  self.texts.get(id)
}

///|
pub fn AssetStore::put_bytes(
  self : AssetStore,
  id : String,
  data : Bytes,
) -> Unit {
  self.bytes.set(id, data)
}

///|
pub fn AssetStore::get_bytes(self : AssetStore, id : String) -> Bytes? {
  self.bytes.get(id)
}

///|
pub async fn AssetStore::register_figure(
  self : AssetStore,
  url : String,
  id? : String = gensym(prefix="figure"),
) -> Figure {
  if self.images.get(id) is None {
    let img = load_image(url)
    self.put_image(id, img)
  }
  { id, }
}

///|
pub async fn AssetStore::register_background(
  self : AssetStore,
  url : String,
  id? : String = gensym(prefix="background"),
) -> Background {
  if self.images.get(id) is None {
    let img = load_image(url)
    self.put_image(id, img)
  }
  { id, url }
}
