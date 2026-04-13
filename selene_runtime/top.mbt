///|
pub struct NativeLoopConfig {
  viewport_width : Double
  viewport_height : Double
  zoom : Double
  fps : UInt
  image_smooth : Bool
}

///|
pub fn NativeLoopConfig::default() -> NativeLoopConfig {
  {
    viewport_width: 1280.0,
    viewport_height: 720.0,
    zoom: 1.0,
    fps: 60U,
    image_smooth: true,
  }
}

///|
fn clamp_non_negative_ms(raw_delta_seconds : Double) -> Int {
  if raw_delta_seconds <= 0.0 {
    0
  } else {
    @math.floor(raw_delta_seconds * 1000.0).to_int()
  }
}

///|
pub fn run_native_loop_with_selene(
  on_tick : (Int) -> Bool,
  on_render? : (Double) -> Unit = _ => (),
  on_startup? : () -> Unit = () => (),
  config? : NativeLoopConfig = NativeLoopConfig::default(),
) -> Unit {
  let run_game = @selene_window.initialize(
    {
      viewport_width: config.viewport_width,
      viewport_height: config.viewport_height,
      screen_width: config.viewport_width * config.zoom,
      screen_height: config.viewport_height * config.zoom,
      fps: config.fps,
      image_smooth: config.image_smooth,
    },
    {
      startup: on_startup,
      render_loop: on_render,
      game_loop: raw_delta => {
        let dt_ms = clamp_non_negative_ms(raw_delta)
        if !on_tick(dt_ms) {
          @selene_window.request_close()
        }
      },
    },
  )
  run_game()
}

///|
test "clamp_non_negative_ms handles edge values" {
  inspect(clamp_non_negative_ms(-0.5), content="0")
  inspect(clamp_non_negative_ms(0.0), content="0")
  inspect(clamp_non_negative_ms(0.016), content="16")
  inspect(clamp_non_negative_ms(0.999), content="999")
}
