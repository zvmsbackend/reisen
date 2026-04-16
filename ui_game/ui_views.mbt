///|
pub(all) struct UiChoiceView {
  id : String
  text : DialogText
} derive(Debug, Eq)

///|
pub(all) struct UiTextInputView {
  var_name : String
  prompt : DialogText
} derive(Debug, Eq)

///|
pub(all) struct UiVideoView {
  url : String
  can_skip : Bool
} derive(Debug, Eq)

///|
pub(all) struct UiDomFigureView {
  id : String
  dom_id : String
  interactive : Bool
  left_pct : Double
  top_pct : Double
  anchor_x : Double
  anchor_y : Double
  layer : Int
  opacity : Double
  scale : Double
  rotation : Double
  blur : Double
  brightness : Double
  contrast : Double
  saturation : Double
  gamma : Double
  color_r : Double
  color_g : Double
  color_b : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct UiViewModel {
  speaker : DialogText
  text : DialogText
  dialog_seq : Int
  typewriter : Bool
  intro_text : DialogText?
  video : UiVideoView?
  append : Bool
  text_box_visible : Bool
  avatar_id : String?
  choices : Array[UiChoiceView]
  text_input : UiTextInputView?
  dialog_history : Array[DialogLogEntry]
  dom_figures : Array[UiDomFigureView]
  auto_mode : Bool
  skip_mode : Bool
  log_visible : Bool
  dirty_speaker : Bool
  dirty_text : Bool
  dirty_choices : Bool
  dirty_text_input : Bool
  dirty_action_buttons : Bool
} derive(Debug, Eq)
