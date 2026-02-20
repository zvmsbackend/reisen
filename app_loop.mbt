///|
/// Browser frame-loop helpers for driving `GameRunner`.

///|
extern "js" fn run_browser_loop_impl(on_tick : (Int) -> Bool) -> Unit =
  #| (on_tick) => {
  #|   let last = 0;
  #|   const loop = (ts) => {
  #|     const dt = last === 0 ? 0 : Math.max(0, Math.floor(ts - last));
  #|     last = ts;
  #|     const keep = on_tick(dt);
  #|     if (keep) {
  #|       requestAnimationFrame(loop);
  #|     }
  #|   };
  #|   requestAnimationFrame(loop);
  #| }

///|
pub fn[T] run_browser_loop(runner : GameRunner[T]) -> Unit {
  run_browser_loop_impl(dt => runner.tick(elapsed_ms=dt))
}

///|
pub fn[T : FromJson] run_browser_app_loop(app : AppController[T]) -> Unit {
  run_browser_loop_impl(dt => app.tick(elapsed_ms=dt))
}
