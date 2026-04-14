///|
struct AudioPort {
  has_active_sfx_impl : () -> Bool
  set_bgm_gain_impl : (Double) -> Unit
  set_sfx_gain_impl : (Double) -> Unit
}

///|
pub fn AudioPort::new(
  has_active_sfx_impl : () -> Bool,
  set_bgm_gain_impl : (Double) -> Unit,
  set_sfx_gain_impl : (Double) -> Unit,
) -> AudioPort {
  { has_active_sfx_impl, set_bgm_gain_impl, set_sfx_gain_impl }
}

///|
pub fn AudioPort::browser() -> AudioPort {
  AudioPort::new(
    @audio_web.AudioDom::has_active_sfx,
    @audio_web.AudioDom::set_bgm_gain,
    @audio_web.AudioDom::set_sfx_gain,
  )
}

///|
pub fn AudioPort::has_active_sfx(self : AudioPort) -> Bool {
  (self.has_active_sfx_impl)()
}

///|
pub fn AudioPort::set_bgm_gain(self : AudioPort, gain : Double) -> Unit {
  (self.set_bgm_gain_impl)(gain)
}

///|
pub fn AudioPort::set_sfx_gain(self : AudioPort, gain : Double) -> Unit {
  (self.set_sfx_gain_impl)(gain)
}
