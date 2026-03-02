///|
extern "js" fn pixi_now_ms() -> Int =
  #| () => Math.floor((globalThis.performance?.now?.() ?? Date.now()))

///|
extern "js" fn set_canvas_element_size(
  canvas : PixiCanvas,
  width : Int,
  height : Int,
) -> Unit =
  #| (canvas, width, height) => {
  #|   if (!canvas) return;
  #|   canvas.width = width;
  #|   canvas.height = height;
  #|   canvas.style.width = width + 'px';
  #|   canvas.style.height = height + 'px';
  #| }

///|
fn figure_rect(
  pos : Position,
  viewport_w : Double,
  viewport_h : Double,
) -> (Double, Double, Double, Double) {
  let w = viewport_w * 0.40
  let h = viewport_h * 0.90
  match pos {
    Left => (viewport_w * 0.05, 0.0, w, h)
    Center => ((viewport_w - w) / 2.0, 0.0, w, h)
    Right => (viewport_w * 0.55, 0.0, w, h)
    Custom(x, y) => (x * viewport_w, y * viewport_h, w, h)
  }
}

///|
fn custom_to_canvas_pos(
  custom_x : Double,
  custom_y : Double,
  viewport_w : Double,
  viewport_h : Double,
  rect_w : Double,
  rect_h : Double,
) -> (Double, Double) {
  let free_w = if viewport_w - rect_w > 0.0 { viewport_w - rect_w } else { 0.0 }
  let free_h = if viewport_h - rect_h > 0.0 { viewport_h - rect_h } else { 0.0 }
  ((custom_x + 1.0) * 0.5 * free_w, (custom_y + 1.0) * 0.5 * free_h)
}

///|
fn canvas_to_custom_pos(
  x : Double,
  y : Double,
  viewport_w : Double,
  viewport_h : Double,
  rect_w : Double,
  rect_h : Double,
) -> (Double, Double) {
  let free_w = viewport_w - rect_w
  let free_h = viewport_h - rect_h
  let custom_x = if free_w <= 0.0 { 0.0 } else { x / free_w * 2.0 - 1.0 }
  let custom_y = if free_h <= 0.0 { 0.0 } else { y / free_h * 2.0 - 1.0 }
  (custom_x, custom_y)
}

///|
fn fit_background(
  image_id : String,
  canvas_w : Double,
  canvas_h : Double,
  sizes : Map[String, (Double, Double)],
) -> (Double, Double, Double, Double) {
  match sizes.get(image_id) {
    Some((img_w, img_h)) => {
      let canvas_ratio = canvas_w / canvas_h
      let img_ratio = img_w / img_h
      let (scale_w, scale_h) = if img_ratio > canvas_ratio {
        let scale = canvas_w / img_w
        (canvas_w, img_h * scale)
      } else {
        let scale = canvas_h / img_h
        (img_w * scale, canvas_h)
      }
      let x = (canvas_w - scale_w) / 2.0
      let y = (canvas_h - scale_h) / 2.0
      (x, y, scale_w, scale_h)
    }
    None => (0.0, 0.0, canvas_w, canvas_h)
  }
}

///|
fn fit_background_cover(
  image_id : String,
  canvas_w : Double,
  canvas_h : Double,
  sizes : Map[String, (Double, Double)],
) -> (Double, Double, Double, Double) {
  match sizes.get(image_id) {
    Some((img_w, img_h)) => {
      let canvas_ratio = canvas_w / canvas_h
      let img_ratio = img_w / img_h
      let (scale_w, scale_h) = if img_ratio > canvas_ratio {
        let scale = canvas_h / img_h
        (img_w * scale, canvas_h)
      } else {
        let scale = canvas_w / img_w
        (canvas_w, img_h * scale)
      }
      let x = (canvas_w - scale_w) / 2.0
      let y = (canvas_h - scale_h) / 2.0
      (x, y, scale_w, scale_h)
    }
    None => (0.0, 0.0, canvas_w, canvas_h)
  }
}

///|
fn fit_figure(
  image_id : String,
  max_w : Double,
  max_h : Double,
  sizes : Map[String, (Double, Double)],
) -> (Double, Double) {
  match sizes.get(image_id) {
    Some((img_w, img_h)) => {
      let img_ratio = img_w / img_h
      let max_ratio = max_w / max_h
      if img_ratio > max_ratio {
        let scale = max_w / img_w
        (max_w, img_h * scale)
      } else {
        let scale = max_h / img_h
        (img_w * scale, max_h)
      }
    }
    None => (max_w, max_h)
  }
}

///|
fn fit_size_to_box(
  base_w : Double,
  base_h : Double,
  max_w : Double,
  max_h : Double,
) -> (Double, Double) {
  if base_w <= 0.0 || base_h <= 0.0 {
    return (max_w, max_h)
  }
  let ratio = base_w / base_h
  let max_ratio = max_w / max_h
  if ratio > max_ratio {
    let w = max_w
    let h = w / ratio
    (w, h)
  } else {
    let h = max_h
    let w = h * ratio
    (w, h)
  }
}

///|
fn scale_rect_with_anchor(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  scale : Double,
  anchor_x : Double,
  anchor_y : Double,
) -> (Double, Double, Double, Double) {
  let sw = w * scale
  let sh = h * scale
  let ax = x + w * anchor_x
  let ay = y + h * anchor_y
  let sx = ax - sw * anchor_x
  let sy = ay - sh * anchor_y
  (sx, sy, sw, sh)
}

///|
fn clamp01(v : Double) -> Double {
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }
}
